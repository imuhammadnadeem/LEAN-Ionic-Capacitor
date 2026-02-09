# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-02-09

### Added

- Capacitor plugin for **Lean Technologies Link**: one API for Web, Android, and iOS.
- `Lean.connect(options)` with typed `LeanConnectOptions` and `LeanConnectResult`.
- **Web:** Lean Link Web SDK integration; `customerId`/`permissions` validation; support for `appToken`, `accessToken`, redirect URLs, `bankIdentifier`.
- **Android:** Reflection-based bridge to Lean SDK; host app adds `me.leantech:link-sdk-android:3.0.2`; ProGuard keep rules for SDK types.
- **iOS:** LeanSDK via Swift Package Manager; setup via `appToken` in options or app init; consistent result shape across platforms.
- Deep linking and token exchange support (Open Finance flows).
- Sandbox and production support via `sandbox` option.

### Documentation

- README: install, usage, platform setup, API, troubleshooting.
- VERIFY.md: how to verify Web, Android, and iOS.
- PRODUCTION.md: pre-release checklist.

[1.0.0]: https://github.com/imuhammadnadeem/LEAN-Ionic-Capaciotr/releases/tag/v1.0.0
