import 'dart:convert';
import '../app_config.dart';
class Profile {
  final String label;
  final String name;
  final String? phone;
  final String? email;
  final List<String> socialLinks;
  final String? photo;
  final String? title;
  final String? company;
  final int themeIndex;
  const Profile({
    required this.name,
    this.label = '',
    this.phone,
    this.email,
    this.socialLinks = const <String>[],
    this.photo,
    this.title,
    this.company,
    this.themeIndex = 0,
  });
  Profile copyWith({
    String? label,
    String? name,
    String? phone,
    String? email,
    List<String>? socialLinks,
    String? photo,
    String? title,
    String? company,
    int? themeIndex,
  }) {
    return Profile(
      label: label ?? this.label,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      socialLinks: socialLinks ?? this.socialLinks,
      photo: photo ?? this.photo,
      title: title ?? this.title,
      company: company ?? this.company,
      themeIndex: themeIndex ?? this.themeIndex,
    );
  }
  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'name': name,
        'phone': phone,
        'email': email,
        'socialLinks': socialLinks,
        'photo': photo,
        'title': title,
        'company': company,
        'themeIndex': themeIndex,
      };
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        label: (json['label'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        socialLinks: (json['socialLinks'] as List<dynamic>?)
                ?.map((dynamic e) => e.toString())
                .toList() ??
            const <String>[],
        photo: json['photo'] as String?,
        title: json['title'] as String?,
        company: json['company'] as String?,
        themeIndex: (json['themeIndex'] as num?)?.toInt() ?? 0,
      );
  static const int _nfcMaxLength = 1200;
  String get shareUrl => _urlFor(_payload());
  String get qrShareUrl => _urlFor(_payload(includePhoto: false));
  String get nfcShareUrl {
    final String full = shareUrl;
    if (full.length <= _nfcMaxLength) return full;
    final Map<String, dynamic> data = _payload(includeLinks: false);
    String link = _urlFor(data);
    if (link.length <= _nfcMaxLength) return link;
    data.remove('ph');
    link = _urlFor(data);
    if (link.length <= _nfcMaxLength) return link;
    data.remove('c');
    link = _urlFor(data);
    if (link.length <= _nfcMaxLength) return link;
    data.remove('t');
    return _urlFor(data);
  }
  Map<String, dynamic> _payload({
    bool includeLinks = true,
    bool includePhoto = true,
  }) =>
      <String, dynamic>{
        'n': name,
        if (phone != null && phone!.trim().isNotEmpty) 'p': phone!.trim(),
        if (email != null && email!.trim().isNotEmpty) 'e': email!.trim(),
        if (includeLinks && socialLinks.isNotEmpty) 'l': socialLinks,
        if (includePhoto && photo != null && photo!.isNotEmpty) 'ph': photo,
        if (title != null && title!.trim().isNotEmpty) 't': title!.trim(),
        if (company != null && company!.trim().isNotEmpty) 'c': company!.trim(),
        if (themeIndex != 0) 'th': themeIndex,
      };
  String _urlFor(Map<String, dynamic> data) {
    final String encoded = base64Url
        .encode(utf8.encode(jsonEncode(data)))
        .replaceAll('=', '');
    return '$kProfileBaseUrl#$encoded';
  }
  factory Profile.demo() => const Profile(
        label: 'My card',
        name: '',
        phone: null,
        email: null,
        socialLinks: <String>[],
      );
  String toVCard({bool includePhoto = true}) {
    final StringBuffer sb = StringBuffer();
    void add(String line) => sb.write('$line\r\n');
    add('BEGIN:VCARD');
    add('VERSION:3.0');
    add('FN:${_escape(name)}');
    if (title != null && title!.trim().isNotEmpty) {
      add('TITLE:${_escape(title!.trim())}');
    }
    if (company != null && company!.trim().isNotEmpty) {
      add('ORG:${_escape(company!.trim())}');
    }
    if (phone != null && phone!.trim().isNotEmpty) {
      add('TEL;TYPE=CELL:${_escape(phone!.trim())}');
    }
    if (email != null && email!.trim().isNotEmpty) {
      add('EMAIL:${_escape(email!.trim())}');
    }
    for (final String link in socialLinks) {
      if (link.trim().isNotEmpty) {
        add('URL:${_escape(link.trim())}');
      }
    }
    if (includePhoto && photo != null && photo!.isNotEmpty) {
      add(_fold('PHOTO;ENCODING=b;TYPE=JPEG:$photo'));
    }
    add('URL:${_escape(includePhoto ? shareUrl : qrShareUrl)}');
    add('NOTE:Shared with BumpShare');
    add('END:VCARD');
    return sb.toString();
  }
  static String _fold(String line) {
    if (line.length <= 75) return line;
    final StringBuffer folded = StringBuffer(line.substring(0, 75));
    int index = 75;
    while (index < line.length) {
      final int end = (index + 74 > line.length) ? line.length : index + 74;
      folded.write('\r\n ');
      folded.write(line.substring(index, end));
      index = end;
    }
    return folded.toString();
  }
  static String _escape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('\r', '')
      .replaceAll('\n', '\\n')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,');
}
