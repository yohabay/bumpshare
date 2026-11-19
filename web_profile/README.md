# Deployed BumpShare profile page

This single static file is what the receiver opens after tapping the sender's
phone. It decodes the profile from the URL fragment, so there is **no backend,
database or account** involved — and no app to install.

It also draws the brand mark for each shared link (LinkedIn, Instagram, X,
Facebook, GitHub, TikTok, YouTube, WhatsApp, Telegram, Threads, Snapchat) and a
globe for anything else.

## Deploy

Pick **one** of these free static hosts:

| Host | How the file lands at the right path | Time to set up |
|---|---|---|
| **Vercel** | deploy the folder that contains the page (`web_profile/`) | 3 min |
| Cloudflare Pages | direct upload / repo | 5 min |
| Netlify | drop / repo | 3 min |

### Vercel (recommended now)

The page is a single static file, so Vercel is a one-command deploy:

```bash
npx vercel deploy --prod
```

Run it from the directory that contains the page (for example `web_profile/`, or
a staging folder that holds `p/index.html` if you want the `/p/` path).

After the deploy finishes, set `kProfileBaseUrl` in `lib/app_config.dart` to the
resulting base URL **ending in `/`** (default now: `https://bumbshare.vercel.app/`)
and rebuild the app.

### Manual upload (any host)

1. Publish `web_profile/index.html` as the index of the path in
   `kProfileBaseUrl` (`lib/app_config.dart`). Default:
   `https://bumbshare.vercel.app/` → the file must end up at `/index.html`.
2. Any static host works: Vercel, Netlify, Cloudflare Pages, GitHub Pages or
   Firebase Hosting.
3. If your URL differs, change `kProfileBaseUrl` to the full directory URL
   **ending in `/`** and rebuild the app.

## How the payload travels

The app shares links like:

```
https://bumbshare.vercel.app/#<base64url-json>
```

The page reads everything after `#`; nothing is sent to a server.

The page is fully self-contained: the brand SVGs are inlined (from
[simple-icons](https://simpleicons.org), CC0) between the `/* LOGOS:START */`
and `/* LOGOS:END */` markers. Refresh them with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/fetch_brand_logos.ps1
```

## The receiver flow (no app)

1. Sender taps phone to phone → NFC tag carries the URI above.
2. Receiver's phone opens the link in the browser (stock Android handles URI
   records reliably; iPhone uses its standard NFC notification).
3. Page decodes the fragment and shows name / phone / email / links with brand
   marks, plus **Save contact** (downloads a vCard) and **Copy**.

> The receiver needs internet access to load this page. For an offline fallback,
> the app still offers a QR code containing a vCard.
