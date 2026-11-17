/// Detects which social platform a pasted link belongs to.
///
/// The whole feature is driven by the URL: type `linkedin.com/in/ada` and every
/// screen shows the LinkedIn mark, type an Instagram link and it shows the
/// Instagram mark, and so on. Unknown links fall back to [SocialPlatform.website].
enum SocialPlatform {
  linkedin,
  instagram,
  x,
  facebook,
  github,
  tiktok,
  youtube,
  whatsapp,
  telegram,
  threads,
  snapchat,
  website;

  /// Human readable name shown next to the mark.
  String get label => switch (this) {
        SocialPlatform.linkedin => 'LinkedIn',
        SocialPlatform.instagram => 'Instagram',
        SocialPlatform.x => 'X',
        SocialPlatform.facebook => 'Facebook',
        SocialPlatform.github => 'GitHub',
        SocialPlatform.tiktok => 'TikTok',
        SocialPlatform.youtube => 'YouTube',
        SocialPlatform.whatsapp => 'WhatsApp',
        SocialPlatform.telegram => 'Telegram',
        SocialPlatform.threads => 'Threads',
        SocialPlatform.snapchat => 'Snapchat',
        SocialPlatform.website => 'Website',
      };

  /// Example shown as the field hint for this platform.
  String get hint => switch (this) {
        SocialPlatform.linkedin => 'https://linkedin.com/in/you',
        SocialPlatform.instagram => 'https://instagram.com/you',
        SocialPlatform.x => 'https://x.com/you',
        SocialPlatform.facebook => 'https://facebook.com/you',
        SocialPlatform.github => 'https://github.com/you',
        SocialPlatform.tiktok => 'https://tiktok.com/@you',
        SocialPlatform.youtube => 'https://youtube.com/@you',
        SocialPlatform.whatsapp => 'https://wa.me/15550100',
        SocialPlatform.telegram => 'https://t.me/you',
        SocialPlatform.threads => 'https://threads.net/@you',
        SocialPlatform.snapchat => 'https://snapchat.com/add/you',
        SocialPlatform.website => 'https://yourwebsite.com',
      };
}

/// Domains owned by each platform. Matching is on the host (including
/// subdomains) so `notlinkedin.com` is not mistaken for LinkedIn.
const Map<String, SocialPlatform> _domains = <String, SocialPlatform>{
  'linkedin.com': SocialPlatform.linkedin,
  'lnkd.in': SocialPlatform.linkedin,
  'instagram.com': SocialPlatform.instagram,
  'instagr.am': SocialPlatform.instagram,
  'x.com': SocialPlatform.x,
  'twitter.com': SocialPlatform.x,
  't.co': SocialPlatform.x,
  'facebook.com': SocialPlatform.facebook,
  'fb.com': SocialPlatform.facebook,
  'fb.me': SocialPlatform.facebook,
  'github.com': SocialPlatform.github,
  'tiktok.com': SocialPlatform.tiktok,
  'youtube.com': SocialPlatform.youtube,
  'youtu.be': SocialPlatform.youtube,
  'whatsapp.com': SocialPlatform.whatsapp,
  'wa.me': SocialPlatform.whatsapp,
  't.me': SocialPlatform.telegram,
  'telegram.me': SocialPlatform.telegram,
  'telegram.org': SocialPlatform.telegram,
  'threads.net': SocialPlatform.threads,
  'threads.com': SocialPlatform.threads,
  'snapchat.com': SocialPlatform.snapchat,
};

final RegExp _hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://');

/// Turns user input into a parseable URI, tolerating a missing scheme.
Uri? parseSocialUri(String input) {
  final String value = input.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('//')) return Uri.tryParse('https:$value');
  if (_hasScheme.hasMatch(value)) return Uri.tryParse(value);
  return Uri.tryParse('https://$value');
}

String? _hostOf(String input) {
  final Uri? uri = parseSocialUri(input);
  final String? host = uri?.host.toLowerCase();
  if (host == null || host.isEmpty) return null;
  return host.startsWith('www.') ? host.substring(4) : host;
}

/// Platform that owns [input], or [SocialPlatform.website] when unknown.
SocialPlatform detectSocialPlatform(String input) {
  final String? host = _hostOf(input);
  if (host == null) return SocialPlatform.website;
  for (final MapEntry<String, SocialPlatform> entry in _domains.entries) {
    if (host == entry.key || host.endsWith('.${entry.key}')) {
      return entry.value;
    }
  }
  return SocialPlatform.website;
}

/// Short text for a link: `linkedin.com/in/ada` instead of the full URL.
///
/// Query strings and fragments are dropped because they are noise in a contact
/// card. Inputs that do not parse (for example `@ada`) are returned unchanged.
String socialDisplayText(String input) {
  final String value = input.trim();
  final Uri? uri = parseSocialUri(value);
  if (uri == null || uri.host.isEmpty || !_looksLikeHost(uri, value)) {
    return value;
  }
  String host = uri.host.toLowerCase();
  if (host.startsWith('www.')) host = host.substring(4);
  String path = uri.path;
  if (path.endsWith('/')) path = path.substring(0, path.length - 1);
  return '$host$path';
}

/// Absolute URL to open/save, adding `https://` when the user omitted it.
String socialHref(String input) {
  final String value = input.trim();
  final Uri? uri = parseSocialUri(value);
  if (uri == null || uri.host.isEmpty || !_looksLikeHost(uri, value)) {
    return value;
  }
  return uri.toString();
}

/// Rejects bare words and handles (`@ada`) that only look like a host after a
/// scheme was forced on them. An explicit scheme is always trusted.
bool _looksLikeHost(Uri uri, String input) =>
    _hasScheme.hasMatch(input) || uri.host.contains('.');
