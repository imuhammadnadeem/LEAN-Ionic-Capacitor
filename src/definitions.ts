/**
 * Result returned from Lean SDK flows.
 * Matches Lean Link SDK response shape across Web, Android, and iOS.
 */
export interface LeanResult {
  status: 'SUCCESS' | 'CANCELLED' | 'ERROR';
  message?: string | null;
  method?: string | null;
  last_api_response?: string | null;
  exit_point?: string | null;
  secondary_status?: string | null;
  bank?: {
    bank_identifier?: string;
    is_supported?: boolean;
  } | null;
}

// Backward-compatible alias.
export type LeanConnectResult = LeanResult;

export interface LeanBaseOptions {
  /** Use sandbox environment. Defaults to true. */
  sandbox?: boolean;
  /** Country code (e.g., 'sa', 'ae'). Defaults to 'sa'. */
  country?: string;
  /** App token (required on Web and Android; recommended on iOS). */
  appToken?: string;
  /** Customer-scoped access token for token exchange / backend auth. */
  accessToken?: string;
  /** Deep link / redirect URL on success. */
  successRedirectUrl?: string;
  /** Deep link / redirect URL on failure. */
  failRedirectUrl?: string;
  /** Optional destination alias shown in UI. */
  destinationAlias?: string;
  /** Optional destination avatar URL shown in UI. */
  destinationAvatar?: string;
}

/**
 * Options for linking a customer via Lean Link.
 */
export interface LeanLinkOptions extends LeanBaseOptions {
  /** Your Lean customer identifier. */
  customerId: string;
  /** Requested scopes. */
  permissions: string[];
  /** Skip bank list by pre-selecting a bank identifier. */
  bankIdentifier?: string;
}

/**
 * Options for connecting a customer via Lean Link.
 */
export interface LeanConnectOptions extends LeanLinkOptions {
  /** Payment destination ID (optional; defaults to your CMA account). */
  paymentDestinationId?: string;
  /** Optional account type filter. */
  accountType?: string;
  /** Optional end user identifier. */
  endUserId?: string;
  /** Consent access window start. */
  accessFrom?: string;
  /** Consent access window end. */
  accessTo?: string;
  /** Show consent explanation screen when supported. */
  showConsentExplanation?: boolean;
  /** Optional serialized customer metadata. */
  customerMetadata?: string;
}

export interface LeanReconnectOptions extends LeanBaseOptions {
  /** Reconnect identifier from your backend. */
  reconnectId: string;
}

export interface LeanCreatePaymentSourceOptions extends LeanBaseOptions {
  /** Your Lean customer identifier. */
  customerId: string;
  /** Skip bank list by pre-selecting a bank identifier. */
  bankIdentifier?: string;
  /** Payment destination ID (optional; defaults to your CMA account). */
  paymentDestinationId?: string;
}

export interface LeanUpdatePaymentSourceOptions extends LeanBaseOptions {
  /** Your Lean customer identifier. */
  customerId: string;
  /** Existing payment source identifier. */
  paymentSourceId: string;
  /** New payment destination identifier. */
  paymentDestinationId: string;
  /** Optional end user identifier. */
  endUserId?: string;
  /** Optional legal entity identifier. */
  entityId?: string;
}

export interface LeanPayOptions extends LeanBaseOptions {
  /** Payment intent identifier (required when bulkPaymentIntentId is not provided). */
  paymentIntentId?: string;
  /** Bulk payment intent identifier (required when paymentIntentId is not provided). */
  bulkPaymentIntentId?: string;
  /** Optional account to preselect for payment. */
  accountId?: string;
  /** Optional bank to preselect for payment. */
  bankIdentifier?: string;
  /** Optional end user identifier. */
  endUserId?: string;
  /** Optional Lean risk details payload. */
  riskDetails?: Record<string, unknown>;
}

export interface LeanVerifyAddressOptions extends LeanBaseOptions {
  customerId: string;
  customerName: string;
  permissions: string[];
}

export interface LeanAuthorizeConsentOptions extends LeanBaseOptions {
  customerId: string;
  consentId: string;
  successRedirectUrl: string;
  failRedirectUrl: string;
  riskDetails?: Record<string, unknown>;
}

export interface LeanCheckoutOptions extends LeanBaseOptions {
  paymentIntentId: string;
  customerName?: string;
  bankIdentifier?: string;
  riskDetails?: Record<string, unknown>;
}

export interface LeanManageConsentsOptions extends LeanBaseOptions {
  customerId: string;
}

export interface LeanCaptureRedirectOptions extends LeanBaseOptions {
  customerId: string;
  consentAttemptId?: string;
  granularStatusCode?: string;
  statusAdditionalInfo?: string;
}

export interface LeanPlugin {
  /** Link a customer for data permissions. */
  link(options: LeanLinkOptions): Promise<LeanResult>;
  /** Connect a customer for combined data and payment journeys. */
  connect(options: LeanConnectOptions): Promise<LeanResult>;
  /** Reconnect an existing entity. */
  reconnect(options: LeanReconnectOptions): Promise<LeanResult>;
  /** Create a payment source for a customer. */
  createPaymentSource(options: LeanCreatePaymentSourceOptions): Promise<LeanResult>;
  /** Update the destination of an existing payment source. */
  updatePaymentSource(options: LeanUpdatePaymentSourceOptions): Promise<LeanResult>;
  /** Complete a payment intent. */
  pay(options: LeanPayOptions): Promise<LeanResult>;
  /** Verify customer address. */
  verifyAddress(options: LeanVerifyAddressOptions): Promise<LeanResult>;
  /** Authorize a consent. */
  authorizeConsent(options: LeanAuthorizeConsentOptions): Promise<LeanResult>;
  /** Run checkout flow for a payment intent. */
  checkout(options: LeanCheckoutOptions): Promise<LeanResult>;
  /** Open consent management flow. */
  manageConsents(options: LeanManageConsentsOptions): Promise<LeanResult>;
  /** Capture redirect status flow. */
  captureRedirect(options: LeanCaptureRedirectOptions): Promise<LeanResult>;
}
