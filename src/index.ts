import { registerPlugin } from '@capacitor/core';

import type { LeanPlugin } from './definitions';

const Lean = registerPlugin<LeanPlugin>('Lean', {
  web: () => import('./web').then((m) => new m.LeanWeb()),
});

export * from './definitions';
export { Lean };
