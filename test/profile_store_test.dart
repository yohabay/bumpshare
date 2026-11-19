import 'package:bumpshare/models/profile.dart';
import 'package:bumpshare/services/profile_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });
  test('a legacy single profile is migrated into a one-card list', () async {
    await ProfileStore.save(const Profile(name: 'Ada', label: 'Personal'));
    final List<Profile> cards = await ProfileStore.loadCards();
    expect(cards, hasLength(1));
    expect(cards.first.name, 'Ada');
    expect(await ProfileStore.loadActiveIndex(), 0);
  });
  test('cards can be added, edited, selected and deleted', () async {
    await ProfileStore.save(const Profile(name: 'Ada', label: 'Personal'));
    await ProfileStore.addCard(
      card: const Profile(name: 'Ada at Work', label: 'Work'),
    );
    List<Profile> cards = await ProfileStore.loadCards();
    expect(cards.map((Profile p) => p.label), <String>['Personal', 'Work']);
    expect(await ProfileStore.loadActiveIndex(), 1);
    await ProfileStore.saveCard(0, const Profile(name: 'Ada L.', label: 'Me'));
    cards = await ProfileStore.loadCards();
    expect(cards.first.name, 'Ada L.');
    await ProfileStore.setActiveIndex(0);
    expect((await ProfileStore.load()).label, 'Me');
    await ProfileStore.deleteCard(0);
    cards = await ProfileStore.loadCards();
    expect(cards, hasLength(1));
    expect(cards.first.label, 'Work');
  });
  test('share history is stored newest first and capped', () async {
    for (int i = 0; i < 25; i++) {
      await ProfileStore.recordShare();
    }
    final List<DateTime> history = await ProfileStore.loadShareHistory();
    expect(history, hasLength(20));
    for (int i = 1; i < history.length; i++) {
      expect(history[i - 1].isAfter(history[i]) || history[i - 1] == history[i],
          isTrue);
    }
  });
}
