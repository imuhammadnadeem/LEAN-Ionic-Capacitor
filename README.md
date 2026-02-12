# lean-ionic-capacitor

[![npm version](https://img.shields.io/npm/v/lean-ionic-capacitor.svg)](https://www.npmjs.com/package/lean-ionic-capacitor)
[![npm downloads](https://img.shields.io/npm/dm/lean-ionic-capacitor.svg)](https://www.npmjs.com/package/lean-ionic-capacitor)
[![license](https://img.shields.io/npm/l/lean-ionic-capacitor.svg)](https://github.com/imuhammadnadeem/LEAN-Ionic-Capacitor/blob/main/LICENSE)

Capacitor plugin for **Lean Technologies Link**: one API for Web, Android, and iOS. Connect customers to Payments and Data with native flows, deep linking, and sandbox/production support.

## Table of Contents

- [Requirements](#requirements)
- [Install](#install)
- [Usage](#usage)
  - [Quick Start Examples](#quick-start-examples)
- [Platform Overview](#platform-overview)
- [Setup by Platform](#setup-by-platform)
  - [Web](#web)
  - [Android](#android)
  - [iOS](#ios)
- [API](#api)
- [Deep Linking and Token Exchange](#deep-linking-and-token-exchange)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

## Requirements

- **Capacitor**: ^6.0.0 || ^7.0.0 || ^8.0.0
- **Node.js**: 18.x or higher
- **iOS**: 15.0 or higher
- **Android**: API level 21 (Android 5.0) or higher
- **Xcode**: 14.0 or higher (for iOS development)
- **Android Studio**: Arctic Fox or higher (for Android development)

## Install

```bash
npm install lean-ionic-capacitor
npx cap sync
```

## Usage

```typescript
import { Lean } from 'lean-ionic-capacitor';

const connectResult = await Lean.connect({
  customerId: '123',
  permissions: ['accounts', 'transactions'],
  sandbox: true,
  country: 'sa', // defaults to 'sa'
  appToken: 'YOUR_APP_TOKEN', // required on Web; recommended on native
  successRedirectUrl: 'https://yourapp.com/success',
  failRedirectUrl: 'https://yourapp.com/fail',
  bankIdentifier: 'LEANMB1',
  paymentDestinationId: 'destination-id',
});

const payResult = await Lean.pay({
  paymentIntentId: 'payment-intent-id',
  accountId: 'account-id', // optional
  sandbox: true,
  appToken: 'YOUR_APP_TOKEN',
});

// All flows return: { status: 'SUCCESS' | 'CANCELLED' | 'ERROR', ... }
```

### Quick Start Examples

#### Link Account (Data Permissions)

```typescript
import { Lean } from 'lean-ionic-capacitor';

const linkResult = await Lean.link({
  customerId: 'customer-123',
  permissions: ['identity', 'accounts', 'balance', 'transactions'],
  appToken: 'YOUR_APP_TOKEN',
  sandbox: true,
  country: 'sa',
});

if (linkResult.status === 'SUCCESS') {
  console.log('Account linked successfully');
}
```

#### Reconnect Existing Account

```typescript
const reconnectResult = await Lean.reconnect({
  reconnectId: 'reconnect-id-from-backend',
  appToken: 'YOUR_APP_TOKEN',
  sandbox: true,
});

if (reconnectResult.status === 'SUCCESS') {
  console.log('Account reconnected successfully');
}
```

#### Create Payment Source

```typescript
const paymentSourceResult = await Lean.createPaymentSource({
  customerId: 'customer-123',
  appToken: 'YOUR_APP_TOKEN',
  paymentDestinationId: 'destination-id',
  sandbox: true,
});

if (paymentSourceResult.status === 'SUCCESS') {
  console.log('Payment source created');
}
```

#### Update Payment Source

```typescript
const updateResult = await Lean.updatePaymentSource({
  customerId: 'customer-123',
  paymentSourceId: 'source-id',
  paymentDestinationId: 'new-destination-id',
  appToken: 'YOUR_APP_TOKEN',
  sandbox: true,
});

if (updateResult.status === 'SUCCESS') {
  console.log('Payment source updated');
}
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

> **Official Documentation:** [docs.leantech.me/docs/web](https://docs.leantech.me/docs/web)

Load the Lean script once (e.g. in `index.html`), choosing the correct region:

```html
<!-- KSA -->
<script src="https://cdn.leantech.me/link/loader/prod/sa/latest/lean-link-loader.min.js"></script>

<!-- UAE -->
<script src="https://cdn.leantech.me/link/loader/prod/ae/latest/lean-link-loader.min.js"></script>
```

Pass `appToken` (and optionally `accessToken`) in each flow method call.

### Android

> **Official Documentation:** [docs.leantech.me/docs/android](https://docs.leantech.me/docs/android)

The plugin declares the Lean Android SDK dependency, so no extra setup in your app is needed. Run `npx cap sync` and build. Pass `appToken` in flow methods.

### iOS

> **Official Documentation:** [docs.leantech.me/docs/ios](https://docs.leantech.me/docs/ios)

The plugin bundles the Lean iOS SDK (`LeanSDK.xcframework`) via its CocoaPods podspec, so you don't need to add the SDK separately in your app.

After `npm install` and `npx cap sync ios`, open the iOS project in Xcode and build.
Set `appToken` via `Lean.manager.setup(appToken, sandbox, version)` in app init, or pass it in flow methods.

## API

### `Lean.link(options)`

Links customer accounts for data permissions. Returns `Promise<LeanResult>`.

#### Options for link()

| Option                 | Type       | Required | Description                                                               |
| ---------------------- | ---------- | -------- | ------------------------------------------------------------------------- |
| `customerId`           | `string`   | Yes      | Your Lean customer identifier.                                            |
| `permissions`          | `string[]` | Yes      | `'identity'`, `'accounts'`, `'transactions'`, `'balance'`, `'payments'`.  |
| `bankIdentifier`       | `string`   | No       | Pre-select a bank (skip bank list).                                       |
| `sandbox`              | `boolean`  | No       | Use sandbox (default `true`).                                             |
| `country`              | `string`   | No       | Country code (default `'sa'`).                                            |
| `appToken`             | `string`   | No       | Lean app token (required on Web and Android).                             |
| `accessToken`          | `string`   | No       | Customer-scoped token for token exchange.                                 |
| `successRedirectUrl`   | `string`   | No       | Redirect URL on success.                                                  |
| `failRedirectUrl`      | `string`   | No       | Redirect URL on failure.                                                  |

### `Lean.connect(options)`

Connects a customer for combined data + payments journeys. Returns `Promise<LeanResult>`.

#### Options for connect()

Same as `Lean.link(options)`, plus:

| Option                 | Type     | Required | Description                                         |
| ---------------------- | -------- | -------- | --------------------------------------------------- |
| `paymentDestinationId` | `string` | No       | Payment destination (defaults to your CMA account). |

### `Lean.reconnect(options)`

Reconnects an existing entity. Returns `Promise<LeanResult>`.

#### Options for reconnect()

| Option               | Type      | Required | Description                               |
| -------------------- | --------- | -------- | ----------------------------------------- |
| `reconnectId`        | `string`  | Yes      | Reconnect identifier from your backend.   |
| `sandbox`            | `boolean` | No       | Use sandbox (default `true`).             |
| `country`            | `string`  | No       | Country code (default `'sa'`).            |
| `appToken`           | `string`  | No       | Lean app token (required on Web/Android). |
| `accessToken`        | `string`  | No       | Customer-scoped token for token exchange. |
| `successRedirectUrl` | `string`  | No       | Redirect URL on success.                  |
| `failRedirectUrl`    | `string`  | No       | Redirect URL on failure.                  |

### `Lean.createPaymentSource(options)`

Creates a payment source for a customer. Returns `Promise<LeanResult>`.

#### Options for createPaymentSource()

| Option                 | Type      | Required | Description                                         |
| ---------------------- | --------- | -------- | --------------------------------------------------- |
| `customerId`           | `string`  | Yes      | Your Lean customer identifier.                      |
| `bankIdentifier`       | `string`  | No       | Pre-select a bank (skip bank list).                 |
| `paymentDestinationId` | `string`  | No       | Payment destination (defaults to your CMA account). |
| `sandbox`              | `boolean` | No       | Use sandbox (default `true`).                       |
| `country`              | `string`  | No       | Country code (default `'sa'`).                      |
| `appToken`             | `string`  | No       | Lean app token (required on Web/Android).           |
| `accessToken`          | `string`  | No       | Customer-scoped token for token exchange.           |
| `successRedirectUrl`   | `string`  | No       | Redirect URL on success.                            |
| `failRedirectUrl`      | `string`  | No       | Redirect URL on failure.                            |

### `Lean.updatePaymentSource(options)`

Updates an existing payment source destination. Returns `Promise<LeanResult>`.

#### Options for updatePaymentSource()

| Option                 | Type      | Required | Description                               |
| ---------------------- | --------- | -------- | ----------------------------------------- |
| `customerId`           | `string`  | Yes      | Your Lean customer identifier.            |
| `paymentSourceId`      | `string`  | Yes      | Existing payment source ID.               |
| `paymentDestinationId` | `string`  | Yes      | New payment destination ID.               |
| `sandbox`              | `boolean` | No       | Use sandbox (default `true`).             |
| `country`              | `string`  | No       | Country code (default `'sa'`).            |
| `appToken`             | `string`  | No       | Lean app token (required on Web/Android). |
| `accessToken`          | `string`  | No       | Customer-scoped token for token exchange. |
| `successRedirectUrl`   | `string`  | No       | Redirect URL on success.                  |
| `failRedirectUrl`      | `string`  | No       | Redirect URL on failure.                  |

### `Lean.pay(options)`

Completes a payment intent. Returns `Promise<LeanResult>`.

#### Options for pay()

| Option               | Type      | Required | Description                               |
| -------------------- | --------- | -------- | ----------------------------------------- |
| `paymentIntentId`    | `string`  | Yes      | Payment intent identifier.                |
| `accountId`          | `string`  | No       | Account ID for pre-selection.             |
| `sandbox`            | `boolean` | No       | Use sandbox (default `true`).             |
| `country`            | `string`  | No       | Country code (default `'sa'`).            |
| `appToken`           | `string`  | No       | Lean app token (required on Web/Android). |
| `accessToken`        | `string`  | No       | Customer-scoped token for token exchange. |
| `successRedirectUrl` | `string`  | No       | Redirect URL on success.                  |
| `failRedirectUrl`    | `string`  | No       | Redirect URL on failure.                  |

#### Result

```ts
interface LeanResult {
  status: 'SUCCESS' | 'CANCELLED' | 'ERROR';
  message?: string | null;
  last_api_response?: string | null;
  exit_point?: string | null;
  secondary_status?: string | null;
  bank?: { bank_identifier?: string; is_supported?: boolean } | null;
}
```

## Deep linking and token exchange

### Deep Linking

Set `successRedirectUrl` and `failRedirectUrl` so Lean redirects back to your app after completing or cancelling the flow.

#### iOS Deep Link Setup

Add a custom URL scheme in your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>yourappscheme</string>
    </array>
  </dict>
</array>
```

Then use URLs like: `yourappscheme://lean/success` and `yourappscheme://lean/fail`

#### Android Deep Link Setup

Add an intent filter in your `AndroidManifest.xml`:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data
    android:scheme="yourappscheme"
    android:host="lean" />
</intent-filter>
```

#### Example Usage with Deep Links

```typescript
const result = await Lean.connect({
  customerId: 'customer-123',
  permissions: ['accounts', 'transactions'],
  appToken: 'YOUR_APP_TOKEN',
  successRedirectUrl: 'yourappscheme://lean/success',
  failRedirectUrl: 'yourappscheme://lean/fail',
  sandbox: true,
});
```

### Token Exchange

Issue a customer-scoped `accessToken` on your backend and pass it (with `appToken`) in flow methods. The plugin forwards these tokens to the Lean SDK for secure authentication.

```typescript
// Backend: Generate accessToken for the customer
// Frontend: Pass both tokens
const result = await Lean.connect({
  customerId: 'customer-123',
  permissions: ['accounts'],
  appToken: 'YOUR_APP_TOKEN',
  accessToken: 'CUSTOMER_ACCESS_TOKEN',
  sandbox: true,
});
```

## Troubleshooting

### Android: "Lean SDK not found"

This is usually a multi-module Gradle issue: the plugin module must be able to resolve the Lean SDK; the app module’s dependencies are not enough. In the host app:

1. **JitPack in `android/settings.gradle`** – Add `maven { url "https://jitpack.io" }` inside `dependencyResolutionManagement { repositories { ... } }` (Gradle 7+). Putting it only in `buildscript.repositories` is not enough.
2. **App module** – In `android/app/build.gradle` add `implementation "me.leantech:link-sdk-android:3.0.8"`.
3. **ProGuard** – If your app has `minifyEnabled true`, add keep rules for `me.leantech.link.android.**`, `me.leantech.lean.**`, `me.leantech.Lean.**`, and `-dontwarn me.leantech.**` in `app/proguard-rules.pro`. Recommended: Use the broader rule `-keep class me.leantech.** { *; }` to cover all SDK packages.
4. **Clean rebuild** – Run `npx cap sync android`, then `cd android && ./gradlew clean`, then rebuild in Android Studio.

See `HOST_APP_SETUP.md` for the full step-by-step and explanation.

### iOS: Build or Framework Issues

#### "Framework not found LeanSDK"

1. **Clean build folder** – In Xcode: Product → Clean Build Folder (Cmd+Shift+K)
2. **Reinstall pods** – Run:

   ```bash
   cd ios
   pod deintegrate
   pod install
   cd ..
   ```

3. **Check podspec** – Ensure `LeanIonicCapacitor.podspec` includes the framework
4. **Rebuild** – Run `npx cap sync ios` and rebuild in Xcode

#### "Module 'LeanSDK' not found"

- Ensure you're building for a real device or simulator (not generic iOS device)
- Check that the framework is properly embedded in the target's "Frameworks, Libraries, and Embedded Content" section in Xcode

#### CocoaPods Installation Issues

If `pod install` fails:

```bash
pod repo update
pod install --repo-update
```

### Web: Script Loading Issues

#### "Lean is not defined"

Ensure the Lean script is loaded before your app initializes. Add it to `index.html`:

```html
<!-- Before your app scripts -->
<script src="https://cdn.leantech.me/link/loader/prod/sa/latest/lean-link-loader.min.js"></script>
```

#### Wrong Region Script

Make sure you're loading the correct regional script:

- **KSA:** `https://cdn.leantech.me/link/loader/prod/sa/latest/lean-link-loader.min.js`
- **UAE:** `https://cdn.leantech.me/link/loader/prod/ae/latest/lean-link-loader.min.js`

#### Content Security Policy (CSP) Issues

If you have CSP enabled, add:

```html
<meta http-equiv="Content-Security-Policy" 
      content="script-src 'self' https://cdn.leantech.me; connect-src 'self' https://*.leantech.me;">
```

## Development

- **Verify (all platforms):** `npm run verify`
- **Check (plugin + example app):** `npm run check`
- **Web only:** `npm run check:web`
- **iOS only:** `npm run check:ios`
- **Web tests:** `npm run test:web`
- **Android tests:** `npm run test:android`

See [VERIFY.md](VERIFY.md) for detailed steps. Before release: run `npm run lint`, then see [PRODUCTION.md](PRODUCTION.md). [CHANGELOG.md](CHANGELOG.md) lists version history.

## Contributing

We welcome contributions! To contribute:

1. **Fork the repository** on GitHub
2. **Create a feature branch**: `git checkout -b feature/my-feature`
3. **Make your changes** and ensure all tests pass:

   ```bash
   npm run verify        # Test all platforms
   npm run lint          # Check code style
   npm run fmt           # Auto-format code
   ```

4. **Commit your changes**: `git commit -m "Add my feature"`
5. **Push to your fork**: `git push origin feature/my-feature`
6. **Open a Pull Request** with a clear description of your changes

### Development Setup

```bash
# Clone the repository
git clone https://github.com/imuhammadnadeem/LEAN-Ionic-Capacitor.git
cd LEAN-Ionic-Capacitor

# Install dependencies
npm install

# Build the plugin
npm run build

# Run tests
npm run verify
```

### Code Style

- Follow existing code conventions
- Run `npm run lint` before committing
- Use `npm run fmt` to auto-format code
- Write meaningful commit messages

## Support

### Getting Help

- **Documentation**: [Lean Technologies Docs](https://docs.leantech.me/)
- **Issues**: [GitHub Issues](https://github.com/imuhammadnadeem/LEAN-Ionic-Capacitor/issues)
- **Email**: For general inquiries about Lean Technologies

### Reporting Bugs

When reporting bugs, please include:

1. Plugin version (`npm list lean-ionic-capacitor`)
2. Capacitor version (`npx cap --version`)
3. Platform (iOS/Android/Web)
4. Steps to reproduce
5. Expected vs actual behavior
6. Error messages or logs

### Feature Requests

Feature requests are welcome! Please open an issue with:

- Clear description of the feature
- Use case and benefits
- Any implementation suggestions

## License

MIT
