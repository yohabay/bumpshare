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
| GitHub Pages | workflow stages `web_profile/index.html` → `p/index.html`, then custom domain `bumpshare.app` → page live at `https://bumpshare.app/p/` | 2 min |
| Cloudflare Pages | connect repo, set output dir to repo root (the workflow's staging aside, you can also just commit a `p/index.html`) | 5 min |
| Netlify | connect repo, set publish directory to repo root | 3 min |
| Vercel | connect repo, set output dir to repo root | 3 min |

### GitHub Pages (one-click via workflow)

This repo already has `.github/workflows/deploy-pages.yml`. Push to `main` and
GitHub Pages deploys the staged page automatically.

1. Repo → **Settings → Pages → Source: GitHub Actions**.
2. Add a **Custom domain** `bumpshare.app` (DNS must point at GitHub Pages).
3. After the first run, the page is live at
   `https://bumpshare.app/p/`.
4. Set `kProfileBaseUrl` in `lib/app_config.dart` to that base URL **ending in `/`**
   (e.g. `https://bumpshare.app/p/`) and rebuild the app.

### Manual upload (any host)

1. Publish `web_profile/index.html` as the index of the path in
   `kProfileBaseUrl` (`lib/app_config.dart`). Default:
   `https://bumpshare.app/p/` → the file must end up at `/p/index.html`.
2. Any static host works: Netlify, Vercel, Cloudflare Pages, GitHub Pages or
   Firebase Hosting. (The GitHub Actions workflow already stages it into `p/`.)
3. If your URL differs, change `kProfileBaseUrl` to the full directory URL
   **ending in `/`** and rebuild the app.

## How the payload travels

The app shares links like:

```
https://bumpshare.app/p/#<base64url-json>
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
