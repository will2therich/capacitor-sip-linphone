package com.weblabs.plugins.capacitorsiplinphone;
import android.content.Context;
import android.content.pm.PackageManager;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import android.Manifest;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

// Import Linphone SDK classes
import org.linphone.core.*;
import org.linphone.core.Account;
import org.linphone.core.AccountParams;
import org.linphone.core.Address;
import org.linphone.core.AuthInfo;
import org.linphone.core.Core;
import org.linphone.core.CoreListener;

import android.net.wifi.WifiManager;
import android.net.wifi.WifiInfo;
import android.location.LocationManager;
import android.content.Context;
import android.Manifest;
import androidx.core.app.ActivityCompat;
import android.content.pm.PackageManager;

import java.util.Timer;
import java.util.TimerTask;

@CapacitorPlugin(name = "SipLinphone")
public class SipLinphonePlugin extends Plugin {

    private Core linphoneCore;
    private CoreListener linphoneListener;
    private Timer timer;

    @Override
    public void load() {
        if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.RECORD_AUDIO)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(getActivity(), new String[]{Manifest.permission.RECORD_AUDIO}, 1234);
        }
        
        super.load();
        Context context = getContext();
        Factory factory = Factory.instance();
        factory.setDebugMode(true, "CapacitorLinphone");

        try {
            timer = new Timer("Linphone scheduler");

            linphoneCore = factory.createCore(null, null, context);

            NatPolicy natPolicy = linphoneCore.createNatPolicy();
            natPolicy.setStunEnabled(true);
            linphoneCore.setNatPolicy(natPolicy);

            // Audio-related flags
            linphoneCore.setUseRfc2833ForDtmf(true);
            linphoneCore.setPlaybackGainDb(1.0f);
            linphoneCore.setMicGainDb(1.0f);

            // Fully implement the CoreListener interface with all required methods
            linphoneListener = new CoreListenerImpl(this);

            // The method to add a listener is addListener
            linphoneCore.addListener(linphoneListener);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @PluginMethod
    public void initialize(PluginCall call) {
        if (linphoneCore != null) {
            linphoneCore.start();
            TimerTask task = new TimerTask() {
                public void run() {
                    if (linphoneCore != null) {
                        linphoneCore.iterate();
                    }
                }
            };
            timer.schedule(task, 0, 20);
            call.resolve();
        } else {
            call.reject("Linphone Core not initialized.");
        }
    }

    @PluginMethod
    public void register(PluginCall call) {
        String username = call.getString("username");
        String password = call.getString("password");
        String domain = call.getString("domain");

        if (username == null || domain == null) {
            call.reject("Username and domain are required for registration.");
            return;
        }

        try {
            AuthInfo authInfo = Factory.instance().createAuthInfo(username, null, password, null, null, domain);
            linphoneCore.addAuthInfo(authInfo);

            String identity = "sip:" + username + "@" + domain;
            String proxy = "sip:" + domain;

            Address identityAddress = Factory.instance().createAddress(identity);
            Address proxyAddress = Factory.instance().createAddress(proxy);

            if (identityAddress == null || proxyAddress == null) {
                call.reject("Failed to create valid SIP addresses.");
                return;
            }

            AccountParams accountParams = linphoneCore.createAccountParams();
            accountParams.setIdentityAddress(identityAddress);
            accountParams.setServerAddress(proxyAddress);
            accountParams.setRegisterEnabled(true);

            Account account = linphoneCore.createAccount(accountParams);
            linphoneCore.addAccount(account);
            linphoneCore.setDefaultAccount(account);

            call.resolve();
        } catch (Exception e) {
            e.printStackTrace();
            call.reject("Registration failed: " + e.getMessage());
        }
    }

    @PluginMethod
    public void unregister(PluginCall call) {
        linphoneCore.clearAccounts();
        linphoneCore.clearAllAuthInfo();
        call.resolve();
    }

    @PluginMethod
    public void makeCall(PluginCall call) {
        String addressString = call.getString("address");

        if (addressString == null || addressString.trim().isEmpty()) {
            call.reject("Missing or empty 'address' parameter.");
            return;
        }

        try {
            Address address = linphoneCore.interpretUrl("sip:" + addressString);
            if (address == null) {
                call.reject("Invalid SIP address.");
                return;
            }

            CallParams params = linphoneCore.createCallParams(null);
            if (params != null) {
                linphoneCore.inviteAddressWithParams("sip:" + address, params);
                call.resolve();
            } else {
                call.reject("Failed to create call parameters.");
            }

        } catch (Exception e) {
            e.printStackTrace();
            call.reject("Failed to make call: " + e.getMessage());
        }
    }

    @PluginMethod
    public void terminateCall(PluginCall call) {
        if (linphoneCore.getCurrentCall() != null) {
            linphoneCore.terminateAllCalls();
            call.resolve();
        } else {
            call.reject("No active call to terminate");
        }
    }

    @PluginMethod
    public void setMute(PluginCall call) {
        boolean mute = call.getBoolean("mute", false);
        if (linphoneCore != null) {
            linphoneCore.setMicEnabled(!mute);
            call.resolve();
        } else {
            call.reject("Linphone Core not initialized.");
        }
    }

    @PluginMethod
    public void setSpeaker(PluginCall call) {
        boolean speakerOn = call.getBoolean("speaker", false);
        if (linphoneCore != null) {
            AudioDevice speaker = null;
            AudioDevice earpiece = null;

            for (AudioDevice device : linphoneCore.getAudioDevices()) {
                if (device.getType() == AudioDevice.Type.Speaker) {
                    speaker = device;
                } else if (device.getType() == AudioDevice.Type.Earpiece) {
                    earpiece = device;
                }
            }

            if (speakerOn && speaker != null) {
                linphoneCore.setOutputAudioDevice(speaker);
            } else if (!speakerOn && earpiece != null) {
                linphoneCore.setOutputAudioDevice(earpiece);
            }

            call.resolve();
        } else {
            call.reject("Linphone Core not initialized.");
        }
    }

    @PluginMethod
    public void acceptCall(PluginCall call) {
        Call incoming = linphoneCore.getCurrentCall();
        if (incoming != null && incoming.getState() == Call.State.IncomingReceived) {
            CallParams params = linphoneCore.createCallParams(incoming);
            incoming.acceptWithParams(params);
            call.resolve();
        } else {
            call.reject("No incoming call to accept.");
        }
    }

    @PluginMethod
    public void declineCall(PluginCall call) {
        Call incoming = linphoneCore.getCurrentCall();
        if (incoming != null && incoming.getState() == Call.State.IncomingReceived) {
            incoming.terminate();
            call.resolve();
        } else {
            call.reject("No incoming call to decline.");
        }
    }

    @PluginMethod
    public void getRegistrationStatus(PluginCall call) {
        if (linphoneCore != null && linphoneCore.getDefaultAccount() != null) {
            RegistrationState state = linphoneCore.getDefaultAccount().getState();
            JSObject result = new JSObject();
            result.put("state", state.toString());
            call.resolve(result);
        } else {
            call.reject("Linphone not initialized or no default account.");
        }
    }

    @PluginMethod
    public void getCurrentBssid(PluginCall call) {
        if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(getActivity(), new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, 5678);
            call.reject("Location permission not granted.");
            return;
        }

        try {
            WifiManager wifiManager = (WifiManager) getContext().getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            if (wifiManager != null) {
                WifiInfo wifiInfo = wifiManager.getConnectionInfo();
                String bssid = wifiInfo.getBSSID();

                JSObject result = new JSObject();
                result.put("bssid", bssid != null ? bssid : "Unavailable");
                call.resolve(result);
            } else {
                call.reject("Could not access WiFiManager");
            }
        } catch (Exception e) {
            call.reject("Failed to retrieve BSSID: " + e.getMessage());
        }
    }


    @Override
    protected void handleOnDestroy() {
        try {
            if (timer != null) {
                timer.cancel();
            }
            if (linphoneCore != null) {
                // The method to remove a listener is removeListener
                linphoneCore.removeListener(linphoneListener);
                linphoneCore.stop();
            }
        } finally {
            linphoneCore = null;
            linphoneListener = null;
        }
        super.handleOnDestroy();
    }



    public void emitEvent(String name, JSObject data) {
        notifyListeners(name, data, true);
    }

}
