# Mobile build & release setup

This project builds three targets from one Flutter codebase:

| Target | Where it builds | Output |
|---|---|---|
| Web | GitHub Actions → Hostinger (already live at nayasantha.com) | static site |
| Android | Locally on Windows, or Codemagic | `.aab` / `.apk` |
| iOS | Codemagic (cloud Mac — can't build on Windows) | `.ipa` |

---

## 🔑 CRITICAL: back up the Android signing key

Play Store apps are tied to their **upload key forever**. If you lose it you can
never push an update. It is **git-ignored on purpose** (not in the repo).

Back these up somewhere safe (password manager + offline copy):

- **Keystore file:** `android/app/upload-keystore.jks`
- **Passwords / alias:** in `android/key.properties`
  - `keyAlias = upload`
  - store & key password: *(the 28-char password generated during setup)*

> Copy `upload-keystore.jks` out of this machine today. Losing it = losing the app.

---

## Android → Google Play

You already have a Play Console account. First release must be uploaded by hand;
after that Codemagic can automate it.

1. **Play Console → Create app** → name "NayaSantha", package
   `com.nayasantha.naya_santha`.
2. **Upload the first build manually:** `build/app/outputs/bundle/release/app-release.aab`
   to an **Internal testing** release. (Already built and signed.)
3. Complete the required forms (privacy policy URL, content rating, data safety,
   store listing — icon/screenshots/description).
4. **For CI auto-publish (optional):** create a Google Cloud **service account**
   with Play access, download its JSON key, and in Codemagic add it as a secure
   variable `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` in a group named `google_play`.

To rebuild the AAB locally any time:
```
flutter build appbundle --release
```

---

## iOS → App Store (via Codemagic)

1. **App Store Connect → My Apps → +** → new app, bundle ID
   `com.nayasantha.nayaSantha` (register the ID under Certificates, Identifiers &
   Profiles first if it isn't there).
2. **App Store Connect API key:** Users and Access → Integrations → App Store
   Connect API → generate a key (Admin/App Manager). Download the `.p8`, note the
   Key ID and Issuer ID.

---

## Codemagic (one-time)

1. Sign up / log in at codemagic.io, **connect this GitHub repo**. It auto-detects
   `codemagic.yaml`.
2. **Android signing:** Teams/App settings → Code signing identities → Android
   keystores → upload `upload-keystore.jks`, enter the alias (`upload`) and
   passwords, and name the reference **exactly** `nayasantha_keystore`
   (matches `codemagic.yaml`).
3. **iOS signing:** add an **App Store Connect API key** integration named
   **exactly** `nayasantha_asc` using the `.p8` / Key ID / Issuer ID from above.
   Codemagic will auto-create the signing certs and provisioning profiles.
4. **Google Play (optional auto-publish):** add the `google_play` variable group
   with `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` as above.
5. Push to `main` (or hit **Start new build**) → pick `android-release` /
   `ios-release`.

### What the workflows do
- **android-release** → builds a signed `.aab`, emails it, and (if the service
  account is set) uploads a **draft** to the Play *internal* track.
- **ios-release** → builds a signed `.ipa` and ships it to **TestFlight**. Flip
  `submit_to_app_store: true` in `codemagic.yaml` when you're ready for review.

Build numbers auto-increment via `$PROJECT_BUILD_NUMBER`. Bump the human-facing
version (`version:` in `pubspec.yaml`, e.g. `0.1.0+1` → `0.2.0+1`) for each
public release.
