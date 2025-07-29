import Capacitor
import CoreLocation
import Foundation
import NetworkExtension
import linphonesw

// Inherit from NSObject to conform to CLLocationManagerDelegate and expose methods to Objective-C
public class SipLinphone: NSObject {
    // MARK: - Properties
    private var currentCall: Call?
    private var linphoneCore: Core?
    private var coreTimer: Timer?
    
    private var locationManager: CLLocationManager?
    private var bssidCall: CAPPluginCall?

    // MARK: - Event Closures
    var onRegistrationStateChanged: (([String: Any]) -> Void)?
    var onIncomingCall: (([String: Any]) -> Void)?
    var onCallStateChanged: (([String: Any]) -> Void)?

    // MARK: - Lifecycle
    override init() {
        super.init()
    }

    deinit {
        coreTimer?.invalidate()
        linphoneCore?.removeDelegate(delegate: self)
        linphoneCore?.stop()
    }

    // MARK: - Core and Registration
    @objc func initialize(_ call: CAPPluginCall) {
        do {
            let factory = Factory.Instance
            
            // Create the core with default configuration paths.
            // We are no longer disabling sound resources here, to allow the default ringtone to load.
            linphoneCore = try factory.createCore(configPath: nil, factoryConfigPath: nil, systemContext: nil)
            
            linphoneCore?.addDelegate(delegate: self)
            try linphoneCore?.start()

            coreTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
                self?.linphoneCore?.iterate()
            }
            call.resolve()
        } catch {
            call.reject("Failed to initialize Linphone Core: \(error.localizedDescription)")
        }
    }

    @objc func register(_ call: CAPPluginCall) {
        guard let username = call.getString("username"),
              let password = call.getString("password"),
              let domain = call.getString("domain"),
              let core = linphoneCore
        else {
            call.reject("Missing SIP credentials or core not initialized")
            return
        }

        do {
            let authInfo = try Factory.Instance.createAuthInfo(username: username, userid: nil, passwd: password, ha1: nil, realm: nil, domain: domain)
            core.addAuthInfo(info: authInfo)

            let accountParams = try core.createAccountParams()
            let identityAddr = try Factory.Instance.createAddress(addr: "sip:\(username)@\(domain)")
            try accountParams.setIdentityaddress(newValue: identityAddr)

            let proxyAddr = try Factory.Instance.createAddress(addr: "sip:\(domain)")
            try accountParams.setServeraddress(newValue: proxyAddr)
            accountParams.registerEnabled = true

            let account = try core.createAccount(params: accountParams)
            try core.addAccount(account: account)
            core.defaultAccount = account
            
            call.resolve(["status": "Registration in progress..."])
        } catch {
            call.reject("Registration error: \(error.localizedDescription)")
        }
    }

    @objc func unregister(_ call: CAPPluginCall) {
        guard let core = linphoneCore else {
            call.reject("Core not initialized")
            return
        }
        core.clearAccounts()
        core.clearAllAuthInfo()
        call.resolve()
    }

    @objc func getRegistrationStatus(_ call: CAPPluginCall) {
        guard let core = linphoneCore, let account = core.defaultAccount else {
            call.reject("Core not initialized or no default account")
            return
        }
        let stateStr = "\(account.state)"
        call.resolve(["state": stateStr.capitalized])
    }

    // MARK: - Call Management
    @objc func makeCall(_ call: CAPPluginCall) {
        guard let address = call.getString("address"), let core = linphoneCore else {
            call.reject("Missing address or core not initialized")
            return
        }

        self.currentCall = core.invite(url: address)
        call.resolve()
    }

    @objc func terminateCall(_ call: CAPPluginCall) {
        guard let currentCall = self.currentCall, currentCall.state != .Released else {
            call.resolve()
            return
        }
        do {
            try currentCall.terminate()
            call.resolve()
        } catch {
            call.reject("Failed to terminate call: \(error.localizedDescription)")
        }
    }

    @objc func acceptCall(_ call: CAPPluginCall) {
        guard let incomingCall = self.currentCall, incomingCall.state == .IncomingReceived else {
            call.reject("No incoming call to accept")
            return
        }
        
        // Stop the ringtone to begin audio resource cleanup.
        linphoneCore?.stopRinging()
        
        // Introduce a small delay to prevent a race condition upon accepting the call.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                try incomingCall.accept()
                call.resolve()
            } catch {
                call.reject("Failed to accept call after delay: \(error.localizedDescription)")
            }
        }
    }

    @objc func declineCall(_ call: CAPPluginCall) {
        guard let incomingCall = self.currentCall, incomingCall.state == .IncomingReceived else {
            call.reject("No incoming call to decline")
            return
        }
        
        // Stop the ringtone to begin the audio resource cleanup.
        linphoneCore?.stopRinging()
        
        // Introduce a small, asynchronous delay before declining.
        // This gives the mediastreamer thread time to fully destroy the ringtone's
        // audio filter, preventing the race condition that was causing the crash.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                try incomingCall.decline(reason: Reason.Declined)
                call.resolve()
            } catch {
                call.reject("Failed to decline call after delay: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - In-Call Actions
    @objc func setMute(_ call: CAPPluginCall) {
        let mute = call.getBool("mute") ?? false
        linphoneCore?.micEnabled = !mute
        call.resolve()
    }

    @objc func setSpeaker(_ call: CAPPluginCall) {
        let speakerOn = call.getBool("speaker") ?? false
        guard let core = self.linphoneCore else {
            call.reject("Linphone core not initialized")
            return
        }

        let speakerDevice = core.audioDevices.first { $0.type == .Speaker }
        let earpieceDevice = core.audioDevices.first { $0.type == .Earpiece }

        if speakerOn {
            if let speaker = speakerDevice {
                core.outputAudioDevice = speaker
            }
        } else {
            if let earpiece = earpieceDevice {
                core.outputAudioDevice = earpiece
            }
        }
        call.resolve()
    }

    // MARK: - Network Information
    @objc func getCurrentBssid(_ call: CAPPluginCall) {
        // A location manager is created for each request and cleaned up upon completion.
        locationManager = CLLocationManager()
        locationManager?.delegate = self

        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager?.authorizationStatus ?? .notDetermined
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission already granted, fetch BSSID and clean up when done.
            fetchBssid(for: call) { [weak self] in
                self?.locationManager = nil
            }
        case .notDetermined:
            // Permission not yet requested. Store the call and request permission.
            // The delegate will handle the result.
            self.bssidCall = call
            locationManager?.requestWhenInUseAuthorization()
        case .denied, .restricted:
            call.reject("Location permission is required to access Wi-Fi information. Please enable it in Settings.")
            self.locationManager = nil // Clean up manager instance.
        @unknown default:
            call.reject("Unknown location authorization status.")
            self.locationManager = nil // Clean up manager instance.
        }
    }

    /// Fetches the BSSID and executes a completion handler for cleanup.
    private func fetchBssid(for call: CAPPluginCall, completion: (() -> Void)? = nil) {
        NEHotspotNetwork.fetchCurrent { network in
            defer {
                // Ensure the completion handler is always called to clean up resources.
                // Dispatch to the main thread for safety when modifying properties.
                DispatchQueue.main.async {
                    completion?()
                }
            }
            
            guard let bssid = network?.bssid else {
                let errorMessage = "Could not retrieve BSSID. Ensure the device is connected to a Wi-Fi network and has Location Access enabled."
                print("⚠️ [SIP-IMPL] \(errorMessage)")
                call.reject(errorMessage)
                return
            }
            
            print("✅ [SIP-IMPL] Fetched BSSID: \(bssid)")
            call.resolve(["bssid": bssid])
        }
    }
    
    /// Handles the result of the location permission request.
    private func handleAuthorizationChange(for manager: CLLocationManager) {
        // Ensure there is a pending call to handle.
        guard let call = bssidCall else { return }

        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission was granted. Fetch the BSSID and clean up everything in the completion handler.
            fetchBssid(for: call) { [weak self] in
                self?.bssidCall = nil
                self?.locationManager = nil
            }
        case .denied, .restricted:
            // Permission denied. Reject the call and clean up resources immediately.
            call.reject("Location permission was denied. Cannot fetch Wi-Fi information.")
            self.bssidCall = nil
            self.locationManager = nil
        case .notDetermined:
            // The status is still undetermined, do nothing and wait for another change.
            break
        @unknown default:
            call.reject("An unknown error occurred with location permissions.")
            self.bssidCall = nil
            self.locationManager = nil
        }
    }
}

