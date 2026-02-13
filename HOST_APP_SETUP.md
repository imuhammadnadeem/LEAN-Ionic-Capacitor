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

The plugin declares the Lean Android SDK in its own `build.gradle`, but the **host app** must make the SDK resolvable for all modules (Gradle 7+ uses a single resolution context). Follow the steps below so both the app module and the plugin module can resolve `me.leantech:link-sdk-android`.

From your **app** root run `npx cap sync android`, then open the Android project in Android Studio and build/run.

### 2.1 Why "Lean SDK not found" happens

Capacitor uses a multi-module Gradle setup. The plugin module (`:lean-ionic-capacitor`) does **not** inherit the app module’s dependencies. The plugin needs the Lean SDK at **compile time** in its own module. If JitPack (or the Lean SDK) is only added in `app/build.gradle` or in `buildscript.repositories`, the plugin module may not see it. The fix is to add the repository and dependency in the places below so **both** the app and the plugin can resolve the SDK.

### 2.2 Required host app setup

#### Step 1: AndroidManifest.xml

Add the following to your **`android/app/src/main/AndroidManifest.xml`**:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

  <!-- Required: Internet permission for Lean SDK -->
  <uses-permission android:name="android.permission.INTERNET" />

  <application>
    <activity android:name=".MainActivity">
      <!-- ... existing configuration ... -->

      <!-- Add this intent filter for deep linking -->
      <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
          android:scheme="yourappscheme"
          android:host="lean" />
      </intent-filter>
    </activity>
  </application>
</manifest>
```

**Important:**

- Replace `yourappscheme` with your app's custom URL scheme (e.g., `myapp`, `companyapp`)
- The `INTERNET` permission is required for Lean SDK to make network calls
- The intent filter enables deep linking back to your app after Lean flows

#### Step 2: JitPack in global repositories (Gradle 7+)

In the host app’s **`android/settings.gradle`**, ensure `dependencyResolutionManagement` includes JitPack. Putting it only in `buildscript.repositories` is not enough.

```groovy
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url "https://jitpack.io" }
    }
}
```

#### Step 3: Lean SDK in the app module

In **`android/app/build.gradle`**, inside `dependencies { }`:

```groovy
dependencies {
    implementation "me.leantech:link-sdk-android:3.0.8"
    // ... other dependencies
}
```

#### Step 4: Plugin module

The plugin already declares `implementation "me.leantech:link-sdk-android:3.0.8"` in its own `android/build.gradle`. No change needed in the plugin; Step 2 ensures the plugin module can resolve it when the host app builds.

#### Step 5: ProGuard (release builds with `minifyEnabled true`)

In **`android/app/proguard-rules.pro`** add:

```proguard
# Lean SDK
-keep class me.leantech.** { *; }
-dontwarn me.leantech.**
```

**Note:** The broader rule `-keep class me.leantech.** { *; }` covers all current and future Lean SDK packages.

### 2.3 After changing Gradle files

```bash
npx cap sync android
cd android
./gradlew clean
```

Then open the project in Android Studio and do **Build → Clean Project**, then **Build → Rebuild Project**.

---

## 3. iOS setup (host app)

All changes below are in your **Xcode app project**, not in the plugin.

### 3.1 Lean iOS SDK

The plugin bundles the Lean iOS SDK (`LeanSDK.xcframework`) via its CocoaPods podspec, so you don't need to add the SDK separately (no extra Swift Package Manager step in your app).

Current bundled Lean iOS SDK line: `3.0.19` (build `32`).

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

### 3.4 Configure deep linking (Info.plist)

For deep linking support, add a custom URL scheme to your **`ios/App/App/Info.plist`**:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>yourappscheme</string>
    </array>
    <key>CFBundleURLName</key>
    <string>com.yourcompany.yourapp</string>
  </dict>
</array>
```

**Important:**

- Replace `yourappscheme` with your app's custom URL scheme (e.g., `myapp`, `companyapp`)
- Update `CFBundleURLName` with your app's bundle identifier (e.g., `com.yourcompany.yourapp`)

**Optional - Query other schemes:**

If your app needs to query other schemes (e.g., to check if Lean SDK can open certain URLs), add:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>leantech</string>
</array>
```

### 3.5 Deep linking usage example

After configuring the URL scheme, use it in your plugin calls:

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

---

## 4. Using the plugin

In your web/JS code (Ionic/Capacitor app):

```ts
import { Lean } from 'lean-ionic-capacitor';

const result = await Lean.connect({
  customerId: 'YOUR_CUSTOMER_ID',
  permissions: ['accounts', 'transactions'],
  sandbox: true,
  country: 'sa', // optional: 'sa', 'ae' (defaults to 'sa')
  appToken: 'YOUR_APP_TOKEN', // required on Web; recommended on native
});
```

See `README.md` for full option details and additional notes on deep linking and token exchange.
