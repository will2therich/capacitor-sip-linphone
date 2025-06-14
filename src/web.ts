import { WebPlugin } from '@capacitor/core';

import type { SipLinphonePlugin, RegisterOptions, CallOptions } from './definitions';

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

  async makeCall(_options: CallOptions): Promise<void> {
    throw this.unavailable('SIP functionality is not available on the web.');
  }

  async hangUp(): Promise<void> {
    throw this.unavailable('SIP functionality is not available on the web.');
  }
}
