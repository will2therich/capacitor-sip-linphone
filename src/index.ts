import { registerPlugin } from '@capacitor/core';

import type { SipLinphonePlugin } from './definitions';

const SipLinphone = registerPlugin<SipLinphonePlugin>('SipLinphone', {
  web: () => import('./web').then((m) => new m.SipLinphoneWeb()),
});

export * from './definitions';
export { SipLinphone };
