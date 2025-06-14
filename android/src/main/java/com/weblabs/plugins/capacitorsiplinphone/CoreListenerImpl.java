package com.weblabs.plugins.capacitorsiplinphone;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.getcapacitor.JSObject;
import org.linphone.core.*;

public class CoreListenerImpl implements CoreListener {
    private final SipLinphonePlugin plugin;

    public CoreListenerImpl(SipLinphonePlugin plugin) {
        this.plugin = plugin;
    }

    @Override
    public void onAccountRegistrationStateChanged(Core core, Account account, RegistrationState state, String message) {
        JSObject ret = new JSObject();
        ret.put("state", "Registration");
        ret.put("status", state.toString());
        ret.put("message", message);
//        plugin.notifyListeners("callStateChanged", ret, true);
        plugin.emitEvent("callStateChanged", ret);
    }

    @Override
    public void onCallStateChanged(Core core, Call call, Call.State state, String message) {
        JSObject ret = new JSObject();
        ret.put("state", "Call");
        ret.put("status", state.toString());
        ret.put("message", message);
//        plugin.notifyListeners("callStateChanged", ret, true);
        plugin.emitEvent("callStateChanged", ret);
    }

    // All other required methods with no-op implementations
    @Override public void onAccountAdded(Core core, Account account) {}
    @Override public void onAccountRemoved(Core core, Account account) {}
    @Override public void onDefaultAccountChanged(Core core, Account account) {}
    @Override public void onAudioDeviceChanged(Core core, AudioDevice audioDevice) {}
    @Override public void onAudioDevicesListUpdated(Core core) {}
    @Override public void onBuddyInfoUpdated(Core core, Friend friend) {}
    @Override public void onCallCreated(Core core, Call call) {}
    @Override public void onCallEncryptionChanged(Core core, Call call, boolean mediaEncryptionEnabled, String authenticationToken) {}
    @Override public void onCallLogUpdated(Core core, CallLog callLog) {}
    @Override public void onCallStatsUpdated(Core core, Call call, CallStats stats) {}
    @Override public void onChatRoomEphemeralMessageDeleted(Core core, ChatRoom chatRoom) {}
    @Override public void onChatRoomRead(Core core, ChatRoom chatRoom) {}
    @Override public void onChatRoomSessionStateChanged(Core core, ChatRoom chatRoom, Call.State state, String message) {}
    @Override public void onChatRoomStateChanged(Core core, ChatRoom chatRoom, ChatRoom.State state) {}
    @Override public void onChatRoomSubjectChanged(Core core, ChatRoom chatRoom) {}
    @Override public void onConfiguringStatus(Core core, ConfiguringState status, String message) {}
    @Override public void onConferenceInfoReceived(Core core, ConferenceInfo conferenceInfo) {}
    @Override public void onConferenceStateChanged(Core core, Conference conference, Conference.State state) {}
    @Override public void onDtmfReceived(Core core, Call call, int dtmf) {}
    @Override public void onEcCalibrationAudioInit(Core core) {}
    @Override public void onEcCalibrationAudioUninit(Core core) {}
    @Override public void onEcCalibrationResult(Core core, EcCalibratorStatus status, int delayMs) {}
    @Override public void onFirstCallStarted(Core core) {}
    @Override public void onFriendListCreated(Core core, FriendList friendList) {}
    @Override public void onFriendListRemoved(Core core, FriendList friendList) {}
    @Override public void onGlobalStateChanged(Core core, GlobalState state, String message) {}
    @Override public void onImeeUserRegistration(Core core, boolean status, String userId, String info) {}
    @Override public void onInfoReceived(Core core, Call call, InfoMessage message) {}
    @Override public void onIsComposingReceived(Core core, ChatRoom chatRoom) {}
    @Override public void onLastCallEnded(Core core) {}
    @Override public void onLogCollectionUploadProgressIndication(Core core, int offset, int total) {}
    @Override public void onLogCollectionUploadStateChanged(Core core, Core.LogCollectionUploadState state, String info) {}
    @Override public void onMessageReceived(Core core, ChatRoom chatRoom, ChatMessage message) {}
    @Override public void onMessageReceivedUnableDecrypt(Core core, ChatRoom chatRoom, ChatMessage message) {}
    @Override public void onMessageSent(Core core, ChatRoom chatRoom, ChatMessage message) {}
    @Override public void onNetworkReachable(Core core, boolean reachable) {}
    @Override public void onNewAlertTriggered(Core core, Alert alert) {}
    @Override public void onNewMessageReaction(Core core, ChatRoom chatRoom, ChatMessage message, ChatMessageReaction reaction) {}
    @Override public void onNotifyPresenceReceived(Core core, Friend linphoneFriend) {}
    @Override public void onNotifyPresenceReceivedForUriOrTel(Core core, Friend linphoneFriend, String uriOrTel, PresenceModel presenceModel) {}
    @Override public void onNotifyReceived(Core core, Event linphoneEvent, String notifiedEvent, Content body) {}
    @Override public void onNotifySent(Core core, Event linphoneEvent, Content body) {}
    @Override public void onPreviewDisplayErrorOccurred(Core core, int errorCode) {}
    @Override public void onPublishReceived(Core core, Event linphoneEvent, String publishEvent, Content body) {}
    @Override public void onPublishStateChanged(Core core, Event linphoneEvent, PublishState state) {}
    @Override public void onPushNotificationReceived(Core core, String payload) {}
    @Override public void onQrcodeFound(Core core, String result) {}
    @Override public void onReactionRemoved(Core core, ChatRoom chatRoom, ChatMessage message, Address address) {}
    @Override public void onReferReceived(Core core, Address referToAddr, Headers customHeaders, Content content) {}
    @Override public void onRegistrationStateChanged(Core core, ProxyConfig proxyConfig, RegistrationState state, String message) {}
    @Override public void onRemainingNumberOfFileTransferChanged(Core core, int downloadCount, int uploadCount) {}
    @Override public void onSubscriptionStateChanged(Core core, Event linphoneEvent, SubscriptionState state) {}
    @Override public void onSubscribeReceived(Core core, Event linphoneEvent, String subscribeEvent, Content body) {}
    @Override public void onTransferStateChanged(Core core, Call transferred, Call.State callState) {}
    @Override public void onCallGoclearAckSent(Core core, Call call) {}
    @Override public void onCallIdUpdated(Core core, String previousCallId, String currentCallId) {}
    @Override public void onCallReceiveMasterKeyChanged(Core core, Call call, String masterKey) {}
    @Override public void onCallSendMasterKeyChanged(Core core, Call call, String masterKey) {}
    @Override public void onAuthenticationRequested(Core core, AuthInfo authInfo, AuthMethod method) {}
    @Override public void onNewSubscriptionRequested(Core core, Friend linphoneFriend, String url) {}
    @Override public void onMessagesReceived(Core core, ChatRoom chatRoom, ChatMessage[] messages) {}
    @Override public void onSnapshotTaken(@NonNull Core core, @NonNull String filePath) {}
    @Override public void onMessageWaitingIndicationChanged(@NonNull Core core, @NonNull Event lev, @NonNull MessageWaitingIndication mwi) {}

    @Override     public void onVersionUpdateCheckResultReceived(@NonNull Core core, @NonNull VersionUpdateCheckResult result, @Nullable String version, @Nullable String url) {}
}
