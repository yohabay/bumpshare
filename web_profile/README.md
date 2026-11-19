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

## Growth loop

The receiver page links to `/get/` with a **Make your own BumpShare card**
call-to-action. That page is served by `web_profile/get/index.html`; update the
App Store link there when the iOS app is published.

## How the payload travels

The app shares links like:

```
https://bumbshare.vercel.app/#<base64url-json>
```

The page reads everything after `#`; the profile data itself is never sent to a
server (only anonymous Vercel Web Analytics page views / named events).

### Payload keys

The fragment decodes to a compact JSON object. All keys are optional except `n`:

| Key | Meaning |
|---|---|
| `n` | Display name (required to render a profile) |
| `p` | Phone number |
| `e` | Email address |
| `l` | Array of social / website URLs |
| `ph` | Profile photo: **raw base64 JPEG bytes only** (no `data:` prefix). Rendered as a circular avatar and written to the vCard as `PHOTO;ENCODING=b;TYPE=JPEG:`. |
| `t` | Job title, shown as `<t> at <c>` (vCard `TITLE`) |
| `c` | Company / organisation (vCard `ORG`) |
| `th` | Theme index `0` purple `#6d28d9`, `1` teal `#0f766e`, `2` rose `#be123c`, `3` indigo `#4338ca`. Missing / unknown values default to purple. |

Old links carrying only `n` / `p` / `e` / `l` still render and save unchanged.

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
   marks, plus **Save contact** (downloads a vCard) and **Copy**. Optional `t` /
   `c` are shown under the name, `ph` as a circular avatar, and `th` sets the
   accent colour. The vCard also contains `TITLE`, `ORG`, `PHOTO` and the public
   profile URL when those fields are present.

## Analytics

Both static pages include the official Vercel Web Analytics snippet
(`/_vercel/insights/script.js`). No other analytics or external scripts are
loaded. Custom events are fired through `window.va('event', ...)`.

> **Setup:** Web Analytics must be enabled for the Vercel project **before**
> deploying these pages. Otherwise `/_vercel/insights/script.js` returns 404.
> Enable it in the project's **Analytics** tab, then redeploy. Custom events
> require a Vercel plan that supports them; page views work on Hobby.

| Page | Event | When |
|---|---|---|
| Profile (`/`) | `profile_opened` | once, when a valid profile is rendered |
| Profile (`/`) | `save_contact` | Save contact link clicked |
| Profile (`/`) | `copy_details` | Copy contact details succeeded |
| Profile (`/`) | `get_app_clicked` | "Make your own BumpShare card" CTA clicked |
| Get app (`/get/`) | `get_app_view` | once on load |
| Get app (`/get/`) | `store_click` | a store link is clicked, with `data.store` = `google_play` or `app_store` |

> The receiver needs internet access to load this page. For an offline fallback,
> the app still offers a QR code containing a vCard.