// MARK: - CoreDelegate
extension SipLinphone: CoreDelegate {
    public func onAccountRegistrationStateChanged(core: Core, account: Account, state: RegistrationState, message: String) {
        let stateStr = "\(state)".capitalized
        print("✅ [SIP-IMPL] Registration State Changed: \(stateStr) - \(message)")
        let data: [String: Any] = ["status": stateStr, "state": "Registration"]
        DispatchQueue.main.async {
            self.onRegistrationStateChanged?(data)
        }
    }

    public func onCallStateChanged(core: Core, call: Call, state: Call.State, message: String) {
        let callStateStr = "\(state)".capitalized
        print("✅ [SIP-IMPL] Call State Changed: \(callStateStr)")

        DispatchQueue.main.async {
            switch state {
            case .IncomingReceived:
                self.currentCall = call
                
                // The compiler error "Cannot call value of non-function type" indicates that `ring`
                // is a property, not a method. We assign the path of the ringtone file to this
                // property to start the ringing.
                let ringtonePath = core.config?.getString(section: "sound", key: "ring", defaultString: nil)
                core.ring = ringtonePath
                
                let remoteAddress = call.remoteAddress?.asString() ?? "Unknown"
                let data: [String: Any] = ["status": "IncomingReceived", "incomingFrom": remoteAddress, "state": "Call"]
                self.onCallStateChanged?(data)
            case .Connected:
                let data: [String: Any] = ["status": callStateStr, "state": "Call"]
                self.onCallStateChanged?(data)
            case .Released:
                // This is the single, reliable place to clear the current call.
                if self.currentCall?.remoteAddress?.asString() == call.remoteAddress?.asString() {
                    self.currentCall = nil
                }
                let data: [String: Any] = ["status": "Released", "state": "Call"]
                self.onCallStateChanged?(data)
            default:
                let data: [String: Any] = ["status": callStateStr, "state": "Call"]
                self.onCallStateChanged?(data)
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension SipLinphone: CLLocationManagerDelegate {
    // Legacy support for iOS < 14
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorizationChange(for: manager)
    }
    
    // For iOS 14+
    @available(iOS 14.0, *)
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationChange(for: manager)
    }
}
