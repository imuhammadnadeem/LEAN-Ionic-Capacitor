# Production readiness

Short checklist before shipping or publishing.

## Pre-release

1. **Lint** – `npm run lint` (ESLint, Prettier, SwiftLint).
2. **Android** – From repo root: `cd android && ./gradlew assembleRelease`. The plugin declares the Lean SDK dependency; host apps need no extra setup. If a host app uses a local `file:` path for testing, ensure the path is correct (e.g. `LEAN-Ionic-Capacitor`, not `LEAN-Ionic-Capaciotr`); see `HOST_APP_SETUP.md` if they see "Lean SDK not found".
3. **iOS** – Run `npx cap sync ios` and make sure the project builds in Xcode with the bundled `LeanSDK.xcframework` from the plugin Podspec (no extra Lean SPM dependency needed in the host app).
4. **Version** – Set the version in `package.json` (e.g. `1.0.0` for stable) and update `CHANGELOG.md`.
5. **Secrets** – Never commit `appToken` or `accessToken`. Use env vars or your backend and pass them into `Lean.connect()` at runtime.

## Publish and tag

1. Run `npm run lint` and `npm run build`.
2. Publish to npm: `npm publish --access public`.
3. Tag the release in git:
   - `git tag v1.0.0`
   - `git push origin v1.0.0`

Use the version you actually published (e.g. `v1.0.1`, `v1.1.0`, etc.).
