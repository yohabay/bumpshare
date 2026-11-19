import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';

/// App-wide accent, driven by the colour chosen for the active card.
///
/// The value is a [ValueNotifier] so [BumpShareApp] can rebuild its
/// [ThemeData] as soon as the user picks a new card colour. The colour is also
/// written to preferences so the native launch screen can use it on the next
/// cold start.
class AppTheme {
  AppTheme._();

  static const String nativeAccentKey = 'bumpshare_app_accent';
  static final ValueNotifier<int> accentIndex = ValueNotifier<int>(0);

  static Color get accent => accentColor(accentIndex.value);

  static Future<void> initialize(int themeIndex) async {
    accentIndex.value = themeIndex;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(nativeAccentKey, accentColor(themeIndex).toARGB32());
  }

  static Future<void> setAccent(int index) async {
    accentIndex.value = index;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(nativeAccentKey, accentColor(index).toARGB32());
  }
}
