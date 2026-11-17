import 'dart:convert';

import 'package:bumpshare/app_config.dart';
import 'package:bumpshare/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> payloadOf(Profile profile) {
  final String fragment = Uri.parse(profile.shareUrl).fragment;
  final String padded = fragment + '=' * ((4 - fragment.length % 4) % 4);
  return jsonDecode(utf8.decode(base64Url.decode(padded))) as Map<String, dynamic>;
}

void main() {
  const Profile profile = Profile(
    name: 'Ada Lovelace',
    phone: '+1 555 0100',
    email: 'ada@example.com',
    socialLinks: <String>['https://example.com'],
  );

  test('shareUrl is self-contained and points at the hosted page', () {
    expect(profile.shareUrl, startsWith(kProfileBaseUrl));
    expect(Uri.parse(profile.shareUrl).fragment, isNotEmpty);
  });

  test('shareUrl fragment decodes back to the profile', () {
    expect(payloadOf(profile), <String, dynamic>{
      'n': 'Ada Lovelace',
      'p': '+1 555 0100',
      'e': 'ada@example.com',
      'l': <dynamic>['https://example.com'],
    });
  });

  test('empty fields are omitted from the shared payload', () {
    expect(payloadOf(Profile.demo()), <String, dynamic>{'n': ''});
  });

  test('vCard escapes user text so it cannot inject fields', () {
    const Profile risky = Profile(name: 'A;B,C\nD\\E');
    final String card = risky.toVCard();
    expect(card, contains(r'FN:A\;B\,C\nD\\E'));
    expect(card, isNot(contains('\nBEGIN:VCARD')));
  });

  test('fromJson tolerates missing and legacy fields', () {
    final Profile restored = Profile.fromJson(<String, dynamic>{
      'name': 'Grace',
      'id': 'legacy-id',
      'photoUrl': 'https://example.com/photo.png',
      'socialLinks': <dynamic>['https://example.com', 42],
    });
    expect(restored.name, 'Grace');
    expect(restored.phone, isNull);
    expect(restored.email, isNull);
    expect(restored.socialLinks, <String>['https://example.com', '42']);
  });
}
