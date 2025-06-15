import Foundation
import Capacitor

@objc(SipLinphonePlugin)
public class SipLinphonePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "SipLinphonePlugin"
    public let jsName = "SipLinphone"

    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "initialize", returnType: "promise"),
        CAPPluginMethod(name: "register", returnType: "promise"),
        CAPPluginMethod(name: "makeCall", returnType: "promise"),
        CAPPluginMethod(name: "terminateCall", returnType: "promise"),
        CAPPluginMethod(name: "setMute", returnType: "promise"),
        CAPPluginMethod(name: "setSpeaker", returnType: "promise"),
        CAPPluginMethod(name: "acceptCall", returnType: "promise"),
        CAPPluginMethod(name: "declineCall", returnType: "promise"),
        CAPPluginMethod(name: "getRegistrationStatus", returnType: "promise"),
        CAPPluginMethod(name: "getCurrentBssid", returnType: "promise")
    ]

    private let implementation = SipLinphone()

    @objc func initialize(_ call: CAPPluginCall) {
        implementation.initialize(call)
    }

    @objc func register(_ call: CAPPluginCall) {
        implementation.register(call)
    }

    @objc func makeCall(_ call: CAPPluginCall) {
        implementation.makeCall(call)
    }

    @objc func terminateCall(_ call: CAPPluginCall) {
        implementation.terminateCall(call)
    }

    @objc func setMute(_ call: CAPPluginCall) {
        implementation.setMute(call)
    }

    @objc func setSpeaker(_ call: CAPPluginCall) {
        implementation.setSpeaker(call)
    }

    @objc func acceptCall(_ call: CAPPluginCall) {
        implementation.acceptCall(call)
    }

    @objc func declineCall(_ call: CAPPluginCall) {
        implementation.declineCall(call)
    }

    @objc func getRegistrationStatus(_ call: CAPPluginCall) {
        implementation.getRegistrationStatus(call)
    }

    @objc func getCurrentBssid(_ call: CAPPluginCall) {
        implementation.getCurrentBssid(call)
    }
}
