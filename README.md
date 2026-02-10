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
| Android   | Lean Link Android SDK (bundled via plugin)          |
| iOS       | Lean Link iOS SDK (bundled via plugin)              |

## Setup by platform

> For full host‑app steps (Android & iOS), see `HOST_APP_SETUP.md`.

### Web

Load the Lean script once (e.g. in `index.html`), choosing the correct region:

```html
<!-- KSA -->
<script src="https://cdn.leantech.me/link/loader/prod/sa/latest/lean-link-loader.min.js"></script>

<!-- UAE -->
<script src="https://cdn.leantech.me/link/loader/prod/ae/latest/lean-link-loader.min.js"></script>
```

Pass `appToken` (and optionally `accessToken`) in `connect()`.

### Android

The plugin declares the Lean Android SDK dependency, so no extra setup in your app is needed. Run `npx cap sync` and build. Pass `appToken` in `connect()`.

### iOS

The plugin bundles the Lean iOS SDK (`LeanSDK.xcframework`) via its CocoaPods podspec, so you don't need to add the SDK separately in your app.

After `npm install` and `npx cap sync ios`, open the iOS project in Xcode and build.  
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

### Android: "Lean SDK not found"

This is usually a multi-module Gradle issue: the plugin module must be able to resolve the Lean SDK; the app module’s dependencies are not enough. In the host app:

1. **JitPack in `android/settings.gradle`** – Add `maven { url "https://jitpack.io" }` inside `dependencyResolutionManagement { repositories { ... } }` (Gradle 7+). Putting it only in `buildscript.repositories` is not enough.
2. **App module** – In `android/app/build.gradle` add `implementation "me.leantech:link-sdk-android:3.0.8"`.
3. **ProGuard** – If your app has `minifyEnabled true`, add keep rules for `me.leantech.link.android.**`, `me.leantech.lean.**`, `me.leantech.Lean.**`, and `-dontwarn me.leantech.**` in `app/proguard-rules.pro`. Recommended: Use the broader rule `-keep class me.leantech.** { *; }` to cover all SDK packages.
4. **Clean rebuild** – Run `npx cap sync android`, then `cd android && ./gradlew clean`, then rebuild in Android Studio.

See `HOST_APP_SETUP.md` for the full step-by-step and explanation.

## Development

- **Verify (all platforms):** `npm run verify`
- **Check (plugin + example app):** `npm run check`
- **Web only:** `npm run check:web`
- **iOS only:** `npm run check:ios`

See [VERIFY.md](VERIFY.md) for detailed steps. Before release: run `npm run lint`, then see [PRODUCTION.md](PRODUCTION.md). [CHANGELOG.md](CHANGELOG.md) lists version history.

## License

MIT
