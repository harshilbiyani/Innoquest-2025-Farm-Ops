import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'splash_screen.dart';
import 'services/user_preferences.dart';
import 'services/theme_provider.dart';
import 'services/localization_service.dart';
import 'home_page.dart';
import 'language_selection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize localization service
  final localizationService = LocalizationService();
  await localizationService.loadLanguage();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: localizationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocalizationService>(
      builder: (context, themeProvider, localizationService, child) {
        return MaterialApp(
          title: 'FarmOps',
          debugShowCheckedModeBanner: false,
          locale: localizationService.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('mr'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: themeProvider.lightTheme.copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          darkTheme: themeProvider.darkTheme.copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          ),
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const InitialScreen(),
        );
      },
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Show splash screen for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check if user is already logged in
    final isLoggedIn = await UserPreferences.isLoggedIn();

    if (isLoggedIn) {
      // Get saved user data
      final mobileNumber = await UserPreferences.getMobileNumber();

      if (mobileNumber != null && mounted) {
        // Navigate to home page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(mobileNumber: mobileNumber),
          ),
        );
        return;
      }
    }

    // Navigate to language selection page (normal flow)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LanguageSelectionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
