# lean-ionic-capacitor

Capacitor plugin for **Lean Technologies Link**: one API for Web, Android, and iOS. Connect customers to Payments and Data with native flows, deep linking, and sandbox/production support.

## Install

```bash
npm install lean-ionic-capacitor
npx cap sync
```

## Usage

```typescript
import { Lean } from 'lean-ionic-capacitor';

const result = await Lean.connect({
  customerId: '123',
  permissions: ['accounts', 'transactions'],
  sandbox: true,
  appToken: 'YOUR_APP_TOKEN',           // required on Web; recommended on native
  successRedirectUrl: 'https://yourapp.com/success',
  failRedirectUrl: 'https://yourapp.com/fail',
  bankIdentifier: 'LEANMB1',            // optional: skip bank list
});

// result: { status: 'SUCCESS' | 'CANCELLED' | 'ERROR', message?, bank?, ... }
```

## Platform overview

| Platform  | Implementation                                      |
| --------- | --------------------------------------------------- |
| Web       | Lean Link Web SDK (load script in your app)         |
| Android   | Lean Link Android SDK via reflection                |
| iOS       | Lean Link iOS SDK (Swift Package)                   |

## Setup by platform

> For full host‑app steps (Android & iOS), see `HOST_APP_SETUP.md`.

### Web

Load the Lean script once (e.g. in `index.html`):

```html
<script src="https://cdn.leantech.me/link/loader/prod/ae/latest/lean-link-loader.min.js"></script>
```

Pass `appToken` (and optionally `accessToken`) in `connect()`.

### Android

The plugin uses the Lean SDK at runtime. Your app must add:

1. **Repositories:** `maven { url 'https://jitpack.io' }` (project or settings)
2. **Dependencies:** `implementation "me.leantech:link-sdk-android:3.0.2"` (app module)

Pass `appToken` in `connect()`.

### iOS

Add the Lean iOS SDK in Xcode: **File → Add Package Dependencies** →  
`https://github.com/leantechnologies/link-sdk-ios-distribution`

Set `appToken` via `Lean.manager.setup(appToken, sandbox, version)` in app init, or pass it in `connect()`.

## API

### `Lean.connect(options)`

Connects a customer to Lean. Returns `Promise<LeanConnectResult>`.

#### Options

| Option                 | Type       | Required      | Description                                                              |
| ---------------------- | ---------- | ------------- | ------------------------------------------------------------------------ |
| `customerId`           | `string`   | Yes           | Your Lean customer identifier.                                           |
| `permissions`          | `string[]` | Yes           | `'identity'`, `'accounts'`, `'transactions'`, `'balance'`, `'payments'`. |
| `sandbox`              | `boolean`  | No            | Use sandbox (default `true`).                                            |
| `appToken`             | `string`   | Web / Android | Lean app token.                                                          |
| `accessToken`          | `string`   | No            | Customer-scoped token for token exchange.                                |
| `successRedirectUrl`   | `string`   | No            | Redirect URL on success (Open Finance).                                  |
| `failRedirectUrl`      | `string`   | No            | Redirect URL on failure (Open Finance).                                  |
| `bankIdentifier`       | `string`   | No            | Pre-select a bank (skip bank list).                                      |
| `paymentDestinationId` | `string`   | No            | Payment destination (defaults to your CMA account).                      |

#### Result

```ts
interface LeanConnectResult {
  status: 'SUCCESS' | 'CANCELLED' | 'ERROR';
  message?: string | null;
  last_api_response?: string | null;
  exit_point?: string | null;
  secondary_status?: string | null;
  bank?: { bank_identifier?: string; is_supported?: boolean } | null;
}
```

## Deep linking and token exchange

- **Deep linking:** Set `successRedirectUrl` and `failRedirectUrl` so Lean redirects back to your app.
- **Token exchange:** Issue a customer-scoped `accessToken` on your backend and pass it (with `appToken`) in `connect()`; the plugin forwards them to the Lean SDK.

## Troubleshooting

**Android: "Lean SDK not found"**  
Add JitPack and `implementation "me.leantech:link-sdk-android:3.0.2"` in your **app’s** `build.gradle`, then `npx cap sync android` and rebuild.

## Development

- **Verify (all platforms):** `npm run verify`
- **Check (plugin + example app):** `npm run check`
- **Web only:** `npm run check:web`
- **iOS only:** `npm run check:ios`

See [VERIFY.md](VERIFY.md) for detailed steps. Before release: run `npm run lint`, then see [PRODUCTION.md](PRODUCTION.md). [CHANGELOG.md](CHANGELOG.md) lists version history.

## License

MIT
