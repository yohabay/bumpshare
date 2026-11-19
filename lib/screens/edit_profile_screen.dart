import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../app_config.dart';
import '../models/profile.dart';
import '../services/app_theme.dart';
import '../models/social_link.dart';
import '../services/profile_store.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/social_badge.dart';
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.initial, this.cardIndex});
  final Profile? initial;
  final int? cardIndex;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}
class _EditProfileScreenState extends State<EditProfileScreen> {
  static const int _maxLinks = 10;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _companyCtrl;
  final List<TextEditingController> _linkCtrl = <TextEditingController>[];
  final List<FocusNode> _linkFocus = <FocusNode>[];
  String? _photo;
  int _themeIndex = 0;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final Profile p = widget.initial ?? Profile.demo();
    _labelCtrl = TextEditingController(
      text: p.label.isEmpty ? 'My card' : p.label,
    );
    _nameCtrl = TextEditingController(text: p.name);
    _phoneCtrl = TextEditingController(text: p.phone ?? '');
    _emailCtrl = TextEditingController(text: p.email ?? '');
    _titleCtrl = TextEditingController(text: p.title ?? '');
    _companyCtrl = TextEditingController(text: p.company ?? '');
    _photo = p.photo;
    _themeIndex = p.themeIndex;
    final List<String> links =
        p.socialLinks.isEmpty ? <String>[''] : p.socialLinks;
    for (final String link in links) {
      _linkCtrl.add(TextEditingController(text: link));
      _linkFocus.add(FocusNode());
    }
  }
  @override
  void dispose() {
    _labelCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _titleCtrl.dispose();
    _companyCtrl.dispose();
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
  Future<void> _pickPhoto() async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (file == null) return;
      final Color accent = accentColor(_themeIndex);
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: 256,
        maxHeight: 256,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: 'Crop photo',
            toolbarColor: accent,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: accent,
            showCropGrid: true,
            lockAspectRatio: true,
            aspectRatioPresets: const <CropAspectRatioPresetData>[
              CropAspectRatioPreset.square,
            ],
          ),
          IOSUiSettings(
            title: 'Crop photo',
            aspectRatioPresets: const <CropAspectRatioPresetData>[
              CropAspectRatioPreset.square,
            ],
          ),
        ],
      );
      if (cropped == null) return; // User backed out of the crop screen.
      final Uint8List bytes = await cropped.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = base64Encode(bytes));
    } catch (e) {
      if (!mounted) return;
      final String message = e is MissingPluginException
          ? 'Photo tools are not loaded. Stop the app and run it again '
              '(a full rebuild, not hot reload).'
          : 'Could not pick a photo: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
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
      final String label = _labelCtrl.text.trim().isEmpty
          ? 'My card'
          : _labelCtrl.text.trim();
      final Profile profile = Profile(
        label: label,
        name: name,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        socialLinks: socials,
        photo: _photo,
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        company:
            _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
        themeIndex: _themeIndex,
      );
      final Future<void> write = widget.cardIndex == null
          ? ProfileStore.save(profile)
          : ProfileStore.saveCard(widget.cardIndex!, profile);
      await write.timeout(const Duration(seconds: 5));
      await AppTheme.setAccent(profile.themeIndex);
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
    final Color accent = accentColor(_themeIndex);
    const List<String> themeNames = <String>[
      'Purple',
      'Teal',
      'Rose',
      'Indigo',
    ];
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
              Row(
                children: <Widget>[
                  ProfileAvatar(
                    profile: Profile(name: _nameCtrl.text, photo: _photo),
                    size: 76,
                    ringColor: accent,
                    ringWidth: 3,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Photo',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A small thumbnail travels with your card.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Wrap(
                          children: <Widget>[
                            TextButton.icon(
                              onPressed: _pickPhoto,
                              icon: const Icon(Icons.photo_outlined),
                              label: Text(_photo == null ? 'Add' : 'Change'),
                            ),
                            if (_photo != null)
                              TextButton.icon(
                                onPressed: () => setState(() => _photo = null),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remove'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _labelCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Card name',
                  hintText: 'Personal, Work…',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 20),
              _SectionTitle(text: 'Personal info', color: accent),
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
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Job title',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _companyCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Company',
                  prefixIcon: Icon(Icons.business_outlined),
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
              _SectionTitle(text: 'Links', color: accent),
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
              const SizedBox(height: 28),
              _SectionTitle(text: 'Card colour', color: accent),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<Widget>.generate(kAccentColors.length, (int i) {
                  return ChoiceChip(
                    label: Text(themeNames[i]),
                    avatar: CircleAvatar(
                      backgroundColor: Color(kAccentColors[i]),
                      radius: 9,
                    ),
                    selected: i == _themeIndex,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _themeIndex = i);
                      AppTheme.setAccent(i);
                    },
                  );
                }),
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
