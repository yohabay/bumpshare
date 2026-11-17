import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/social_link.dart';
import '../services/profile_store.dart';
import '../widgets/bump_share_logo.dart';
import '../widgets/social_badge.dart';

/// Third milestone screen: profile details that get shared via NFC.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile _profile = Profile.demo();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Profile p = await ProfileStore.load();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    await Navigator.pushNamed(context, '/edit');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final Profile profile = _profile;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String initial = profile.name.isNotEmpty ? profile.name[0] : '?';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BumpShareLogo(size: 64),
                const SizedBox(height: 24),
                // Avatar with colored ring
                Container(
                  width: 132,
                  height: 132,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.name.isEmpty ? 'Your name' : profile.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: profile.name.isEmpty ? colorScheme.onSurfaceVariant : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.name.isEmpty
                      ? 'Tap edit to add your details'
                      : 'This is how your friends will see you.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                // Contact details card
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      _ProfileRow(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: profile.phone,
                      ),
                      const Divider(height: 1),
                      _ProfileRow(
                        icon: Icons.email,
                        label: 'Email',
                        value: profile.email,
                      ),
                      if (profile.socialLinks.isNotEmpty) ...[
                        const Divider(height: 1),
                        ...profile.socialLinks.map(
                          (String social) => _ProfileRow(
                            leading: SocialBadge(
                              platform: detectSocialPlatform(social),
                            ),
                            label: detectSocialPlatform(social).label,
                            value: socialDisplayText(social),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Edit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _edit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit profile'),
                  ),
                ),
                const SizedBox(height: 12),
                // Hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.nfc,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Shared over NFC as a contact card',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final String? value;

  const _ProfileRow({
    this.icon,
    this.leading,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          leading ??
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon ?? Icons.link,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? '—',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
