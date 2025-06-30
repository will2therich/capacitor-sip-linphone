import Foundation
import Capacitor
import SystemConfiguration.CaptiveNetwork
import CoreLocation
import NetworkExtension
import linphonesw

@objc(SipLinphone)
public class SipLinphone: CAPPlugin {
    private var call: String? // Placeholder for future Linphone call object
    private var locationManager: CLLocationManager?
    private var bssidCall: CAPPluginCall?
    private var linphoneCore: Core? = nil
    private var coreTimer: Timer?
    
    @objc func initialize(_ call: CAPPluginCall) {
        do {
            linphoneCore = try Factory.Instance.createCore(configPath: nil, factoryConfigPath: nil, systemContext: nil)
            
            // Add 'try' to acknowledge that start() can fail
            try linphoneCore?.start()
            
            // Start iteration timer
            coreTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
                self?.linphoneCore?.iterate()
            }
            
            call.resolve()
        } catch {
            // This block now catches errors from both createCore() and start()
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
            // AuthInfo creation is correct
            let authInfo = try Factory.Instance.createAuthInfo(username: username, userid: nil, passwd: password, ha1: nil, realm: nil, domain: domain)
            core.addAuthInfo(info: authInfo)
            
            // AccountParams creation is correct
            let accountParams = try core.createAccountParams()
            
            // --- THIS IS THE CORRECTED SECTION ---
            
            // 1. Create the identity address using 'try'
            let identityStr = "sip:\(username)@\(domain)"
            let identityAddr = try Factory.Instance.createAddress(addr: identityStr)
            
            // 2. Assign the identity Address object
            try accountParams.setIdentityaddress(newValue: identityAddr)
            
            // 3. Create the server address using 'try'
            let proxyStr = "sip:\(domain)"
            let proxyAddr = try Factory.Instance.createAddress(addr: proxyStr)
            
            // 4. Assign the server address
            try accountParams.setServeraddress(newValue: proxyAddr)
            
            // 5. Enable registration
            accountParams.registerEnabled = true
            
            
            // Account creation and adding it to the core remains the same
            let account = try core.createAccount(params: accountParams)
            try core.addAccount(account: account)
            core.defaultAccount = account
            
            call.resolve(["status": "Registration in progress..."])
        } catch {
            // This single catch block now handles potential errors from:
            // - createAuthInfo
            // - createAccountParams
            // - createAddress (for both identity and proxy)
            // - createAccount
            call.reject("Registration error: \(error.localizedDescription)")
        }
    }
    
  @objc func makeCall(_ call: CAPPluginCall) {
    guard let address = call.getString("address") else {
      call.reject("Missing address")
      return
    }

    // TODO: Initiate outgoing call to address

    call.resolve()
  }

  @objc func terminateCall(_ call: CAPPluginCall) {
    // TODO: Terminate current call

    call.resolve()
  }

  @objc func setMute(_ call: CAPPluginCall) {
    let mute = call.getBool("mute") ?? false
    // TODO: Toggle mic mute state
    call.resolve()
  }

  @objc func setSpeaker(_ call: CAPPluginCall) {
    let speaker = call.getBool("speaker") ?? false
    // TODO: Toggle audio output to speaker/earpiece
    call.resolve()
  }

  @objc func acceptCall(_ call: CAPPluginCall) {
    // TODO: Accept incoming call
    call.resolve()
  }

  @objc func declineCall(_ call: CAPPluginCall) {
    // TODO: Decline incoming call
    call.resolve()
  }

  @objc func getRegistrationStatus(_ call: CAPPluginCall) {
    // TODO: Return registration state
    let result = ["state": "Unknown"]
    call.resolve(result)
  }


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

}

extension SipLinphone: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let call = bssidCall else { return }

        let status = manager.authorizationStatus

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            self.fetchBssid { bssid in
                call.resolve(["bssid": bssid ?? "d8:ec:5e:d5:cb:56"])
                self.bssidCall = nil
                self.locationManager = nil
            }
        } else {
            call.resolve(["bssid": "d8:ec:5e:d5:cb:56"]) // mock fallback
            self.bssidCall = nil
            self.locationManager = nil
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

