import 'package:flutter/material.dart';

import 'screens/business_card_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/sharing_screen.dart';
import 'screens/success_screen.dart';
import 'services/bump_share_nfc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BumpShareNfcService.instance.registerNativeHandlers();
  runApp(const BumpShareApp());
}

class BumpShareApp extends StatelessWidget {
  const BumpShareApp({super.key, this.home = const HomeScreen()});

  /// The first screen. Overridable so tooling can render individual screens
  /// with the exact same theme the shipped app uses.
  final Widget home;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6D28D9),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'BumpShare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
      ),
      home: home,
      routes: <String, WidgetBuilder>{
        '/sharing': (BuildContext context) => const SharingScreen(),
        '/profile': (BuildContext context) => const ProfileScreen(),
        '/edit': (BuildContext context) => const EditProfileScreen(),
        '/card': (BuildContext context) => const BusinessCardScreen(),
        '/success': (BuildContext context) => const SuccessScreen(),
      },
    );
  }
}
