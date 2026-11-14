# Android Release Signing

Release builds are signed with the **upload keystore** described by
`android/key.properties`. Both the keystore and `key.properties` are
git-ignored; never commit them.

| Build | Without `key.properties` | With `key.properties` |
|---|---|---|
| `flutter run --release`, dev/local release builds | Debug keys (local testing only) | Upload key |
| `flutter build appbundle --flavor prod` | **Fails on purpose** | Upload key |

## 1. Create the upload keystore (once)

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Back it up in a password manager. If it is lost, an upload key reset through
Play Console is required (assuming Play App Signing is enabled).

## 2. Configure local builds

```bash
cp android/key.properties.example android/key.properties
```

Fill in the passwords. `storeFile` is relative to `android/app/`.

## 3. Configure CI (GitHub Actions)

Add these repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 android/app/upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | store password |
| `ANDROID_KEY_PASSWORD` | key password |
| `ANDROID_KEY_ALIAS` | key alias (e.g. `upload`) |

With the secrets set, CI builds a signed prod `.aab` on every push to `main`
and attaches it as a workflow artifact. Without them it builds a dev APK
only, to prove the Android build still compiles.
