import 'dart:ui';
const String kProfileBaseUrl = 'https://bumbshare.vercel.app/';
const List<int> kAccentColors = <int>[
  0xFF6D28D9, // purple
  0xFF0F766E, // teal
  0xFFBE123C, // rose
  0xFF4338CA, // indigo
];
Color accentColor(int index) {
  final int safe = index < 0
      ? 0
      : (index >= kAccentColors.length ? kAccentColors.length - 1 : index);
  return Color(kAccentColors[safe]);
}
