import 'dart:convert';

import '../app_config.dart';

/// The contact card a user shares. Deliberately local-only: no account, no
/// backend and no cloud storage.
class Profile {
  final String name;
  final String? phone;
  final String? email;
  final List<String> socialLinks;

  const Profile({
    required this.name,
    this.phone,
    this.email,
    this.socialLinks = const <String>[],
  });

  Profile copyWith({
    String? name,
    String? phone,
    String? email,
    List<String>? socialLinks,
  }) {
    return Profile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'phone': phone,
        'email': email,
        'socialLinks': socialLinks,
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        name: (json['name'] as String?) ?? '',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        socialLinks: (json['socialLinks'] as List<dynamic>?)
                ?.map((dynamic e) => e.toString())
                .toList() ??
            const <String>[],
      );

  /// Self-contained link to the hosted profile page.
  ///
  /// The profile is base64url-encoded into the fragment. Static hosting is
  /// enough: the page decodes it locally and offers a "Save contact" action.
  String get shareUrl {
    final Map<String, dynamic> data = <String, dynamic>{
      'n': name,
      if (phone != null && phone!.trim().isNotEmpty) 'p': phone!.trim(),
      if (email != null && email!.trim().isNotEmpty) 'e': email!.trim(),
      if (socialLinks.isNotEmpty) 'l': socialLinks,
    };
    final String encoded = base64Url
        .encode(utf8.encode(jsonEncode(data)))
        .replaceAll('=', '');
    return '$kProfileBaseUrl#$encoded';
  }

  factory Profile.demo() => const Profile(
        name: '',
        phone: null,
        email: null,
        socialLinks: <String>[],
      );

  /// vCard 3.0 used by the QR fallback and by the hosted profile page.
  String toVCard() {
    final StringBuffer sb = StringBuffer();
    sb.writeln('BEGIN:VCARD');
    sb.writeln('VERSION:3.0');
    sb.writeln('FN:${_escape(name)}');
    if (phone != null && phone!.trim().isNotEmpty) {
      sb.writeln('TEL;TYPE=CELL:${_escape(phone!.trim())}');
    }
    if (email != null && email!.trim().isNotEmpty) {
      sb.writeln('EMAIL:${_escape(email!.trim())}');
    }
    for (final String link in socialLinks) {
      if (link.trim().isNotEmpty) {
        sb.writeln('URL:${_escape(link.trim())}');
      }
    }
    sb.writeln('NOTE:Shared with BumpShare');
    sb.writeln('END:VCARD');
    return sb.toString();
  }

  /// Escapes text so user input cannot inject extra vCard fields.
  static String _escape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('\r', '')
      .replaceAll('\n', '\\n')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,');
}
