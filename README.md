# BumpShare

Tap two phones together to share a contact card. **Only the sender installs the
app.** The receiver just needs NFC switched on: their phone opens the shared
profile and can save the contact without installing anything.

## How it works

1. The sender creates a profile (name, phone, email, links). It is stored only on
   the device.
2. **Share Contact Card** arms Android Host Card Emulation with a single NDEF URI
   record:
   `https://bumpshare.vercel.app/#<base64url profile>`.
3. The receiver taps. Stock Android opens the link in the browser; iPhone shows
   its standard NFC notification, which opens the same link.
4. The static page in `web_profile/` decodes the profile from the URL fragment
   and offers **Save contact**. No backend, account, database or receiver app.

A QR code containing the same profile as a vCard is available as an offline
fallback.

## Links with brand logos

Social links are driven entirely by the URL:

- The editor starts with **one** link field. **Add link (+)** appends another
  (up to 10), and each field can be removed again.
- The logo inside the field follows what you type — paste a LinkedIn link and
  the LinkedIn mark appears, Instagram the camera mark, X the X, and so on
  (LinkedIn, Instagram, X, Facebook, GitHub, TikTok, YouTube, WhatsApp,
  Telegram, Threads, Snapchat). Anything else gets a website globe.
- The same marks are shown on the home card, the profile screen, the shared
  business card and the receiver's web page.

Detection lives in `lib/models/social_link.dart` and the marks in
`lib/widgets/social_badge.dart`. The web page's copies are inlined by
`tools/fetch_brand_logos.ps1`.

## Project layout

```
lib/
  app_config.dart          Base URL of the hosted profile page
  models/profile.dart      Profile model, share link, vCard
  services/                NFC bridge + local profile storage
  screens/                 Home, sharing, success, profile, edit, business card
android/.../kotlin/...     HCE Type 4 tag emulator (sender only)
web_profile/index.html     Static receiver page (deploy this)
docs/                      Protocol, limitations, iPhone notes, testing
```

## Run

```bash
flutter pub get
flutter run
```

## Deploy the receiver page

See `web_profile/README.md`. In short: publish `web_profile/index.html` at the
path configured by `kProfileBaseUrl` in `lib/app_config.dart`, then rebuild.

## Build

```bash
flutter build apk --release      # signed APK, for device testing
flutter build appbundle --release  # signed .aab, only for Play upload
```

Release signing uses `android/key.properties` + `android/app/bumpshare-upload.jks`
(both git-ignored), with application ID `com.robatech.app`. Hosting
`web_profile/index.html` at `kProfileBaseUrl` is the one remaining release task
(see `docs/LIMITATIONS.md`).

## Status

- [x] Sender UI, profile editing, QR fallback, business card
- [x] Android HCE sender emitting a single NDEF URI record
- [x] Receiver needs no app (stock Android browser / iPhone notification)
- [x] Static profile page
- [x] Launcher icon (adaptive, all densities)
- [x] Release signing keystore + application ID `com.robatech.app`
- [ ] Deploy the profile page at `kProfileBaseUrl`
- [ ] Real-device validation on stock Android and iPhone (see `docs/TESTING.md`)

## Documentation

- `docs/NFC_PROTOCOL.md` — wire protocol and NDEF layout
- `docs/IPHONE_COMPATIBILITY.md` — iPhone receiver behaviour
- `docs/LIMITATIONS.md` — hardware/OS limits and release TODOs
- `docs/TESTING.md` — device test checklist
