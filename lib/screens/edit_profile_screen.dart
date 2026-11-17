import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/social_link.dart';
import '../services/profile_store.dart';
import '../widgets/social_badge.dart';

/// Screen for editing the user's own profile (name, phone, email, socials).
///
/// Socials start as a single field. The **+** button adds another one, and the
/// logo inside each field follows the link the user pastes.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.initial});

  final Profile? initial;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const int _maxLinks = 10;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  final List<TextEditingController> _linkCtrl = <TextEditingController>[];
  final List<FocusNode> _linkFocus = <FocusNode>[];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Profile p = widget.initial ?? Profile.demo();
    _nameCtrl = TextEditingController(text: p.name);
    _phoneCtrl = TextEditingController(text: p.phone ?? '');
    _emailCtrl = TextEditingController(text: p.email ?? '');

    final List<String> links =
        p.socialLinks.isEmpty ? <String>[''] : p.socialLinks;
    for (final String link in links) {
      _linkCtrl.add(TextEditingController(text: link));
      _linkFocus.add(FocusNode());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    for (final TextEditingController c in _linkCtrl) {
      c.dispose();
    }
    for (final FocusNode f in _linkFocus) {
      f.dispose();
    }
    super.dispose();
  }

  void _addLink() {
    if (_linkCtrl.length >= _maxLinks) return;
    setState(() {
      _linkCtrl.add(TextEditingController());
      _linkFocus.add(FocusNode());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _linkFocus.last.requestFocus();
    });
  }

  void _removeLink(int index) {
    if (_linkCtrl.length == 1) {
      _linkCtrl.first.clear();
      setState(() {});
      return;
    }
    final TextEditingController controller = _linkCtrl.removeAt(index);
    final FocusNode focus = _linkFocus.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
      focus.dispose();
    });
  }

  Future<void> _save() async {
    final String name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final List<String> socials = _linkCtrl
          .map((TextEditingController c) => c.text.trim())
          .where((String s) => s.isNotEmpty)
          .toList();
      final Profile profile = Profile(
        name: name,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        socialLinks: socials,
      );
      await ProfileStore.save(profile).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved locally.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _SectionTitle(text: 'Personal info', color: colors.primary),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 28),
              _SectionTitle(text: 'Links', color: colors.primary),
              const SizedBox(height: 4),
              Text(
                'Paste a link — the logo is picked automatically. '
                'Tap + to add another.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ...List<Widget>.generate(_linkCtrl.length, (int i) {
                final SocialPlatform platform =
                    detectSocialPlatform(_linkCtrl[i].text);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _linkCtrl[i],
                    focusNode: _linkFocus[i],
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    textInputAction: i == _linkCtrl.length - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: platform == SocialPlatform.website
                          ? 'Social link'
                          : '${platform.label} link',
                      hintText: platform.hint,
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 56, minHeight: 52),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: SocialBadge(platform: platform, size: 30),
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Remove link',
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removeLink(i),
                      ),
                    ),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed:
                      _linkCtrl.length >= _maxLinks ? null : _addLink,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add link'),
                ),
              ),
              if (_linkCtrl.length >= _maxLinks)
                Text(
                  'Up to $_maxLinks links.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving…' : 'Save profile'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Everything stays on this phone until you tap to share.',
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
    );
  }
}
