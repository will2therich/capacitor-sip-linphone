import Foundation
import Capacitor

@objc(SipLinphone)
public class SipLinphone: CAPPlugin {
  private var call: String? // Placeholder for future Linphone call object

  @objc func initialize(_ call: CAPPluginCall) {
    // TODO: Setup Linphone core
    call.resolve()
  }

  @objc func register(_ call: CAPPluginCall) {
    guard let username = call.getString("username"),
          let password = call.getString("password"),
          let domain = call.getString("domain") else {
      call.reject("Missing parameters")
      return
    }

    // TODO: Perform SIP registration using Linphone SDK

    call.resolve()
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
    // TODO: Use iOS APIs to retrieve current BSSID (note: limited access in iOS 13+)
    let result = ["bssid": "Unavailable"]
    call.resolve(result)
  }

  public func echo(_ value: String) -> String {
      return value
  }
}
