# BumpShare — NFC Protocol

The sender behaves like an NFC Forum **Type 4 tag** via Android Host Card
Emulation. It carries exactly **one NDEF URI record**: the shared profile link.
The receiver needs no BumpShare app; the stock OS handles the tag.

```
 Sender (Android, BumpShare)                 Receiver (stock Android / iPhone)
 ┌──────────────────────┐                   ┌───────────────────────────────┐
 │ Flutter UI            │  startSharing(uri)│ NFC stack (no app)            │
 │ MethodChannel         │ ─────────────────►│ reads NDEF URI                 │
 │ NdefHceService        │                   │ opens https://yohabay.github.io/bumpshare/p/… │
 │ Type4TagEmulator      │ ◄──── APDUs ──────│ browser / Safari notification  │
 └──────────────────────┘                   └───────────────────────────────┘
```

## 1. Tag / application parameters

| Item | Value |
|---|---|
| AID | `D2 76 00 00 85 01 01` (7 bytes) |
| AID category | `other` (non-payment) |
| CC file | `E1 03` |
| NDEF file | `E1 04` |
| UID | random per tap (readers must not depend on it) |

## 2. Reader exchange

All APDUs use `CLA = 0x00`.

### 2.1 SELECT AID

```
00 A4 04 00 07 D2 76 00 00 85 01 01
```

Response `90 00`.

### 2.2 SELECT NDEF file

```
00 A4 00 00 02 E1 04
```

Response `90 00`.

### 2.3 READ BINARY

```
00 B0 P1 P2 Le
```

The NDEF file content is `[NLEN: 2 bytes big-endian][NDEF message]`.

`Le` is treated as a maximum (ISO 7816-4): the emulator clamps the response to
the bytes available and returns `90 00`, so OS readers that request `0x80`,
`0x00` or the full record length still receive valid data. Readers may issue
multiple bounded reads; the emulator serves any offset.

| SW | Meaning |
|---|---|
| `9000` | OK |
| `6A81` | Function not supported |
| `6A82` | File not found |
| `6700` | Wrong length |
| `6986` | Command not allowed |

## 3. Capability container (file E1 03)

```
00 0F   CCLEN = 15
10      mapping version 1.0
00 3B   MLe = 59  (max read response)
00 34   MLc = 52
04 06   NDEF File Control TLV
E1 04   NDEF file id
FF FE   max NDEF size
00      read access: free
FF      write access: none
```

## 4. NDEF record

The message is a single **TNF = Well Known (0x01)** record, type `U` (RTD URI):

- Header `0xD1` for the short form (`MB=1, ME=1, SR=1, TNF=001`), `0xC1` for the
  long form.
- Payload: one prefix byte + UTF-8 suffix. `https://` uses prefix `0x04`.
- The URI is `https://yohabay.github.io/bumpshare/p/#<base64url-json>`.

The fragment encodes `{n: name, p: phone, e: email, l: [links]}`. Fragments are
never sent to a server; the static page at `web_profile/index.html` decodes it
locally. This is what lets a stock receiver show and save the contact without a
BumpShare app or a backend.

## 5. Sender state

1. Flutter calls `startSharing(uri)`.
2. `MainActivity` verifies NFC is enabled and HCE is supported, then calls
   `CardEmulation.setPreferredService`.
3. `NdefHceService.currentUri` is set; the emulator serves it on the next read.
4. The first NDEF body read fires `onSharingComplete` so the UI can show success.
5. `stopSharing()` unsets the preferred service and clears the URI. It is called
   on tap completion, on the Cancel button and on screen disposal.

Out of scope: receiving in-app (removed — receivers use their OS), peer-to-peer
NFC, multi-record messages, payments.
