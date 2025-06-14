import { WebPlugin } from '@capacitor/core';

import type { SipLinphonePlugin, RegisterOptions, CallOptions, MuteOption, SpeakerOption } from './definitions';

export class SipLinphoneWeb extends WebPlugin implements SipLinphonePlugin {
  constructor() {
    super();
  }

  async initialize(): Promise<void> {
    throw this.unavailable('SIP functionality is not available on the web.');
  }

  async register(_options: RegisterOptions): Promise<void> {
    throw this.unavailable('SIP functionality is not available on the web.');
  }

  async unregister(): Promise<void> {
    throw this.unavailable('SIP functionality is not available on the web.');
  }

  async acceptCall(): Promise<void> {
    throw this.unavailable('SIP functionality is not available on the web.');
  }

  async declineCall(): Promise<void> {
    throw this.unavailable('SIP functionality is not available on the web.');
  }

  async makeCall(_options: CallOptions): Promise<void> {
    throw this.unavailable('SIP functionality is not available on the web.');
  }

  async setMute(_options: MuteOption): Promise<void> {
    throw this.unavailable('SIP functionality is not available on the web.');
  }

  async setSpeaker(_options: SpeakerOption): Promise<void> {
    throw this.unavailable('SIP functionality is not available on the web.');
  }

  async hangUp(): Promise<void> {
    throw this.unavailable('SIP functionality is not available on the web.');
  }
}
