/// Configuration for the hosted BumpShare profile page.
///
/// The sender shares a self-contained HTTPS link over NFC. The page decodes the
/// profile from the URL fragment, so no backend, account or database is needed.
/// Change this one value to your own deployment before publishing.
const String kProfileBaseUrl = 'https://bumbshare.vercel.app/';
