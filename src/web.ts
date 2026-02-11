import { WebPlugin } from '@capacitor/core';

import type {
  LeanPlugin,
  LeanResult,
  LeanLinkOptions,
  LeanConnectOptions,
  LeanReconnectOptions,
  LeanCreatePaymentSourceOptions,
  LeanUpdatePaymentSourceOptions,
  LeanPayOptions,
} from './definitions';

declare global {
  interface Window {
    Lean?: {
      link(options: LeanWebLinkOptions): void;
      connect(options: LeanWebConnectOptions): void;
      reconnect(options: LeanWebReconnectOptions): void;
      createPaymentSource(options: LeanWebCreatePaymentSourceOptions): void;
      updatePaymentSource(options: LeanWebUpdatePaymentSourceOptions): void;
      pay(options: LeanWebPayOptions): void;
    };
  }

  interface LeanWebBaseOptions {
    app_token?: string;
    access_token?: string;
    sandbox?: string | boolean;
    success_redirect_url?: string;
    fail_redirect_url?: string;
    callback?: (response: LeanResult) => void;
  }

  interface LeanWebLinkOptions extends LeanWebBaseOptions {
    customer_id: string;
    permissions: string[];
    bank_identifier?: string;
  }

  interface LeanWebConnectOptions extends LeanWebLinkOptions {
    payment_destination_id?: string;
  }

  interface LeanWebReconnectOptions extends LeanWebBaseOptions {
    reconnect_id: string;
  }

  interface LeanWebCreatePaymentSourceOptions extends LeanWebBaseOptions {
    customer_id: string;
    bank_identifier?: string;
    payment_destination_id?: string;
  }

  interface LeanWebUpdatePaymentSourceOptions extends LeanWebBaseOptions {
    customer_id: string;
    payment_source_id: string;
    payment_destination_id: string;
  }

  interface LeanWebPayOptions extends LeanWebBaseOptions {
    payment_intent_id: string;
    account_id?: string;
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
 * For Web, appToken (and optionally accessToken) should be passed in
 * flow calls (link/connect/reconnect/createPaymentSource/updatePaymentSource/pay).
 */
export class LeanWeb extends WebPlugin implements LeanPlugin {
  /** Guards all web flows until the Lean loader script is available on window. */
  private ensureSdkAvailable(): void {
    if (!window.Lean) {
      throw new Error(
        'Lean Web SDK not loaded. Add the correct loader script to index.html, e.g. ' +
          '<script src="https://cdn.leantech.me/link/loader/prod/sa/latest/lean-link-loader.min.js"></script> (KSA).',
      );
    }
  }

  /** Maps plugin camelCase options to Lean Web snake_case base options. */
  private toWebBase(options: {
    sandbox?: boolean;
    appToken?: string;
    accessToken?: string;
    successRedirectUrl?: string;
    failRedirectUrl?: string;
  }): LeanWebBaseOptions {
    const sandbox = options.sandbox ?? true;
    const out: LeanWebBaseOptions = {
      sandbox: typeof sandbox === 'boolean' ? (sandbox ? 'true' : 'false') : String(sandbox),
    };
    if (options.appToken != null) out.app_token = options.appToken;
    if (options.accessToken != null) out.access_token = options.accessToken;
    if (options.successRedirectUrl != null) out.success_redirect_url = options.successRedirectUrl;
    if (options.failRedirectUrl != null) out.fail_redirect_url = options.failRedirectUrl;
    return out;
  }

  /** Invokes a Lean Web flow and resolves with callback payload. */
  private invokeFlow(
    method:
      | 'link'
      | 'connect'
      | 'reconnect'
      | 'createPaymentSource'
      | 'updatePaymentSource'
      | 'pay',
    options:
      | LeanWebLinkOptions
      | LeanWebConnectOptions
      | LeanWebReconnectOptions
      | LeanWebCreatePaymentSourceOptions
      | LeanWebUpdatePaymentSourceOptions
      | LeanWebPayOptions,
  ): Promise<LeanResult> {
    this.ensureSdkAvailable();
    return new Promise((resolve) => {
      const params = { ...options, callback: (response: LeanResult) => resolve(response) };
      window.Lean![method](params as never);
    });
  }

  async link(options: LeanLinkOptions): Promise<LeanResult> {
    if (!options?.customerId?.trim()) {
      throw new Error('customerId is required');
    }
    if (!Array.isArray(options.permissions)) {
      throw new Error('permissions must be a non-null array');
    }
    const params: LeanWebLinkOptions = {
      ...this.toWebBase(options),
      customer_id: options.customerId,
      permissions: options.permissions,
    };
    if (options.bankIdentifier != null) params.bank_identifier = options.bankIdentifier;
    return this.invokeFlow('link', params);
  }

  async connect(options: LeanConnectOptions): Promise<LeanResult> {
    if (!options?.customerId?.trim()) {
      throw new Error('customerId is required');
    }
    if (!Array.isArray(options.permissions)) {
      throw new Error('permissions must be a non-null array');
    }
    const params: LeanWebConnectOptions = {
      ...this.toWebBase(options),
      customer_id: options.customerId,
      permissions: options.permissions,
    };
    if (options.bankIdentifier != null) params.bank_identifier = options.bankIdentifier;
    if (options.paymentDestinationId != null) params.payment_destination_id = options.paymentDestinationId;
    return this.invokeFlow('connect', params);
  }

  async reconnect(options: LeanReconnectOptions): Promise<LeanResult> {
    if (!options?.reconnectId?.trim()) {
      throw new Error('reconnectId is required');
    }
    const params: LeanWebReconnectOptions = {
      ...this.toWebBase(options),
      reconnect_id: options.reconnectId,
    };
    return this.invokeFlow('reconnect', params);
  }

  async createPaymentSource(options: LeanCreatePaymentSourceOptions): Promise<LeanResult> {
    if (!options?.customerId?.trim()) {
      throw new Error('customerId is required');
    }
    const params: LeanWebCreatePaymentSourceOptions = {
      ...this.toWebBase(options),
      customer_id: options.customerId,
    };
    if (options.bankIdentifier != null) params.bank_identifier = options.bankIdentifier;
    if (options.paymentDestinationId != null) params.payment_destination_id = options.paymentDestinationId;
    return this.invokeFlow('createPaymentSource', params);
  }

  async updatePaymentSource(options: LeanUpdatePaymentSourceOptions): Promise<LeanResult> {
    if (!options?.customerId?.trim()) {
      throw new Error('customerId is required');
    }
    if (!options?.paymentSourceId?.trim()) {
      throw new Error('paymentSourceId is required');
    }
    if (!options?.paymentDestinationId?.trim()) {
      throw new Error('paymentDestinationId is required');
    }
    const params: LeanWebUpdatePaymentSourceOptions = {
      ...this.toWebBase(options),
      customer_id: options.customerId,
      payment_source_id: options.paymentSourceId,
      payment_destination_id: options.paymentDestinationId,
    };
    return this.invokeFlow('updatePaymentSource', params);
  }

  async pay(options: LeanPayOptions): Promise<LeanResult> {
    if (!options?.paymentIntentId?.trim()) {
      throw new Error('paymentIntentId is required');
    }
    const params: LeanWebPayOptions = {
      ...this.toWebBase(options),
      payment_intent_id: options.paymentIntentId,
    };
    if (options.accountId != null) params.account_id = options.accountId;
    return this.invokeFlow('pay', params);
  }
}
