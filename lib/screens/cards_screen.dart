import 'package:flutter/material.dart';
import '../app_config.dart';
import '../models/profile.dart';
import '../services/app_theme.dart';
import '../services/profile_store.dart';
import '../widgets/profile_avatar.dart';
import 'edit_profile_screen.dart';
class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});
  @override
  State<CardsScreen> createState() => _CardsScreenState();
}
class _CardsScreenState extends State<CardsScreen> {
  List<Profile> _cards = <Profile>[Profile.demo()];
  int _activeIndex = 0;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    final List<Profile> cards = await ProfileStore.loadCards();
    final int active = await ProfileStore.loadActiveIndex();
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _activeIndex = active;
      _loading = false;
    });
  }
  Future<void> _select(int index) async {
    await ProfileStore.setActiveIndex(index);
    await AppTheme.setAccent(_cards[index].themeIndex);
    if (mounted) Navigator.of(context).pop(true);
  }
  Future<void> _add() async {
    await ProfileStore.addCard();
    await _load();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            EditProfileScreen(cardIndex: _activeIndex),
      ),
    );
    await _load();
  }
  Future<void> _edit(int index) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => EditProfileScreen(
          initial: _cards[index],
          cardIndex: index,
        ),
      ),
    );
    await _load();
  }
  Future<void> _rename(int index) async {
    final TextEditingController controller = TextEditingController(
      text: _cards[index].label.isEmpty
          ? 'Card ${index + 1}'
          : _cards[index].label,
    );
    final String? next = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Rename card'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Card name'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next == null || next.isEmpty) return;
    await ProfileStore.saveCard(index, _cards[index].copyWith(label: next));
    await _load();
  }
  Future<void> _delete(int index) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete this card?'),
        content: Text(
          '"${_cardLabel(_cards[index], index)}" will be removed from this phone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ProfileStore.deleteCard(index);
    await _load();
  }
  String _cardLabel(Profile card, int index) =>
      card.label.isEmpty ? 'Card ${index + 1}' : card.label;
  String _roleLine(Profile card) {
    final String title = card.title?.trim() ?? '';
    final String company = card.company?.trim() ?? '';
    if (title.isNotEmpty && company.isNotEmpty) return '$title at $company';
    if (title.isNotEmpty) return title;
    if (company.isNotEmpty) return company;
    return card.name.trim().isEmpty ? 'Empty card' : 'Tap to make active';
  }
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cards'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add card',
            icon: const Icon(Icons.add),
            onPressed: _add,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      itemCount: _cards.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        final Profile card = _cards[index];
                        final bool active = index == _activeIndex;
                        final Color accent = accentColor(card.themeIndex);
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: ProfileAvatar(
                              profile: card,
                              size: 52,
                              ringColor: accent,
                              ringWidth: 2,
                            ),
                            title: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    _cardLabel(card, index),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                if (active)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Active',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _roleLine(card),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            onTap: () => _select(index),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  tooltip: 'Edit card',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _edit(index),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'More',
                                  onSelected: (String value) {
                                    if (value == 'rename') _rename(index);
                                    if (value == 'delete') _delete(index);
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      const <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'rename',
                                      child: Text('Rename'),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'The active card is the one you bump or show as a QR code.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
