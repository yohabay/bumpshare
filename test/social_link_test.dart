import 'package:bumpshare/models/social_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectSocialPlatform', () {
    test('recognises the supported platforms from full URLs', () {
      expect(detectSocialPlatform('https://www.linkedin.com/in/ada'),
          SocialPlatform.linkedin);
      expect(detectSocialPlatform('https://instagram.com/ada'),
          SocialPlatform.instagram);
      expect(detectSocialPlatform('https://x.com/ada'), SocialPlatform.x);
      expect(detectSocialPlatform('https://twitter.com/ada'), SocialPlatform.x);
      expect(detectSocialPlatform('https://facebook.com/ada'),
          SocialPlatform.facebook);
      expect(detectSocialPlatform('https://github.com/ada'),
          SocialPlatform.github);
      expect(detectSocialPlatform('https://www.tiktok.com/@ada'),
          SocialPlatform.tiktok);
      expect(detectSocialPlatform('https://youtu.be/abc'), SocialPlatform.youtube);
      expect(detectSocialPlatform('https://wa.me/15550100'),
          SocialPlatform.whatsapp);
      expect(detectSocialPlatform('https://t.me/ada'), SocialPlatform.telegram);
      expect(detectSocialPlatform('https://threads.net/@ada'),
          SocialPlatform.threads);
      expect(detectSocialPlatform('https://snapchat.com/add/ada'),
          SocialPlatform.snapchat);
    });

    test('works without a scheme and on subdomains', () {
      expect(detectSocialPlatform('linkedin.com/in/ada'),
          SocialPlatform.linkedin);
      expect(detectSocialPlatform('m.facebook.com/ada'), SocialPlatform.facebook);
      expect(detectSocialPlatform('  github.com/ada  '), SocialPlatform.github);
    });

    test('lookalike domains and unknown links fall back to website', () {
      expect(detectSocialPlatform('https://notlinkedin.com/in/ada'),
          SocialPlatform.website);
      expect(detectSocialPlatform('https://linkedin.com.evil.example'),
          SocialPlatform.website);
      expect(detectSocialPlatform('example.com'), SocialPlatform.website);
      expect(detectSocialPlatform(''), SocialPlatform.website);
      expect(detectSocialPlatform('@ada'), SocialPlatform.website);
    });
  });

  group('display + href', () {
    test('display text drops scheme, www, query and trailing slash', () {
      expect(socialDisplayText('https://www.linkedin.com/in/ada/?utm=x'),
          'linkedin.com/in/ada');
      expect(socialDisplayText('linkedin.com/in/ada'), 'linkedin.com/in/ada');
      expect(socialDisplayText('example.com/'), 'example.com');
    });

    test('display text keeps unparseable input as typed', () {
      expect(socialDisplayText('@ada'), '@ada');
    });

    test('href adds https when missing and keeps the real URL', () {
      expect(socialHref('linkedin.com/in/ada'), 'https://linkedin.com/in/ada');
      expect(socialHref('https://x.com/ada'), 'https://x.com/ada');
    });
  });

  test('every platform has a label and a hint', () {
    for (final SocialPlatform platform in SocialPlatform.values) {
      expect(platform.label, isNotEmpty);
      expect(platform.hint, startsWith('https://'));
    }
  });
}
