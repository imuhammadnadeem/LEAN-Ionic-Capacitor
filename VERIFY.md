# How to verify the plugin

Run these from the **project root**.

## Quick reference

| Goal              | Command                                                                        |
| ----------------- | ------------------------------------------------------------------------------ |
| All platforms     | `npm run verify` (plugin build only) or `npm run check` (plugin + example app) |
| Web only          | `npm run verify:web` or `npm run check:web`                                    |
| Android only      | `npm run verify:android` or `npm run check:android`                            |
| iOS only          | `npm run check:ios` or `npm run check:ios:simulator`                           |

- **verify** – Build the plugin (no example app).
- **check** – Build the plugin and the example app (full run).

---

## Web

### Plugin build

```bash
npm run build
```

Compiles `src/` to `dist/` (including `src/web.ts`). If this passes, the Web plugin and types are valid.

### Example app (dev server)

```bash
npm run build
cd example-app
npm install
npm run start
```

Open the URL (e.g. `http://localhost:5173`). The example calls `Lean.connect()` from `example.js`. Without real credentials you may see an error or incomplete Lean UI; the check is that the plugin loads and `Lean.connect()` runs without "Lean is not defined". With credentials in `example-app/src/js/example.js` you can test the full Web flow.

### Example app (production build)

```bash
npm run check:web
```

Builds the plugin and then the example app (install + build). Use this to confirm production bundling.

---

## Android

```bash
npm run verify:android
```

or:

```bash
cd android && ./gradlew clean build test && cd ..
```

- Builds the plugin (no Lean SDK at compile time; uses reflection to call SDK at runtime).
- Requires Java and Android SDK.
- **In a host app:** If you see "Lean SDK not found", see `README.md` and `HOST_APP_SETUP.md` for troubleshooting (JitPack in `settings.gradle` with `dependencyResolutionManagement`, Lean SDK in `app/build.gradle`, ProGuard rules for release).

---

## iOS

Capacitor targets iOS only; `swift build` targets macOS. Use **xcodebuild** (or Xcode) for iOS.

### Command line (device)

```bash
npm run check:ios
```

or:

```bash
xcodebuild -scheme LeanIonicCapacitor -destination 'generic/platform=iOS' -configuration Debug build
```

Builds the Swift package for a generic iOS device (SPM: Capacitor, LeanSDK). If the scheme is missing, open the package in Xcode once (`open Package.swift`), then run again. List schemes: `xcodebuild -list` (scheme is **LeanIonicCapacitor**).

### Command line (simulator)

```bash
npm run check:ios:simulator
```

or:

```bash
xcodebuild -scheme LeanIonicCapacitor -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Debug build
```

Use a simulator you have (e.g. `iPhone 15`). List devices: `xcrun simctl list devices available`.

### Xcode (GUI)

1. Open **Package.swift** in Xcode.
2. Select scheme **LeanIonicCapacitor** and an iOS simulator or “Any iOS Device”.
3. **Cmd+B** to build. **Cmd+U** to run tests.

### Run iOS tests from CLI

```bash
xcodebuild -scheme LeanIonicCapacitor -destination 'platform=iOS Simulator,name=iPhone 16' test
```
