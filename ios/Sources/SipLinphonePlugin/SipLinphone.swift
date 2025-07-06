import Capacitor
import CoreLocation
import Foundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import linphonesw

// Inherit from NSObject to conform to CLLocationManagerDelegate
public class SipLinphone: NSObject {
    // MARK: - Properties
    private var currentCall: Call?
    private var locationManager: CLLocationManager?
    private var bssidCall: CAPPluginCall?
    private var linphoneCore: Core?
    private var coreTimer: Timer?

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
            linphoneCore = try Factory.Instance.createCore(configPath: nil, factoryConfigPath: nil, systemContext: nil)
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
            self.currentCall = nil
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
        locationManager = CLLocationManager()
        locationManager?.delegate = self

        switch locationManager?.authorizationStatus ?? .notDetermined {
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
                let data: [String: Any] = ["status": "IncomingReceived", "incomingFrom": "1001", "state": "Call"]
                self.onCallStateChanged?(data)
            case .Connected:
                let data: [String: Any] = ["status": callStateStr, "state": "Call"]
                self.onCallStateChanged?(data)
            case .Released:
                self.currentCall = nil
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
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let call = bssidCall else { return }

        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
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
