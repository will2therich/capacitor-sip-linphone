import { WebPlugin } from '@capacitor/core';

import type { SipLinphonePlugin } from './definitions';

export class SipLinphoneWeb extends WebPlugin implements SipLinphonePlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
