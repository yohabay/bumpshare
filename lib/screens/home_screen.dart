import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_config.dart';
import '../models/profile.dart';
import '../models/social_link.dart';
import '../services/bump_share_nfc.dart';
import '../services/profile_store.dart';
import '../widgets/bump_share_logo.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/social_badge.dart';

enum NfcStatus { checking, ready, unavailable, disabled, unsupported }

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
    final String url = _profile.nfcShareUrl;
    final bool armed = await _nfc.startSharing(url);
    if (!mounted) return;
    if (!armed) {
      _message('Could not start NFC sharing on this phone.');
      return;
    }
    await Navigator.pushNamed(context, '/sharing', arguments: url);
    await _checkNfc();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

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
              width: 244,
              height: 244,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: _profile.toVCard(includePhoto: false),
                version: QrVersions.auto,
                size: 220,
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
    final bool canShare = _status == NfcStatus.ready;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: <Widget>[
                  const BumpShareLogo(size: 60),
                  const SizedBox(height: 12),
                  Text(
                    'Share your contact',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap two phones together. No app needed on the other phone.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _NfcBanner(
                    status: _status,
                    onEnable: () async {
                      await _nfc.openNfcSettings();
                      await _checkNfc();
                    },
                  ),
                  if (_status != NfcStatus.checking &&
                      _status != NfcStatus.ready)
                    const SizedBox(height: 18),
                  _ProfileCard(
                    profile: _profile,
                    onEdit: () async {
                      await Navigator.pushNamed(
                        context,
                        '/edit',
                        arguments: _profile,
                      );
                      await _loadProfile();
                    },
                    onView: () => Navigator.pushNamed(context, '/profile'),
                    onCard: () => Navigator.pushNamed(context, '/card'),
                    onCards: () async {
                      await Navigator.pushNamed(context, '/cards');
                      await _loadProfile();
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: canShare ? _startSharing : null,
                      icon: const Icon(Icons.nfc, size: 28),
                      label: const Text(
                        'Share Contact Card',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    children: <Widget>[
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
                    ],
                  ),
                  const SizedBox(height: 12),
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
    required this.onCards,
  });
  final Profile profile;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final VoidCallback onCard;
  final VoidCallback onCards;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool hasName = profile.name.trim().isNotEmpty;
    final Color accent = accentColor(profile.themeIndex);
    final String title = profile.title?.trim() ?? '';
    final String company = profile.company?.trim() ?? '';
    final String subtitle = title.isNotEmpty && company.isNotEmpty
        ? '$title at $company'
        : (title.isNotEmpty
            ? title
            : (company.isNotEmpty
                ? company
                : (profile.phone ?? 'No phone added')));
    final String cardLabel =
        profile.label.isEmpty ? 'My card' : profile.label;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(width: 5, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ProfileAvatar(
                              profile: profile,
                              size: 44,
                              ringColor: accent,
                              ringWidth: 2,
                            ),
                            if (profile.socialLinks.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 72,
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: profile.socialLinks.map((String link) {
                                    final SocialPlatform platform =
                                        detectSocialPlatform(link);
                                    return Tooltip(
                                      message: platform.label,
                                      child: SocialBadge(platform: platform, size: 20),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                cardLabel.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.9,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasName ? profile.name : 'Your name',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: hasName ? null : colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.visibility_outlined,
                            label: 'Profile',
                            accent: accent,
                            onTap: onView,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.credit_card,
                            label: 'Card',
                            accent: accent,
                            onTap: onCard,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.grid_view_outlined,
                            label: 'Cards',
                            accent: accent,
                            onTap: onCards,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 22, color: accent),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
