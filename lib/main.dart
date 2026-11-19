import 'package:flutter/material.dart';
import 'models/profile.dart';
import 'screens/business_card_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/sharing_screen.dart';
import 'screens/success_screen.dart';
import 'services/app_theme.dart';
import 'services/bump_share_nfc.dart';
import 'services/profile_store.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BumpShareNfcService.instance.registerNativeHandlers();
  final bool onboarded = await ProfileStore.isOnboardingComplete();
  final Profile savedProfile = await ProfileStore.load();
  await AppTheme.initialize(savedProfile.themeIndex);
  runApp(BumpShareApp(
    home: onboarded ? const SplashScreen() : const OnboardingScreen(),
  ));
}
class BumpShareApp extends StatefulWidget {
  const BumpShareApp({super.key, this.home = const HomeScreen()});
  final Widget home;
  @override
  State<BumpShareApp> createState() => _BumpShareAppState();
}
class _BumpShareAppState extends State<BumpShareApp> {
  @override
  void initState() {
    super.initState();
    AppTheme.accentIndex.addListener(_onAccentChanged);
  }

  void _onAccentChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppTheme.accentIndex.removeListener(_onAccentChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppTheme.accent,
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'BumpShare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
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
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
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
      home: widget.home,
      routes: <String, WidgetBuilder>{
        '/sharing': (BuildContext context) => SharingScreen(
              shareUrl: ModalRoute.of(context)?.settings.arguments as String?,
            ),
        '/profile': (BuildContext context) => const ProfileScreen(),
        '/edit': (BuildContext context) => EditProfileScreen(
              initial: ModalRoute.of(context)?.settings.arguments as Profile?,
            ),
        '/cards': (BuildContext context) => const CardsScreen(),
        '/card': (BuildContext context) => const BusinessCardScreen(),
        '/success': (BuildContext context) => const SuccessScreen(),
      },
    );
  }
}
