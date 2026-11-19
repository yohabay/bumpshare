# BumpShare — Limitations and release checklist

## Hardware / platform

| Limitation | Detail |
|---|---|
| NFC range | ~4 cm; phones must be held back-to-back, still for ~1 s |
| HCE support | The sender needs `FEATURE_NFC_HOST_CARD_EMULATION`. Many budget NFC phones can read but not emulate, so they cannot send. The app detects this and explains it. |
| Screen state | Sender must stay unlocked and awake (`requireDeviceUnlock`/`requireDeviceScreenOn` in `apduservice.xml`). |
| Cases / interference | Metal cases, wallets and magnets can block the field. |
| Receiver internet | The shared link is a hosted static page, so the receiver needs data/Wi-Fi to load it. The QR fallback works offline. |

## OS behaviour

- **Android 16+ (API 36+)** may dispatch web-bearing NFC tags as `ACTION_VIEW`
  with a user confirmation; this is fine for a URI record.
- **iPhone background reading** requires XS+ and a notification tap; see
  `docs/IPHONE_COMPATIBILITY.md`.
- Android has no reliable stock handler for `text/vcard` NFC tags — this is why
  the sender emits a URI record instead of a vCard.

## Product / security

- No profile backend: everything is encoded in the URL fragment and stored
  locally on the sender's device.
- No authentication or encryption beyond HTTPS: anyone who reads the tag in
  range gets the link. Keep that in mind before adding sensitive fields.
- The page URL contains the profile data; it can appear in browser history.

## Before publishing to Google Play

- [x] Application ID set to `com.robatech.app` (`android/app/build.gradle.kts`).
      **Permanent** — the same ID + upload key must sign every future update.
- [x] Release signing config with an upload keystore
      (`android/app/bumpshare-upload.jks`, credentials in `android/key.properties`,
      both git-ignored). Back these up; they cannot be regenerated.
- [x] Branded adaptive launcher icons in every density
      (`android/app/src/main/res/mipmap-*`).
- [x] Deploy `web_profile/index.html` at `https://bumbshare.vercel.app/` and set
      `kProfileBaseUrl` in `lib/app_config.dart` to that live URL.
- [ ] Build the signed `.aab` for Play upload
      (`flutter build appbundle --release`).
- [ ] Privacy policy + accurate Data Safety declaration (the app sends no data
      to BumpShare servers; the profile is shared peer-to-peer over NFC).
- [ ] Real-device validation: stock Android receiver and iPhone receiver using
      `docs/TESTING.md`.
- [ ] Store screenshots / description that state the receiver needs no app.
      Rendered screens are in `screenshots/` (`flutter test tools/render_screens_test.dart`).
