# Device testing — BumpShare

There is no receiver app to install. Test the sender with an unmodified phone.

## Prerequisites

- Flutter 3.47 / Dart 3.13.5, Android Studio, JDK 17.
- Sender: Android phone with NFC **and** HCE support, NFC enabled, screen on and
  unlocked.
- Receiver: any NFC phone (stock Android or iPhone) with NFC enabled.

## Build & install

```bash
flutter pub get
flutter test                       # Dart unit + smoke tests
cd android && ./gradlew test       # Kotlin protocol tests
flutter build apk --debug
flutter run -d <device-id>
```

## Test checklist

### Sender

- [ ] A new profile can be saved and survives a restart.
- [ ] The link section starts with one field; **Add link** adds another and the
      remove button deletes it again (one field is always kept).
- [ ] Pasting `linkedin.com/in/you`, `instagram.com/you`, `x.com/you`,
      `github.com/you`, … shows the matching brand mark and label in the field.
- [ ] An unknown link shows a globe and is labelled **Social link**.
- [ ] Home card, profile screen and business card show the same brand marks.
- [ ] Profile preview, business card and QR dialog show the saved data.
- [ ] With NFC off, the home screen shows "NFC is turned off" and **Turn on**
      opens NFC settings.
- [ ] On a phone without HCE, the app explains that it cannot send.
- [ ] **Share Contact Card** starts sharing and the "Ready to share" screen
      appears.
- [ ] Back / Cancel disarms sharing (another tap no longer triggers success).
- [ ] A completed tap shows "Contact shared" and returns home on **Done**.

### Receiver — stock Android

- [ ] Phone with NFC enabled and **no BumpShare installed** receives the tap.
- [ ] Browser opens the `https://…/p/#…` link.
- [ ] Page shows the correct name, phone, email and links.
- [ ] Each link shows its platform mark and a short `domain/path` label.
- [ ] **Save contact** downloads/opens a vCard that can be imported.
- [ ] QR fallback works with NFC and data disabled on the receiver.

### Receiver — iPhone

- [ ] iPhone XS+ with NFC enabled receives the tap without the app.
- [ ] NFC notification appears; tapping it opens Safari.
- [ ] Page renders correctly and Save contact adds a contact.

## Troubleshooting

- No tap: keep phones back-to-back within ~4 cm, hold ~1 s, remove thick cases.
- Sender not working: screen must be on and unlocked; phone must support HCE.
- Logcat tags: `BumpShareMain`, `BumpShareHCE`.
- Page does not load: check `kProfileBaseUrl` and that the static site is live.
