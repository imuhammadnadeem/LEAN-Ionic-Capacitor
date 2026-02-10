# Changelog

<!-- markdownlint-disable MD024 -->

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-02-09

### Changed

- Android: Added `me.leantech.link.android.Lean` as primary class name in reflection lookup to support SDK v3.x package structure (tries `me.leantech.link.android.Lean`, then `me.leantech.lean.Lean`, then `me.leantech.Lean` for backward compatibility).
- Android: Improved error handling with `InvocationTargetException` wrapping for better error messages when Lean SDK calls fail.
- Android: Enhanced `connect()` method with defensive argument passing to support different SDK signature variations and properly pass `accessToken` for customer-scoped authentication.
- Android: Updated error message to explicitly mention `me.leantech.link.android.**` in ProGuard rules.
- Docs: Comprehensive Android "Lean SDK not found" troubleshooting with root cause explanation (Capacitor multi-module Gradle setup; plugin module needs SDK at compile time; JitPack must be in global repos). Updated `HOST_APP_SETUP.md`, `README.md`, and `VERIFY.md` with step-by-step setup: JitPack in `settings.gradle` (`dependencyResolutionManagement` with `PREFER_PROJECT` mode), Lean SDK in `app/build.gradle`, ProGuard rules prioritizing `me.leantech.link.android.**` package.

## [1.0.2] - 2026-02-09

### Changed

- iOS: Bundle `LeanSDK.xcframework` via CocoaPods `vendored_frameworks` so host apps don't have to add the SDK manually.
- Docs: Clarified Capacitor **8+** requirement and updated iOS setup/production docs to describe the new integration.

## [1.0.1] - 2026-02-09

### Added

- GitHub Actions CI workflow for lint and web verification.
- `HOST_APP_SETUP.md` with detailed host app setup for Android and iOS.
- `PRODUCTION.md` production readiness checklist.

### Changed

- Improved npm `keywords` for better discoverability.
- Updated SwiftLint script to lint only project Swift files.
- Updated Rollup configuration to work reliably on Linux CI by explicitly adding the native binary as an optional dependency.

## [1.0.0] - 2025-02-09

### Added – initial release

- Capacitor plugin for **Lean Technologies Link**: one API for Web, Android, and iOS.
- `Lean.connect(options)` with typed `LeanConnectOptions` and `LeanConnectResult`.
- **Web:** Lean Link Web SDK integration; `customerId`/`permissions` validation; support for `appToken`, `accessToken`, redirect URLs, `bankIdentifier`.
- **Android:** Reflection-based bridge to Lean SDK; host app adds `me.leantech:link-sdk-android:3.0.8`; ProGuard keep rules for SDK types.
- **iOS:** LeanSDK via Swift Package Manager; setup via `appToken` in options or app init; consistent result shape across platforms.
- Deep linking and token exchange support (Open Finance flows).
- Sandbox and production support via `sandbox` option.

### Documentation

- README: install, usage, platform setup, API, troubleshooting.
- VERIFY.md: how to verify Web, Android, and iOS.
- PRODUCTION.md: pre-release checklist.

[1.0.3]: https://github.com/imuhammadnadeem/LEAN-Ionic-Capacitor/releases/tag/v1.0.3
[1.0.2]: https://github.com/imuhammadnadeem/LEAN-Ionic-Capacitor/releases/tag/v1.0.2
[1.0.1]: https://github.com/imuhammadnadeem/LEAN-Ionic-Capacitor/releases/tag/v1.0.1
[1.0.0]: https://github.com/imuhammadnadeem/LEAN-Ionic-Capacitor/releases/tag/v1.0.0
