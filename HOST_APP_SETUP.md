# Host app setup (Android & iOS)

Step‑by‑step instructions for using `lean-ionic-capacitor` in your own app.

---

## 1. Install the plugin in your Capacitor app

From your **app** project (not the plugin repo):

```bash
npm install lean-ionic-capacitor
npx cap sync
```

---

## 2. Android setup (host app)

All changes below are in **your Android app**, not in the plugin.

### 2.1 Add JitPack repository

Depending on your Gradle setup:

- **Gradle 7+/settings.gradle** (Kotlin DSL or Groovy):
  - Find `dependencyResolutionManagement { repositories { ... } }` and add:

    ```gradle
    maven { url 'https://jitpack.io' }
    ```

- **Older projects/project-level build.gradle**:
  - Under `allprojects { repositories { ... } }`, add:

    ```gradle
    maven { url 'https://jitpack.io' }
    ```

### 2.2 Add Lean SDK dependency

In your app module `build.gradle` (usually `app/build.gradle`), inside `dependencies { ... }`:

```gradle
implementation "me.leantech:link-sdk-android:3.0.2"
```

### 2.3 Sync Capacitor and rebuild

From your **app** root:

```bash
npx cap sync android
```

Then open the Android project in Android Studio and build/run as usual.

> Note: The plugin loads Lean SDK via reflection. The **plugin** does not bundle the SDK; your app must provide it via the dependency above.

---

## 3. iOS setup (host app)

All changes below are in your **Xcode app project**, not in the plugin.

### 3.1 Add Lean iOS SDK via Swift Package Manager

1. Open your app in Xcode.
2. Go to **File → Add Package Dependencies…**.
3. Enter the URL:

   ```text
   https://github.com/leantechnologies/link-sdk-ios-distribution
   ```

4. Choose a version rule (e.g. “Up to Next Major”).
5. Add the package to your **app target**.

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
