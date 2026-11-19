# iPhone as a receiver

iPhone does not need the BumpShare app. The sender emits a standard NDEF URI
record, which iPhone's NFC stack reads like any NFC tag.

## Expected flow

1. Android sender is armed, unlocked with screen on.
2. iPhone (XS or newer, NFC enabled, unlocked at least once since restart) is
   held near the sender.
3. iOS detects the NDEF URI and shows its NFC notification/banner.
4. The user taps the notification; Safari opens `https://bumbshare.vercel.app/`.
5. The static page renders the contact and offers **Save contact**.

## Conditions / caveats

- Background tag reading is unavailable during Apple Pay, camera use, an active
  foreground NFC session, or Airplane mode.
- iPhones older than XS need Control Center NFC (or will not read background
  tags).
- Universal Links are not used: the link opens in Safari. If you later want the
  page to open an installed iOS app, add an `apple-app-site-association` file.
- iPhone cannot be a BumpShare sender: Apple does not expose Host Card Emulation
  to third-party apps.

## Validation status

This behaviour is consistent with Apple's Core NFC documentation and the
previously studied Android-HCE → iPhone reports, but it **has not yet been
re-validated with the final BumpShare build on real hardware**. See
`docs/TESTING.md`.
