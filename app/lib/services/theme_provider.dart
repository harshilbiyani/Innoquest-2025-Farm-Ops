import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themeKey = 'isDarkMode';

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  // Load theme preference from storage
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading theme preference: $e');
    }
  }

  // Toggle dark mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
      print('✅ Theme preference saved: ${_isDarkMode ? "Dark" : "Light"}');
    } catch (e) {
      print('❌ Error saving theme preference: $e');
    }
  }

  // Set theme explicitly
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode == isDark) return;

    _isDarkMode = isDark;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      print('❌ Error saving theme preference: $e');
    }
  }

  // Light theme
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF008575),
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF008575),
        secondary: Color(0xFF2BC24A),
        surface: Colors.white,
        error: Colors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Dark theme
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF008575),
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00A890),
        secondary: Color(0xFF2BC24A),
        surface: Color(0xFF1E1E1E),
        error: Colors.redAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Get current theme
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  // Helper methods for consistent colors across the app
  Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  Color getCardColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  Color getTextColor(BuildContext context) {
    return _isDarkMode ? Colors.white : Colors.black;
  }

  Color getSecondaryTextColor(BuildContext context) {
    return _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
  }

  Color getLightGreenBackground(BuildContext context) {
    return _isDarkMode ? const Color(0xFF1E3A35) : const Color(0xFFE2FCE1);
  }

  Color getBorderColor(BuildContext context) {
    return _isDarkMode
        ? Colors.grey.shade700
        : const Color(0xFF008575).withOpacity(0.3);
  }

  // Get appropriate logo based on theme
  String getLogo() {
    return _isDarkMode
        ? 'assets/images/farmops_alt.png'
        : 'assets/images/farmops_logo.png';
  }
}

// Extension for easy theme access in widgets
extension ThemeExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  Color get cardColor => Theme.of(this).colorScheme.surface;
  Color get textColor => isDarkMode ? Colors.white : Colors.black;
  Color get secondaryTextColor =>
      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
  Color get lightGreenBg =>
      isDarkMode ? const Color(0xFF1E3A35) : const Color(0xFFE2FCE1);
  Color get borderColor => isDarkMode
      ? Colors.grey.shade700
      : const Color(0xFF008575).withOpacity(0.3);

  // Get appropriate logo based on theme
  String get farmOpsLogo => isDarkMode
      ? 'assets/images/farmops_alt.png'
      : 'assets/images/farmops_logo.png';
}
