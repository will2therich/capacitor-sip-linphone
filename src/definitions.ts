import type { PluginListenerHandle } from '@capacitor/core';

/**
 * An interface defining the options for registering with a SIP server.
 */
export interface RegisterOptions {
  /** The SIP username. */
  username: string;
  /** The SIP user's password. */
  password?: string;
  /** The SIP domain/server address. */
  domain: string;
}

/**
 * An interface for call options.
 */
export interface CallOptions {
  /** The SIP address to call (e.g., "sip:user@domain.com"). */
  address: string;
}

export interface MuteOption {
  mute: boolean
}

export interface SpeakerOption {
  speaker: boolean
}

/**
 * Defines the public API for the SipLinphone plugin.
 */
export interface SipLinphonePlugin {
  /**
   * Initializes the Linphone core. This must be called before any other method.
   * @returns {Promise<void>} A promise that resolves when initialization is complete.
   */
  initialize(): Promise<void>;

  /**
   * Registers the user agent with the SIP server.
   * @param options - The registration options.
   * @returns {Promise<void>} A promise that resolves on successful registration attempt.
   */
  register(options: RegisterOptions): Promise<void>;

  /**
   * Unregisters the user agent from the SIP server.
   * @returns {Promise<void>} A promise that resolves when unregistered.
   */
  unregister(): Promise<void>;

  /**
   * Makes an outgoing call.
   * @param options - The call options.
   * @returns {Promise<void>} A promise that resolves when the call is initiated.
   */
  makeCall(options: CallOptions): Promise<void>;

  /**
   * Hangs up the current call.
   * @returns {Promise<void>} A promise that resolves when the call is terminated.
   */
  hangUp(): Promise<void>;

  /**
   * Accepts an incoming call.
   * @returns {Promise<void>} A promise that resolves when the call is terminated.
   */
  acceptCall(): Promise<void>;

  /**
   * Declines an incoming call.
   * @returns {Promise<void>} A promise that resolves when the call is terminated.
   */
  declineCall(): Promise<void>;

  /**
   * Allows toggling of the microphone.
   * @param options - options
   * @returns {Promise<void>} A promise that resolves when the call is terminated.
   */
  setMute(options: MuteOption): Promise<void>;

  /**
   * Allows toggling of the speaker.
   * @param options - the mute data
   * @returns {Promise<void>} A promise that resolves when the call is terminated.
   */
  setSpeaker(options: SpeakerOption): Promise<void>;

  /**
   * Listens for changes in the call state. gives SIP events, incoming & outgoing call updates
   *
   * @param eventName - The name of the event to listen for ('callStateChanged').
   * @param callback - The function to execute when the event occurs.
   * @returns {Promise<PluginListenerHandle>} A promise that resolves with a listener handle.
   */
  addListener(
      eventName: 'callStateChanged',
      callback: (data: { state: string }) => void,
  ): Promise<PluginListenerHandle>;
}
