import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/profile.dart';
import '../models/social_link.dart';
import '../services/bump_share_nfc.dart';
import '../services/profile_store.dart';
import '../widgets/bump_share_logo.dart';
import '../widgets/social_badge.dart';

enum NfcStatus { checking, ready, unavailable, disabled, unsupported }

/// Single entry point: edit your card, then tap to share it.
/// There is deliberately no "receive" screen — the other phone needs no app.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BumpShareNfcService _nfc = BumpShareNfcService.instance;
  Profile _profile = Profile.demo();
  NfcStatus _status = NfcStatus.checking;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkNfc();
  }

  Future<void> _loadProfile() async {
    final Profile profile = await ProfileStore.load();
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _checkNfc() async {
    if (!await _nfc.isNfcAvailable()) return _set(NfcStatus.unavailable);
    if (!await _nfc.isNfcEnabled()) return _set(NfcStatus.disabled);
    if (!await _nfc.isHceSupported()) return _set(NfcStatus.unsupported);
    _set(NfcStatus.ready);
  }

  void _set(NfcStatus status) {
    if (mounted) setState(() => _status = status);
  }

  Future<void> _startSharing() async {
    if (_status != NfcStatus.ready) {
      _message('Turn on NFC and use a phone that supports NFC sharing.');
      return;
    }
    final bool armed = await _nfc.startSharing(_profile.shareUrl);
    if (!mounted) return;
    if (!armed) {
      _message('Could not start NFC sharing on this phone.');
      return;
    }
    await Navigator.pushNamed(context, '/sharing');
    await _checkNfc();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Opens the sender's own share link in the system browser. This shows the
  /// receiver's side of the flow without needing an actual NFC tap — handy for
  /// testing the hosted profile page before publishing.
  Future<void> _openSharePagePreview() async {
    final String url = _profile.shareUrl;
    final bool opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      _message('Could not open the shared page.');
    }
  }

  void _showQr() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Share via QR code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: _profile.toVCard(),
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Scan to save the contact — works without NFC or internet.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            children: <Widget>[
              const BumpShareLogo(size: 76),
              const SizedBox(height: 18),
              Text(
                'Share your contact',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap two phones together. No app needed on the other phone.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _NfcBanner(
                status: _status,
                onEnable: () async {
                  await _nfc.openNfcSettings();
                  await _checkNfc();
                },
              ),
              if (_status != NfcStatus.checking &&
                  _status != NfcStatus.ready)
                const SizedBox(height: 20),
              _ProfileCard(
                profile: _profile,
                onEdit: () async {
                  await Navigator.pushNamed(context, '/edit');
                  await _loadProfile();
                },
                onView: () => Navigator.pushNamed(context, '/profile'),
                onCard: () => Navigator.pushNamed(context, '/card'),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton.icon(
                  onPressed: _startSharing,
                  icon: const Icon(Icons.nfc, size: 28),
                  label: const Text(
                    'Share Contact Card',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _showQr,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Show QR code instead'),
              ),
              TextButton.icon(
                onPressed: _openSharePagePreview,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Preview shared page'),
              ),
              const SizedBox(height: 16),
              Text(
                'The other person only needs NFC switched on. '
                'They tap the link that appears and save the contact.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NfcBanner extends StatelessWidget {
  const _NfcBanner({required this.status, required this.onEnable});

  final NfcStatus status;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    if (status == NfcStatus.ready || status == NfcStatus.checking) {
      return const SizedBox.shrink();
    }

    final String text;
    final IconData icon;
    final bool canEnable;
    switch (status) {
      case NfcStatus.disabled:
        text = 'NFC is turned off. Enable it to share.';
        icon = Icons.nfc;
        canEnable = true;
      case NfcStatus.unsupported:
        text = 'This phone cannot send via NFC (HCE unsupported).';
        icon = Icons.phone_android;
        canEnable = false;
      case NfcStatus.unavailable:
        text = 'This device has no NFC hardware.';
        icon = Icons.phone_android;
        canEnable = false;
      default:
        return const SizedBox.shrink();
    }

    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          if (canEnable)
            TextButton(
              onPressed: onEnable,
              child: const Text('Turn on'),
            ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onEdit,
    required this.onView,
    required this.onCard,
  });

  final Profile profile;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final VoidCallback onCard;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool hasName = profile.name.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    hasName ? profile.name.trim()[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        hasName ? profile.name : 'Your name',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: hasName ? null : colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.phone ?? 'No phone added',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit profile',
                ),
              ],
            ),
            if (profile.socialLinks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.socialLinks.map((String link) {
                    final SocialPlatform platform = detectSocialPlatform(link);
                    return Tooltip(
                      message: platform.label,
                      child: SocialBadge(platform: platform, size: 34),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCard,
                    icon: const Icon(Icons.credit_card, size: 18),
                    label: const Text('Card'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
