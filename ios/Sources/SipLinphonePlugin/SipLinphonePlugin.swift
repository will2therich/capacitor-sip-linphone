import Foundation
import Capacitor

@objc(SipLinphonePlugin)
public class SipLinphonePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "SipLinphonePlugin"
    public let jsName = "SipLinphone"
    private let implementation = SipLinphone()

    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "initialize", returnType: "promise"),
        CAPPluginMethod(name: "register", returnType: "promise"),
        CAPPluginMethod(name: "unregister", returnType: "promise"),
        CAPPluginMethod(name: "makeCall", returnType: "promise"),
        CAPPluginMethod(name: "terminateCall", returnType: "promise"),
        CAPPluginMethod(name: "setMute", returnType: "promise"),
        CAPPluginMethod(name: "setSpeaker", returnType: "promise"),
        CAPPluginMethod(name: "acceptCall", returnType: "promise"),
        CAPPluginMethod(name: "declineCall", returnType: "promise"),
        CAPPluginMethod(name: "getRegistrationStatus", returnType: "promise"),
        CAPPluginMethod(name: "getCurrentBssid", returnType: "promise")
    ]

    // This method is called when the plugin is first initialized.
    public override func load() {
        super.load()
        self.setupEventListeners()
    }

    // Set up the closures to listen for events from the implementation class.
    private func setupEventListeners() {
        implementation.onRegistrationStateChanged = { [weak self] data in
            self?.notifyListeners("registrationStateChanged", data: data)
        }

        implementation.onIncomingCall = { [weak self] data in
            self?.notifyListeners("incomingCall", data: data)
        }

        implementation.onCallStateChanged = { [weak self] data in
            self?.notifyListeners("callStateChanged", data: data)
        }
    }

    // MARK: - Bridged Plugin Methods

    @objc func initialize(_ call: CAPPluginCall) {
        implementation.initialize(call)
    }

    @objc func register(_ call: CAPPluginCall) {
        implementation.register(call)
    }

    @objc func unregister(_ call: CAPPluginCall) {
        implementation.unregister(call)
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