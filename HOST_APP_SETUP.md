# Host app setup (Android & iOS)

Step‑by‑step instructions for using `lean-ionic-capacitor` in your own app.

---

## 1. Install the plugin in your Capacitor app

From your **app** project (not the plugin repo):

**From npm (recommended):**

```bash
npm install lean-ionic-capacitor
npx cap sync
```

---

## 2. Android setup (host app)

No extra setup required when using the plugin from **npm** and building debug. The plugin declares the Lean Android SDK dependency (and JitPack in its `build.gradle`), so the SDK is pulled in when you add the plugin. From your **app** root run `npx cap sync android`, then open the Android project in Android Studio and build/run.

If your app has **release minification** (`minifyEnabled true`), add the dependency, repositories, and ProGuard rules in the host app as in section 2.1 step 3.

### 2.1 Troubleshooting: "Lean SDK not found"

If you see this error in the host app:

1. **Sync from node_modules** – Ensure the plugin is installed and run `npm install` then `npx cap sync android`.
2. **Add in the host app explicitly** (required when using release build with `minifyEnabled true`):
   - **Repositories:** `maven { url 'https://jitpack.io' }` in the root `build.gradle` (or `settings.gradle`) and in `app/build.gradle`.
   - **Dependency:** In `app/build.gradle`, inside `dependencies { }`:  
     `implementation "me.leantech:link-sdk-android:3.0.8"`
   - **ProGuard:** In `app/proguard-rules.pro` (mandatory if your app has `minifyEnabled true`):  
     `-keep class me.leantech.lean.** { *; }`  
     `-keep class me.leantech.Lean.** { *; }`  
     `-dontwarn me.leantech.**`  
     If the error persists, add a broader keep: `-keep class me.leantech.** { *; }`
3. Run `npx cap sync android` and do a **clean rebuild** in Android Studio (Build → Clean Project, then Build → Rebuild Project).

---

## 3. iOS setup (host app)

All changes below are in your **Xcode app project**, not in the plugin.

### 3.1 Lean iOS SDK

The plugin bundles the Lean iOS SDK (`LeanSDK.xcframework`) via its CocoaPods podspec, so you don't need to add the SDK separately (no extra Swift Package Manager step in your app).

### 3.2 Ensure the Capacitor plugin is synced

From your **app** root:

```bash
npx cap sync ios
```

Then open the iOS project in Xcode and build.

### 3.3 Configure `appToken`

You can do either of the following:

- **Option A – Configure in app init**  
  In your app’s startup (e.g. `AppDelegate`), call:

  ```swift
  import LeanSDK

  // Example
  Lean.manager.setup(appToken: "YOUR_APP_TOKEN", sandbox: true, version: "latest")
  ```

- **Option B – Configure via plugin options**  
  Pass `appToken` in `Lean.connect()` options from your web/JS side. The plugin will call `Lean.manager.setup` for you if an `appToken` is provided.

---

## 4. Using the plugin

In your web/JS code (Ionic/Capacitor app):

```ts
import { Lean } from 'lean-ionic-capacitor';

const result = await Lean.connect({
  customerId: 'YOUR_CUSTOMER_ID',
  permissions: ['accounts', 'transactions'],
  sandbox: true,
  appToken: 'YOUR_APP_TOKEN', // required on Web; recommended on native
});
```

See `README.md` for full option details and additional notes on deep linking and token exchange.
