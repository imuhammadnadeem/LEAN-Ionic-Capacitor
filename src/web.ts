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
  LeanVerifyAddressOptions,
  LeanAuthorizeConsentOptions,
  LeanCheckoutOptions,
  LeanManageConsentsOptions,
  LeanCaptureRedirectOptions,
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
      verifyAddress(options: LeanWebVerifyAddressOptions): void;
      authorizeConsent(options: LeanWebAuthorizeConsentOptions): void;
      checkout(options: LeanWebCheckoutOptions): void;
      manageConsents(options: LeanWebManageConsentsOptions): void;
      captureRedirect(options: LeanWebCaptureRedirectOptions): void;
    };
  }

  interface LeanWebBaseOptions {
    app_token?: string;
    access_token?: string;
    sandbox?: string | boolean;
    success_redirect_url?: string;
    fail_redirect_url?: string;
    destination_alias?: string;
    destination_avatar?: string;
    callback?: (response: LeanResult) => void;
  }

  interface LeanWebLinkOptions extends LeanWebBaseOptions {
    customer_id: string;
    permissions: string[];
    bank_identifier?: string;
  }

  interface LeanWebConnectOptions extends LeanWebLinkOptions {
    payment_destination_id?: string;
    account_type?: string;
    end_user_id?: string;
    access_to?: string;
    access_from?: string;
    show_consent_explanation?: boolean;
    customer_metadata?: string;
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
    end_user_id?: string;
    entity_id?: string;
  }

  interface LeanWebPayOptions extends LeanWebBaseOptions {
    payment_intent_id?: string;
    bulk_payment_intent_id?: string;
    account_id?: string;
    bank_identifier?: string;
    end_user_id?: string;
    risk_details?: Record<string, unknown>;
  }

  interface LeanWebVerifyAddressOptions extends LeanWebBaseOptions {
    customer_id: string;
    customer_name: string;
    permissions: string[];
  }

  interface LeanWebAuthorizeConsentOptions extends LeanWebBaseOptions {
    customer_id: string;
    consent_id: string;
    risk_details?: Record<string, unknown>;
  }

  interface LeanWebCheckoutOptions extends LeanWebBaseOptions {
    payment_intent_id: string;
    customer_name?: string;
    bank_identifier?: string;
    risk_details?: Record<string, unknown>;
  }

  interface LeanWebManageConsentsOptions extends LeanWebBaseOptions {
    customer_id: string;
  }

  interface LeanWebCaptureRedirectOptions extends LeanWebBaseOptions {
    customer_id: string;
    consent_attempt_id?: string;
    granular_status_code?: string;
    status_additional_info?: string;
  }
}

/**
 * Web implementation using Lean Link Web SDK.
 *
 * Load the appropriate loader script in your app (e.g. in index.html):
 *
 * - For KSA:
 *   <script src="https://cdn.leantech.me/link/loader/prod/sa/latest/lean-link-loader.min.js"></script>
 * - For UAE:
 *   <script src="https://cdn.leantech.me/link/loader/prod/ae/latest/lean-link-loader.min.js"></script>
 */
export class LeanWeb extends WebPlugin implements LeanPlugin {
  private ensureSdkAvailable(): void {
    if (!window.Lean) {
      throw new Error(
        'Lean Web SDK not loaded. Add the correct loader script to index.html, e.g. ' +
          '<script src="https://cdn.leantech.me/link/loader/prod/sa/latest/lean-link-loader.min.js"></script> (KSA).',
      );
    }
  }

  private toWebBase(options: {
    sandbox?: boolean;
    appToken?: string;
    accessToken?: string;
    successRedirectUrl?: string;
    failRedirectUrl?: string;
    destinationAlias?: string;
    destinationAvatar?: string;
  }): LeanWebBaseOptions {
    const sandbox = options.sandbox ?? true;
    const out: LeanWebBaseOptions = {
      sandbox: typeof sandbox === 'boolean' ? (sandbox ? 'true' : 'false') : String(sandbox),
    };
    if (options.appToken != null) out.app_token = options.appToken;
    if (options.accessToken != null) out.access_token = options.accessToken;
    if (options.successRedirectUrl != null) out.success_redirect_url = options.successRedirectUrl;
    if (options.failRedirectUrl != null) out.fail_redirect_url = options.failRedirectUrl;
    if (options.destinationAlias != null) out.destination_alias = options.destinationAlias;
    if (options.destinationAvatar != null) out.destination_avatar = options.destinationAvatar;
    return out;
  }

