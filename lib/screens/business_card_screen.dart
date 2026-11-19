import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../app_config.dart';
import '../models/profile.dart';
import '../models/social_link.dart';
import '../services/profile_store.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/social_badge.dart';

class BusinessCardScreen extends StatefulWidget {
  const BusinessCardScreen({super.key, this.profile});
  final Profile? profile;
  @override
  State<BusinessCardScreen> createState() => _BusinessCardScreenState();
}

class _BusinessCardScreenState extends State<BusinessCardScreen> {
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey<_FlipCardState> _flipKey = GlobalKey<_FlipCardState>();
  bool _sharing = false;
  Profile _profile = Profile.demo();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _profile = widget.profile!;
      _loaded = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final Profile p = await ProfileStore.load();
    if (mounted) setState(() { _profile = p; _loaded = true; });
  }

  Future<void> _shareAsImage() async {
    setState(() => _sharing = true);
    try {
      // Always export the business-card side, even if the profile face is up.
      final _FlipCardState? flip = _flipKey.currentState;
      if (flip != null && !flip.showingBack) {
        flip.flip();
        await Future<void>.delayed(const Duration(milliseconds: 650));
      }
      final RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/bumpshare_card.png');
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My contact card — shared via BumpShare',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Widget _frontFace(ThemeData theme, Profile profile, Color accent, String role) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Colors.white, Color(0xFFF5F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  profile: profile,
                  size: 62,
                  ringColor: accent,
                  ringWidth: 3,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.isEmpty ? 'Your name' : profile.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (role.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          role,
                          style: TextStyle(
                            color: accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'BUMP · TAP TO SHARE',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.flip_camera_android, size: 17, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  'Tap to see the business card',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _backFace(ThemeData theme, Profile profile, Color accent, String role) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[accent, accent.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileAvatar(
                            profile: profile,
                            size: 42,
                            ringColor: Colors.white,
                            ringWidth: 2,
                            backgroundColor: Colors.white.withValues(alpha: 0.22),
                            foregroundColor: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile.name.isEmpty ? 'Your name' : profile.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (role.isNotEmpty)
                            Text(
                              role,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profile.phone != null && profile.phone!.isNotEmpty)
                            _InfoLine(icon: Icons.phone, text: profile.phone!, color: Colors.white),
                          if (profile.email != null && profile.email!.isNotEmpty)
                            _InfoLine(icon: Icons.email, text: profile.email!, color: Colors.white),
                          if (profile.socialLinks.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: profile.socialLinks.take(4).map((String link) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SocialBadge(
                                      platform: detectSocialPlatform(link),
                                      size: 20,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: profile.toVCard(includePhoto: false),
                    version: QrVersions.auto,
                    size: 120,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 8,
            child: Icon(
              Icons.flip_camera_android,
              size: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final ThemeData theme = Theme.of(context);
    final Profile profile = _profile;
    final Color accent = accentColor(profile.themeIndex);
    final String title = profile.title?.trim() ?? '';
    final String company = profile.company?.trim() ?? '';
    final String role = title.isNotEmpty && company.isNotEmpty
        ? '$title at $company'
        : (title.isNotEmpty ? title : company);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business card'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              RepaintBoundary(
                key: _cardKey,
                child: AspectRatio(
                  aspectRatio: 1.6,
                  child: _FlipCard(
                    key: _flipKey,
                    front: _frontFace(theme, profile, accent, role),
                    back: _backFace(theme, profile, accent, role),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap the card to flip between your profile and business card.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _sharing ? null : _shareAsImage,
                  icon: _sharing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share),
                  label: Text(_sharing ? 'Sharing…' : 'Share as image'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-sided card with a 3D Y-axis flip, matching the hosted profile page.
class _FlipCard extends StatefulWidget {
  const _FlipCard({super.key, required this.front, required this.back});
  final Widget front;
  final Widget back;
  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  bool get showingBack => _controller.value > 0.5;

  void flip() {
    if (_controller.isAnimating) return;
    if (showingBack) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (BuildContext context, Widget? child) {
          final double angle = _animation.value * math.pi;
          final Widget face = showingBack
              ? Transform(
                  transform: Matrix4.rotationY(math.pi),
                  alignment: Alignment.center,
                  child: widget.back,
                )
              : widget.front;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: face,
          );
        },
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.withValues(alpha: 0.95),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
