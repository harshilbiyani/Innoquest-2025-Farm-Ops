import 'package:flutter/material.dart';
import 'services/theme_provider.dart';
import 'services/localization_service.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFE2FCE1), // Brand light green background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Farm-Ops Logo (includes text in logo)
            Image.asset(context.farmOpsLogo, width: 300, height: 300),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                context.isDarkMode
                    ? const Color(0xFF00A890)
                    : const Color(0xFF2BC24A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
