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
   * Listens for changes in the call state.
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