  private invokeFlow(
    method:
      | 'link'
      | 'connect'
      | 'reconnect'
      | 'createPaymentSource'
      | 'updatePaymentSource'
      | 'pay'
      | 'verifyAddress'
      | 'authorizeConsent'
      | 'checkout'
      | 'manageConsents'
      | 'captureRedirect',
    options:
      | LeanWebLinkOptions
      | LeanWebConnectOptions
      | LeanWebReconnectOptions
      | LeanWebCreatePaymentSourceOptions
      | LeanWebUpdatePaymentSourceOptions
      | LeanWebPayOptions
      | LeanWebVerifyAddressOptions
      | LeanWebAuthorizeConsentOptions
      | LeanWebCheckoutOptions
      | LeanWebManageConsentsOptions
      | LeanWebCaptureRedirectOptions,
  ): Promise<LeanResult> {
    this.ensureSdkAvailable();
    return new Promise((resolve, reject) => {
      const sdk = window.Lean;
      const flow = sdk?.[method] as ((params: typeof options) => void) | undefined;
      if (!flow) {
        reject(new Error(`Lean Web SDK method not available: ${method}`));
        return;
      }
      const params = { ...options, callback: (response: LeanResult) => resolve(response) };
      flow(params);
    });
  }

  async link(options: LeanLinkOptions): Promise<LeanResult> {
    if (!options?.customerId?.trim()) throw new Error('customerId is required');
    if (!Array.isArray(options.permissions)) throw new Error('permissions must be a non-null array');

    const params: LeanWebLinkOptions = {
      ...this.toWebBase(options),
      customer_id: options.customerId,
      permissions: options.permissions,
    };
    if (options.bankIdentifier != null) params.bank_identifier = options.bankIdentifier;
    return this.invokeFlow('link', params);
  }

  async connect(options: LeanConnectOptions): Promise<LeanResult> {
    if (!options?.customerId?.trim()) throw new Error('customerId is required');
    if (!Array.isArray(options.permissions)) throw new Error('permissions must be a non-null array');

    const params: LeanWebConnectOptions = {
      ...this.toWebBase(options),
      customer_id: options.customerId,
      permissions: options.permissions,
    };
    if (options.bankIdentifier != null) params.bank_identifier = options.bankIdentifier;
    if (options.paymentDestinationId != null) params.payment_destination_id = options.paymentDestinationId;
    if (options.accountType != null) params.account_type = options.accountType;
    if (options.endUserId != null) params.end_user_id = options.endUserId;
    if (options.accessTo != null) params.access_to = options.accessTo;
    if (options.accessFrom != null) params.access_from = options.accessFrom;
    if (options.showConsentExplanation != null) params.show_consent_explanation = options.showConsentExplanation;
    if (options.customerMetadata != null) params.customer_metadata = options.customerMetadata;
    return this.invokeFlow('connect', params);
  }

  async reconnect(options: LeanReconnectOptions): Promise<LeanResult> {
    if (!options?.reconnectId?.trim()) throw new Error('reconnectId is required');

    const params: LeanWebReconnectOptions = {
      ...this.toWebBase(options),
      reconnect_id: options.reconnectId,
    };
    return this.invokeFlow('reconnect', params);
  }

  async createPaymentSource(options: LeanCreatePaymentSourceOptions): Promise<LeanResult> {
    if (!options?.customerId?.trim()) throw new Error('customerId is required');

    const params: LeanWebCreatePaymentSourceOptions = {
      ...this.toWebBase(options),
      customer_id: options.customerId,
    };
    if (options.bankIdentifier != null) params.bank_identifier = options.bankIdentifier;
    if (options.paymentDestinationId != null) params.payment_destination_id = options.paymentDestinationId;
    return this.invokeFlow('createPaymentSource', params);
  }

