import 'dart:convert';
import 'package:bumpshare/app_config.dart';
import 'package:bumpshare/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';
Map<String, dynamic> payloadFromUrl(String url) {
  final String fragment = Uri.parse(url).fragment;
  final String padded = fragment + '=' * ((4 - fragment.length % 4) % 4);
  return jsonDecode(utf8.decode(base64Url.decode(padded))) as Map<String, dynamic>;
}
Map<String, dynamic> payloadOf(Profile profile) =>
    payloadFromUrl(profile.shareUrl);
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
  test('card label is local only and never enters the shared payload', () {
    const Profile labelled = Profile(name: 'Ada', label: 'Work');
    expect(payloadOf(labelled), <String, dynamic>{'n': 'Ada'});
    expect(labelled.toJson()['label'], 'Work');
  });
  test('extended fields use the compact web payload keys', () {
    const Profile rich = Profile(
      name: 'Ada',
      title: 'Engineer',
      company: 'Acme',
      themeIndex: 2,
    );
    expect(payloadOf(rich), <String, dynamic>{
      'n': 'Ada',
      't': 'Engineer',
      'c': 'Acme',
      'th': 2,
    });
  });
  test('nfcShareUrl drops social links when the link is too long', () {
    final Profile busy = Profile(
      name: 'Ada',
      socialLinks: List<String>.generate(
        24,
        (int i) => 'https://example.com/a-long-link-$i',
      ),
    );
    expect(busy.shareUrl.length, greaterThan(1200));
    expect(busy.nfcShareUrl.length, lessThanOrEqualTo(1200));
    expect(payloadFromUrl(busy.nfcShareUrl), isNot(contains('l')));
    expect(payloadFromUrl(busy.nfcShareUrl)['n'], 'Ada');
  });
  test('nfcShareUrl drops the photo before dropping contact details', () {
    final Profile busy = Profile(
      name: 'Ada',
      phone: '+1 555 0100',
      email: 'ada@example.com',
      title: 'Engineer',
      company: 'Acme',
      photo: base64Encode(List<int>.filled(4000, 0xff)),
      socialLinks: List<String>.generate(
        12,
        (int i) => 'https://example.com/link-$i',
      ),
    );
    final Map<String, dynamic> payload = payloadFromUrl(busy.nfcShareUrl);
    expect(busy.nfcShareUrl.length, lessThanOrEqualTo(1200));
    expect(payload, isNot(contains('ph')));
    expect(payload, isNot(contains('l')));
    expect(payload['p'], '+1 555 0100');
    expect(payload['e'], 'ada@example.com');
  });
  test('vCard includes the BumpShare profile link', () {
    expect(profile.toVCard(), contains('URL:${profile.shareUrl}'));
  });
  test('vCard includes title, company and a folded photo', () {
    final Profile rich = Profile(
      name: 'Ada',
      title: 'Engineer',
      company: 'Acme',
      photo: base64Encode(List<int>.filled(300, 0x41)),
    );
    final String card = rich.toVCard();
    expect(card, contains('TITLE:Engineer'));
    expect(card, contains('ORG:Acme'));
    expect(card, contains('PHOTO;ENCODING=b;TYPE=JPEG:'));
    final int start = card.indexOf('PHOTO;');
    final int end = card.indexOf('\r\nEND:VCARD', start);
    final String photoLine = card.substring(start, end);
    expect(photoLine, contains('\r\n '));
    expect(photoLine.split('\r\n ').first.length, 75);
  });
  test('QR vCard omits the photo and uses a photo-free profile link', () {
    final Profile rich = Profile(
      name: 'Ada',
      photo: base64Encode(List<int>.filled(300, 0x41)),
      title: 'Engineer',
    );
    final String card = rich.toVCard(includePhoto: false);
    expect(card, isNot(contains('PHOTO;')));
    expect(card, contains('URL:${rich.qrShareUrl}'));
    expect(card, isNot(contains('URL:${rich.shareUrl}')));
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
    expect(restored.label, '');
    expect(restored.photo, isNull);
    expect(restored.themeIndex, 0);
  });
}
