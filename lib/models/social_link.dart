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
String socialHref(String input) {
  final String value = input.trim();
  final Uri? uri = parseSocialUri(value);
  if (uri == null || uri.host.isEmpty || !_looksLikeHost(uri, value)) {
    return value;
  }
  return uri.toString();
}
bool _looksLikeHost(Uri uri, String input) =>
    _hasScheme.hasMatch(input) || uri.host.contains('.');
