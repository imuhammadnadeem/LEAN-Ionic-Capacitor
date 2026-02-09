import { WebPlugin } from '@capacitor/core';

import type { LeanPlugin, LeanConnectOptions, LeanConnectResult } from './definitions';

declare global {
  interface Window {
    Lean?: {
      connect(options: LeanWebConnectOptions): void;
    };
  }

  interface LeanWebConnectOptions {
    app_token?: string;
    access_token?: string;
    customer_id: string;
    permissions: string[];
    sandbox?: string | boolean;
    success_redirect_url?: string;
    fail_redirect_url?: string;
    bank_identifier?: string;
    payment_destination_id?: string;
    callback?: (response: LeanConnectResult) => void;
  }
}

/**
 * Web implementation using Lean Link Web SDK.
 *
 * Load the appropriate loader script in your app (e.g. in index.html):
 *
 * - For **KSA**:
 *   <script src="https://cdn.leantech.me/link/loader/prod/sa/latest/lean-link-loader.min.js"></script>
 * - For **UAE**:
 *   <script src="https://cdn.leantech.me/link/loader/prod/ae/latest/lean-link-loader.min.js"></script>
 *
 * For Web, appToken (and optionally accessToken) should be passed in connect() or the SDK may not work.
 */
export class LeanWeb extends WebPlugin implements LeanPlugin {
  async connect(options: LeanConnectOptions): Promise<LeanConnectResult> {
    if (!options?.customerId?.trim()) {
      throw new Error('customerId is required');
    }
    if (!Array.isArray(options.permissions)) {
      throw new Error('permissions must be a non-null array');
    }

    return new Promise((resolve, reject) => {
      if (!window.Lean) {
        reject(
          new Error(
            'Lean Web SDK not loaded. Add the correct loader script to index.html, e.g. ' +
              '<script src="https://cdn.leantech.me/link/loader/prod/sa/latest/lean-link-loader.min.js"></script> (KSA) ' +
              'or <script src="https://cdn.leantech.me/link/loader/prod/ae/latest/lean-link-loader.min.js"></script> (UAE).',
          ),
        );
        return;
      }

      const sandbox = options.sandbox ?? true;
      const params: LeanWebConnectOptions = {
        customer_id: options.customerId,
        permissions: options.permissions,
        sandbox: typeof sandbox === 'boolean' ? (sandbox ? 'true' : 'false') : String(sandbox),
        callback: (response: LeanConnectResult) => resolve(response),
      };
      if (options.appToken != null) params.app_token = options.appToken;
      if (options.accessToken != null) params.access_token = options.accessToken;
      if (options.successRedirectUrl != null) params.success_redirect_url = options.successRedirectUrl;
      if (options.failRedirectUrl != null) params.fail_redirect_url = options.failRedirectUrl;
      if (options.bankIdentifier != null) params.bank_identifier = options.bankIdentifier;
      if (options.paymentDestinationId != null) params.payment_destination_id = options.paymentDestinationId;

      window.Lean.connect(params);
    });
  }
}
