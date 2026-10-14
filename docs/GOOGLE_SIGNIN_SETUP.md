# Sahyān — Google Sign-In Configuration Guide (Android & Web)

This guide documents the exact configuration steps required to enable native **Google Sign-In** for the Sahyān mobile application on Android and Web platforms.

---

## 1. Prerequisites
- Google Cloud / Firebase Console access for the Sahyān project.
- Android debug and release keystores.

---

## 2. Step-by-Step Android Setup

### Step 2.1: Extract the SHA-1 Fingerprint of your Keystore
Run the Gradle `signingReport` task inside the `frontend/` directory to obtain your SHA-1 and SHA-256 fingerprints:

```bash
cd frontend/android
./gradlew signingReport
```

For Windows PowerShell:
```powershell
cd E:\Sahyān_MCA_APP\frontend\android
.\gradlew.bat signingReport
```

Look for the `debug` signing report in the output:
```text
Variant: debug
Config: debug
Store: C:\Users\<Username>\.android\debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA-256: YY:YY:YY:...
```

### Step 2.2: Register the Android App in Firebase Console
1. Open the [Firebase Console](https://console.firebase.google.com).
2. Select your Sahyān project.
3. Click **Project Settings** (gear icon) > **General**.
4. Under **Your apps**, click **Add app** > **Android**.
5. Set:
   - **Android package name:** `com.sahyan.sahyan`
   - **App nickname:** `Sahyān Android`
   - **Debug signing certificate SHA-1:** Paste the SHA-1 fingerprint extracted in Step 2.1.
6. Click **Register app**.

### Step 2.3: Download and Place `google-services.json`
1. Download the generated `google-services.json` file.
2. Place it in the directory:
   ```text
   frontend/android/app/google-services.json
   ```
3. Verify that `frontend/android/app/build.gradle.kts` applies the Google Services plugin:
   ```kotlin
   if (file("google-services.json").exists()) {
       apply(plugin = "com.google.gms.google-services")
   }
   ```

### Step 2.4: Enable Google Sign-In in Firebase Authentication
1. In Firebase Console, navigate to **Build** > **Authentication** > **Sign-in method**.
2. Click **Add new provider** > **Google**.
3. Toggle **Enable**.
4. Select the project support email and save.
5. Copy the **Web client ID** auto-generated under the Google provider settings.

---

## 3. Web & Environment Variable Setup (Optional)
If running on Flutter Web or custom builds:
```bash
flutter run --dart-define=FIREBASE_ANDROID_API_KEY=YOUR_KEY \
            --dart-define=FIREBASE_ANDROID_APP_ID=YOUR_APP_ID \
            --dart-define=FIREBASE_PROJECT_ID=sahyan-carpool
```

---

## 4. Automatic UI Behavior in Sahyān
- When Google Sign-In is **not configured** (i.e. `google-services.json` is missing or Firebase is uninitialized), Sahyān automatically conceals the Google Sign-In button and divider to prevent showing developer errors to passengers.
- As soon as `google-services.json` is placed in `frontend/android/app/` and Firebase initializes, the Google Sign-In button automatically appears in the Sign In interface.