  async updatePaymentSource(options: LeanUpdatePaymentSourceOptions): Promise<LeanResult> {
    if (!options?.customerId?.trim()) throw new Error('customerId is required');
    if (!options?.paymentSourceId?.trim()) throw new Error('paymentSourceId is required');
    if (!options?.paymentDestinationId?.trim()) throw new Error('paymentDestinationId is required');

    const params: LeanWebUpdatePaymentSourceOptions = {
      ...this.toWebBase(options),
      customer_id: options.customerId,
      payment_source_id: options.paymentSourceId,
      payment_destination_id: options.paymentDestinationId,
    };
    if (options.endUserId != null) params.end_user_id = options.endUserId;
    if (options.entityId != null) params.entity_id = options.entityId;
    return this.invokeFlow('updatePaymentSource', params);
  }

  async pay(options: LeanPayOptions): Promise<LeanResult> {
    if (!options?.paymentIntentId?.trim() && !options?.bulkPaymentIntentId?.trim()) {
      throw new Error('paymentIntentId or bulkPaymentIntentId is required');
    }

    const params: LeanWebPayOptions = {
      ...this.toWebBase(options),
    };
    if (options.paymentIntentId != null) params.payment_intent_id = options.paymentIntentId;
    if (options.bulkPaymentIntentId != null) params.bulk_payment_intent_id = options.bulkPaymentIntentId;
    if (options.accountId != null) params.account_id = options.accountId;
    if (options.bankIdentifier != null) params.bank_identifier = options.bankIdentifier;
    if (options.endUserId != null) params.end_user_id = options.endUserId;
    if (options.riskDetails != null) params.risk_details = options.riskDetails;
    return this.invokeFlow('pay', params);
  }

  async verifyAddress(options: LeanVerifyAddressOptions): Promise<LeanResult> {
    if (!options?.customerId?.trim()) throw new Error('customerId is required');
    if (!options?.customerName?.trim()) throw new Error('customerName is required');
    if (!Array.isArray(options.permissions)) throw new Error('permissions must be a non-null array');

    const params: LeanWebVerifyAddressOptions = {
      ...this.toWebBase(options),
      customer_id: options.customerId,
      customer_name: options.customerName,
      permissions: options.permissions,
    };
    return this.invokeFlow('verifyAddress', params);
  }

  async authorizeConsent(options: LeanAuthorizeConsentOptions): Promise<LeanResult> {
    if (!options?.customerId?.trim()) throw new Error('customerId is required');
    if (!options?.consentId?.trim()) throw new Error('consentId is required');
    if (!options?.successRedirectUrl?.trim()) throw new Error('successRedirectUrl is required');
    if (!options?.failRedirectUrl?.trim()) throw new Error('failRedirectUrl is required');

    const params: LeanWebAuthorizeConsentOptions = {
      ...this.toWebBase(options),
      customer_id: options.customerId,
      consent_id: options.consentId,
    };
    if (options.riskDetails != null) params.risk_details = options.riskDetails;
    return this.invokeFlow('authorizeConsent', params);
  }

  async checkout(options: LeanCheckoutOptions): Promise<LeanResult> {
    if (!options?.paymentIntentId?.trim()) throw new Error('paymentIntentId is required');

    const params: LeanWebCheckoutOptions = {
      ...this.toWebBase(options),
      payment_intent_id: options.paymentIntentId,
    };
    if (options.customerName != null) params.customer_name = options.customerName;
    if (options.bankIdentifier != null) params.bank_identifier = options.bankIdentifier;
    if (options.riskDetails != null) params.risk_details = options.riskDetails;
    return this.invokeFlow('checkout', params);
  }

  async manageConsents(options: LeanManageConsentsOptions): Promise<LeanResult> {
    if (!options?.customerId?.trim()) throw new Error('customerId is required');

    const params: LeanWebManageConsentsOptions = {
      ...this.toWebBase(options),
      customer_id: options.customerId,
    };
    return this.invokeFlow('manageConsents', params);
  }

  async captureRedirect(options: LeanCaptureRedirectOptions): Promise<LeanResult> {
    if (!options?.customerId?.trim()) throw new Error('customerId is required');

    const params: LeanWebCaptureRedirectOptions = {
      ...this.toWebBase(options),
      customer_id: options.customerId,
    };
    if (options.consentAttemptId != null) params.consent_attempt_id = options.consentAttemptId;
    if (options.granularStatusCode != null) params.granular_status_code = options.granularStatusCode;
    if (options.statusAdditionalInfo != null) params.status_additional_info = options.statusAdditionalInfo;
    return this.invokeFlow('captureRedirect', params);
  }
}
