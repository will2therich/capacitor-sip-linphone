import Foundation
import Capacitor
import SystemConfiguration.CaptiveNetwork
import CoreLocation
import NetworkExtension
import linphonesw

@objc(SipLinphone)
public class SipLinphone: CAPPlugin {
    // Keep a reference to the active or incoming Linphone call object
    private var currentCall: Call?
    private var locationManager: CLLocationManager?
    private var bssidCall: CAPPluginCall?
    private var linphoneCore: Core? = nil
    private var coreTimer: Timer?
    
    // MARK: - Plugin Lifecycle
    
    public override func load() {
        // This is a good place to add setup that needs to happen once.
        // For microphone permissions, ensure "Privacy - Microphone Usage Description"
        // is set in your app's Info.plist.
    }
    
    deinit {
        coreTimer?.invalidate()
        linphoneCore?.removeDelegate(delegate: self)
        linphoneCore?.stop()
    }

    // MARK: - Core and Registration
    
    @objc func initialize(_ call: CAPPluginCall) {
        do {
            
            linphoneCore = try Factory.Instance.createCore(configPath: nil, factoryConfigPath: nil, systemContext: nil)
            
            // Add the delegate to listen for core events
            linphoneCore?.addDelegate(delegate: self)
            
            // Start the core
            try linphoneCore?.start()
            
            // Start iteration timer to process events
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
              let core = linphoneCore else {
            call.reject("Missing SIP credentials or core not initialized")
            return
        }
        
        do {
            let authInfo = try Factory.Instance.createAuthInfo(username: username, userid: nil, passwd: password, ha1: nil, realm: nil, domain: domain)
            core.addAuthInfo(info: authInfo)
            
            let accountParams = try core.createAccountParams()
            
            let identityStr = "sip:\(username)@\(domain)"
            let identityAddr = try Factory.Instance.createAddress(addr: identityStr)
            try accountParams.setIdentityaddress(newValue: identityAddr)
            
            let proxyStr = "sip:\(domain)"
            let proxyAddr = try Factory.Instance.createAddress(addr: proxyStr)
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
        do {
            if let currentCall = self.currentCall {
                
                // If we have a specific call, terminate it
                try currentCall.terminate()
                self.currentCall = nil
            } else {
                // Otherwise, terminate all calls as a fallback
                try linphoneCore?.terminateAllCalls()
            }
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

        do {
            try incomingCall.accept()
            call.resolve()
        } catch {
            call.reject("Failed to accept call: \(error.localizedDescription)")
        }
    }

    @objc func declineCall(_ call: CAPPluginCall) {
        guard let incomingCall = self.currentCall, incomingCall.state == .IncomingReceived else {
            call.reject("No incoming call to decline")
            return
        }
        
        do {
            try incomingCall.decline(reason: Reason.Declined)
            self.currentCall = nil
            call.resolve()
        } catch {
            call.reject("Failed to decline call: \(error.localizedDescription)")
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

        // Find the available speaker and earpiece audio devices
        let speakerDevice = core.audioDevices.first { $0.type == .Speaker }
        let earpieceDevice = core.audioDevices.first { $0.type == .Earpiece }

        if speakerOn {
            // If speaker mode is requested, set the output device to speaker
            if let speaker = speakerDevice {
                core.outputAudioDevice = speaker
            }
        } else {
            // Otherwise, set it back to the earpiece
            if let earpiece = earpieceDevice {
                core.outputAudioDevice = earpiece
            }
        }
        
        call.resolve()
    }
    
    // MARK: - Network Information

    @objc func getCurrentBssid(_ call: CAPPluginCall) {
        locationManager = CLLocationManager()
        locationManager?.delegate = self

        let status = locationManager?.authorizationStatus ?? .notDetermined

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            fetchBssid { bssid in
                call.resolve(["bssid": bssid ?? "d8:ec:5e:d5:cb:56"])
            }
        case .notDetermined:
            bssidCall = call
            locationManager?.requestWhenInUseAuthorization()
        default:
            call.reject("Location permission not granted")
        }
    }
    
    private func fetchBssid(completion: @escaping (String?) -> Void) {
        NEHotspotNetwork.fetchCurrent { network in
            if let bssid = network?.bssid {
                print("Fetched BSSID: \(bssid)")
                completion(bssid)
            } else {
                print("Failed to fetch BSSID")
                completion(nil)
            }
        }
    }
}

// MARK: - CoreDelegate

extension SipLinphone: CoreDelegate {
    public func onAccountRegistrationStateChanged(core: Core, account: Account, state: RegistrationState, message: String) {
        let stateStr = "\(state)".capitalized
        
        print("✅ [SIP-PLUGIN] Registration State Changed: \(stateStr) - \(message)")
        
        // Send a "state" field along with the "status"
        self.notifyListeners("registrationStateChanged", data: ["status": stateStr, "state": "Registration"])
    }
    
    public func onCallStateChanged(core: Core, call: Call, state: Call.State, message: String) {
        var callStateStr = "\(state)".capitalized
        
        switch state {
        case .IncomingReceived:
            self.currentCall = call // Store the incoming call object
            self.notifyListeners("incomingCall", data: ["callId": "123", "status": callStateStr])
        case .Connected:
            self.notifyListeners("callStateChanged", data: ["status": callStateStr, "state": "Call"])
        case .Released:
            callStateStr = "Released" // Use a clearer term
            self.currentCall = nil // Clear the call object when it's terminated
            self.notifyListeners("callStateChanged", data: ["status": callStateStr, "state": "Call"])
        default:
            // Optionally notify for other states as well
            self.notifyListeners("callStateChanged", data: ["status": callStateStr, "state": "Call"])
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension SipLinphone: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let call = bssidCall else { return }

        let status = manager.authorizationStatus

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            self.fetchBssid { bssid in
                call.resolve(["bssid": bssid ?? "d8:ec:5e:d5:cb:56"]) // Mock for simulator
                self.bssidCall = nil
                self.locationManager = nil
            }
        } else {
            call.resolve(["bssid": "d8:ec:5e:d5:cb:56"]) // Mock fallback
            self.bssidCall = nil
            self.locationManager = nil
        }
    }
}
