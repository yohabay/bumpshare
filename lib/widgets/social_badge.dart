import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/social_link.dart';
class SocialBadge extends StatelessWidget {
  const SocialBadge({
    super.key,
    required this.platform,
    this.size = 40,
    this.showBackground = true,
  });
  final SocialPlatform platform;
  final double size;
  final bool showBackground;
  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background = _background(colors);
    final Color foreground = showBackground ? _foreground : background;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: showBackground && _gradient == null ? background : null,
        gradient: showBackground ? _gradient : null,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: showBackground
            ? null
            : Border.all(color: colors.outlineVariant),
      ),
      alignment: Alignment.center,
      child: FaIcon(
        _icon,
        size: size * 0.5,
        color: foreground,
      ),
    );
  }
  FaIconData get _icon => switch (platform) {
        SocialPlatform.linkedin => FontAwesomeIcons.linkedinIn,
        SocialPlatform.instagram => FontAwesomeIcons.instagram,
        SocialPlatform.x => FontAwesomeIcons.xTwitter,
        SocialPlatform.facebook => FontAwesomeIcons.facebookF,
        SocialPlatform.github => FontAwesomeIcons.github,
        SocialPlatform.tiktok => FontAwesomeIcons.tiktok,
        SocialPlatform.youtube => FontAwesomeIcons.youtube,
        SocialPlatform.whatsapp => FontAwesomeIcons.whatsapp,
        SocialPlatform.telegram => FontAwesomeIcons.telegram,
        SocialPlatform.threads => FontAwesomeIcons.threads,
        SocialPlatform.snapchat => FontAwesomeIcons.snapchat,
        SocialPlatform.website => FontAwesomeIcons.globe,
      };
  Color _background(ColorScheme colors) => switch (platform) {
        SocialPlatform.linkedin => const Color(0xFF0A66C2),
        SocialPlatform.instagram => const Color(0xFFE1306C),
        SocialPlatform.x => const Color(0xFF111111),
        SocialPlatform.facebook => const Color(0xFF1877F2),
        SocialPlatform.github => const Color(0xFF181717),
        SocialPlatform.tiktok => const Color(0xFF111111),
        SocialPlatform.youtube => const Color(0xFFFF0000),
        SocialPlatform.whatsapp => const Color(0xFF25D366),
        SocialPlatform.telegram => const Color(0xFF26A5E4),
        SocialPlatform.threads => const Color(0xFF111111),
        SocialPlatform.snapchat => const Color(0xFFFFFC00),
        SocialPlatform.website => colors.primary,
      };
  Color get _foreground => switch (platform) {
        SocialPlatform.snapchat => const Color(0xFF111111),
        SocialPlatform.whatsapp => Colors.white,
        _ => Colors.white,
      };
  Gradient? get _gradient => platform == SocialPlatform.instagram
      ? const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: <Color>[
            Color(0xFFF9CE34),
            Color(0xFFEE2A7B),
            Color(0xFF6228D7),
          ],
        )
      : null;
}
