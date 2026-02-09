/**
 * Result returned from Lean.connect() (and native redirect flows).
 * Matches Lean Link SDK response shape across Web, Android, and iOS.
 */
export interface LeanConnectResult {
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

/**
 * Options for connecting a customer via Lean Link (Web / Android / iOS).
 */
export interface LeanConnectOptions {
  /** Your Lean customer identifier. */
  customerId: string;
  /** Requested scopes: 'identity' | 'accounts' | 'transactions' | 'balance' | 'payments'. */
  permissions: string[];
  /** Use sandbox environment. Defaults to true. */
  sandbox?: boolean;
  /** App token (required for Web; optional for native if configured separately). */
  appToken?: string;
  /** Customer-scoped access token for token exchange / backend auth (Web & native). */
  accessToken?: string;
  /** Deep link / redirect URL on success (Open Finance flows). */
  successRedirectUrl?: string;
  /** Deep link / redirect URL on failure (Open Finance flows). */
  failRedirectUrl?: string;
  /** Skip bank list by pre-selecting a bank identifier. */
  bankIdentifier?: string;
  /** Payment destination ID (optional; defaults to your CMA account). */
  paymentDestinationId?: string;
}

export interface LeanPlugin {
  /**
   * Connect a customer to Lean (Payments + Data). Uses Web SDK on web,
   * native Lean SDK on Android and iOS. Supports deep linking and
   * sandbox/production via options.
   * @throws if customerId is missing, permissions are invalid, or SDK is not available.
   */
  connect(options: LeanConnectOptions): Promise<LeanConnectResult>;
}
