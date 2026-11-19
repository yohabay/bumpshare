import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
class ProfileStore {
  static const String _key = 'bumpshare_profile';
  static const String _cardsKey = 'bumpshare_cards';
  static const String _activeKey = 'bumpshare_active_card';
  static const String _onboardingKey = 'bumpshare_onboarding_done';
  static const String _historyKey = 'bumpshare_share_history';
  static const int _maxHistory = 20;
  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();
  static int _clamp(int index, int length) =>
      index < 0 ? 0 : (index >= length ? length - 1 : index);
  static List<Profile> _decodeCards(String? raw) {
    if (raw == null || raw.isEmpty) return const <Profile>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Profile.fromJson)
          .toList();
    } catch (_) {
      return const <Profile>[];
    }
  }
  static Future<Profile> _legacyProfile(SharedPreferences prefs) async {
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return Profile.demo();
    try {
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      return Profile.fromJson(json);
    } catch (_) {
      return Profile.demo();
    }
  }
  static Future<List<Profile>> _cardsOf(SharedPreferences prefs) async {
    final List<Profile> cards = _decodeCards(prefs.getString(_cardsKey));
    if (cards.isNotEmpty) return cards;
    return <Profile>[await _legacyProfile(prefs)];
  }
  static Future<void> _writeCards(
    SharedPreferences prefs,
    List<Profile> cards,
    int activeIndex,
  ) async {
    final List<Profile> safeCards =
        cards.isEmpty ? <Profile>[Profile.demo()] : cards;
    final int safeIndex = _clamp(activeIndex, safeCards.length);
    await prefs.setString(
      _cardsKey,
      jsonEncode(safeCards.map((Profile p) => p.toJson()).toList()),
    );
    await prefs.setInt(_activeKey, safeIndex);
    await prefs.setString(_key, jsonEncode(safeCards[safeIndex].toJson()));
  }
  static Future<List<Profile>> loadCards() async {
    final SharedPreferences prefs = await _prefs;
    return _cardsOf(prefs);
  }
  static Future<int> loadActiveIndex() async {
    final SharedPreferences prefs = await _prefs;
    final List<Profile> cards = await _cardsOf(prefs);
    return _clamp(prefs.getInt(_activeKey) ?? 0, cards.length);
  }
  static Future<void> setActiveIndex(int index) async {
    final SharedPreferences prefs = await _prefs;
    final List<Profile> cards = await _cardsOf(prefs);
    await _writeCards(prefs, cards, index);
  }
  static Future<Profile> load() async {
    final SharedPreferences prefs = await _prefs;
    final List<Profile> cards = await _cardsOf(prefs);
    return cards[_clamp(prefs.getInt(_activeKey) ?? 0, cards.length)];
  }
  static Future<void> save(Profile profile) async {
    final SharedPreferences prefs = await _prefs;
    final List<Profile> cards = await _cardsOf(prefs);
    final int index = _clamp(prefs.getInt(_activeKey) ?? 0, cards.length);
    cards[index] = profile;
    await _writeCards(prefs, cards, index);
  }
  static Future<void> saveCard(int index, Profile profile) async {
    final SharedPreferences prefs = await _prefs;
    final List<Profile> cards = await _cardsOf(prefs);
    final int safeIndex = _clamp(index, cards.length);
    cards[safeIndex] = profile;
    await _writeCards(prefs, cards, prefs.getInt(_activeKey) ?? 0);
  }
  static Future<void> saveCards(List<Profile> cards, {int? activeIndex}) async {
    final SharedPreferences prefs = await _prefs;
    await _writeCards(prefs, cards, activeIndex ?? prefs.getInt(_activeKey) ?? 0);
  }
  static Future<Profile> addCard({Profile? card}) async {
    final SharedPreferences prefs = await _prefs;
    final List<Profile> cards = await _cardsOf(prefs);
    final Profile newCard = card ??
        Profile(
          label: 'Card ${cards.length + 1}',
          name: '',
          themeIndex: 0,
        );
    cards.add(newCard);
    await _writeCards(prefs, cards, cards.length - 1);
    return newCard;
  }
  static Future<void> deleteCard(int index) async {
    final SharedPreferences prefs = await _prefs;
    final List<Profile> cards = await _cardsOf(prefs);
    if (cards.length == 1) {
      cards[0] = Profile.demo();
    } else {
      cards.removeAt(_clamp(index, cards.length));
    }
    await _writeCards(prefs, cards, prefs.getInt(_activeKey) ?? 0);
  }
  static Future<void> clear() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(_key);
    await prefs.remove(_cardsKey);
    await prefs.remove(_activeKey);
  }
  static Future<bool> isOnboardingComplete() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getBool(_onboardingKey) ?? false;
  }
  static Future<void> setOnboardingComplete() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setBool(_onboardingKey, true);
  }
  static Future<List<DateTime>> loadShareHistory() async {
    final SharedPreferences prefs = await _prefs;
    final List<String> raw = prefs.getStringList(_historyKey) ?? const <String>[];
    return raw
        .map((String value) => DateTime.tryParse(value))
        .whereType<DateTime>()
        .toList();
  }
  static Future<void> recordShare() async {
    final SharedPreferences prefs = await _prefs;
    final List<String> raw =
        List<String>.from(prefs.getStringList(_historyKey) ?? const <String>[]);
    raw.insert(0, DateTime.now().toIso8601String());
    final List<String> trimmed =
        raw.length > _maxHistory ? raw.sublist(0, _maxHistory) : raw;
    await prefs.setStringList(_historyKey, trimmed);
  }
}
