# capacitor-sip-linphone

Gives SIP functionality to a capacitor app

## Install

```bash
npm install capacitor-sip-linphone
npx cap sync
```

## API

<docgen-index>

* [`initialize()`](#initialize)
* [`register(...)`](#register)
* [`unregister()`](#unregister)
* [`makeCall(...)`](#makecall)
* [`hangUp()`](#hangup)
* [`acceptCall()`](#acceptcall)
* [`declineCall()`](#declinecall)
* [`setMute(...)`](#setmute)
* [`setSpeaker(...)`](#setspeaker)
* [`addListener('callStateChanged', ...)`](#addlistenercallstatechanged-)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

Defines the public API for the SipLinphone plugin.

### initialize()

```typescript
initialize() => Promise<void>
```

Initializes the Linphone core. This must be called before any other method.

--------------------


### register(...)

```typescript
register(options: RegisterOptions) => Promise<void>
```

Registers the user agent with the SIP server.

| Param         | Type                                                        | Description                 |
| ------------- | ----------------------------------------------------------- | --------------------------- |
| **`options`** | <code><a href="#registeroptions">RegisterOptions</a></code> | - The registration options. |

--------------------


### unregister()

```typescript
unregister() => Promise<void>
```

Unregisters the user agent from the SIP server.

--------------------


### makeCall(...)

```typescript
makeCall(options: CallOptions) => Promise<void>
```

Makes an outgoing call.

| Param         | Type                                                | Description         |
| ------------- | --------------------------------------------------- | ------------------- |
| **`options`** | <code><a href="#calloptions">CallOptions</a></code> | - The call options. |

--------------------


### hangUp()

```typescript
hangUp() => Promise<void>
```

Hangs up the current call.

--------------------


### acceptCall()

```typescript
acceptCall() => Promise<void>
```

Accepts an incoming call.

--------------------


### declineCall()

```typescript
declineCall() => Promise<void>
```

Declines an incoming call.

--------------------


### setMute(...)

```typescript
setMute(options: MuteOption) => Promise<void>
```

Allows toggling of the microphone.

| Param         | Type                                              | Description |
| ------------- | ------------------------------------------------- | ----------- |
| **`options`** | <code><a href="#muteoption">MuteOption</a></code> | - options   |

--------------------


### setSpeaker(...)

```typescript
setSpeaker(options: SpeakerOption) => Promise<void>
```

Allows toggling of the speaker.

| Param         | Type                                                    | Description     |
| ------------- | ------------------------------------------------------- | --------------- |
| **`options`** | <code><a href="#speakeroption">SpeakerOption</a></code> | - the mute data |

--------------------


### addListener('callStateChanged', ...)

```typescript
addListener(eventName: 'callStateChanged', callback: (data: { state: string; }) => void) => Promise<PluginListenerHandle>
```

Listens for changes in the call state. gives SIP events, incoming & outgoing call updates

| Param           | Type                                               | Description                                                 |
| --------------- | -------------------------------------------------- | ----------------------------------------------------------- |
| **`eventName`** | <code>'callStateChanged'</code>                    | - The name of the event to listen for ('callStateChanged'). |
| **`callback`**  | <code>(data: { state: string; }) =&gt; void</code> | - The function to execute when the event occurs.            |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### Interfaces


#### RegisterOptions

An interface defining the options for registering with a SIP server.

| Prop           | Type                | Description                    |
| -------------- | ------------------- | ------------------------------ |
| **`username`** | <code>string</code> | The SIP username.              |
| **`password`** | <code>string</code> | The SIP user's password.       |
| **`domain`**   | <code>string</code> | The SIP domain/server address. |


#### CallOptions

An interface for call options.

| Prop          | Type                | Description                                            |
| ------------- | ------------------- | ------------------------------------------------------ |
| **`address`** | <code>string</code> | The SIP address to call (e.g., "sip:user@domain.com"). |


#### MuteOption

| Prop       | Type                 |
| ---------- | -------------------- |
| **`mute`** | <code>boolean</code> |


#### SpeakerOption

| Prop          | Type                 |
| ------------- | -------------------- |
| **`speaker`** | <code>boolean</code> |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |

</docgen-api>
