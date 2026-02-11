/**
 * Result returned from Lean SDK flows.
 * Matches Lean Link SDK response shape across Web, Android, and iOS.
 */
export interface LeanResult {
  status: 'SUCCESS' | 'CANCELLED' | 'ERROR';
  message?: string | null;
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
  /** Country code (e.g., 'sa'). Defaults to 'sa'. */
  country?: string;
  /** App token (required on Web; recommended on native). */
  appToken?: string;
  /** Customer-scoped access token for token exchange / backend auth. */
  accessToken?: string;
  /** Deep link / redirect URL on success. */
  successRedirectUrl?: string;
  /** Deep link / redirect URL on failure. */
  failRedirectUrl?: string;
}

/**
 * Options for linking a customer via Lean Link.
 */
export interface LeanLinkOptions extends LeanBaseOptions {
  /** Your Lean customer identifier. */
  customerId: string;
  /** Requested scopes: 'identity' | 'accounts' | 'transactions' | 'balance' | 'payments'. */
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
}

export interface LeanPayOptions extends LeanBaseOptions {
  /** Payment intent identifier. */
  paymentIntentId: string;
  /** Optional account to preselect for payment. */
  accountId?: string;
}

export interface LeanPlugin {
  /**
   * Link a customer for data permissions.
   */
  link(options: LeanLinkOptions): Promise<LeanResult>;
  /**
   * Connect a customer for combined data and payment journeys.
   */
  connect(options: LeanConnectOptions): Promise<LeanResult>;
  /**
   * Reconnect an existing entity.
   */
  reconnect(options: LeanReconnectOptions): Promise<LeanResult>;
  /**
   * Create a payment source for a customer.
   */
  createPaymentSource(options: LeanCreatePaymentSourceOptions): Promise<LeanResult>;
  /**
   * Update the destination of an existing payment source.
   */
  updatePaymentSource(options: LeanUpdatePaymentSourceOptions): Promise<LeanResult>;
  /**
   * Complete a payment intent.
   */
  pay(options: LeanPayOptions): Promise<LeanResult>;
}
