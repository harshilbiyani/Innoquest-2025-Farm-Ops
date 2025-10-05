import 'package:flutter/material.dart';
import 'dart:async';
import 'language_selection_page.dart';
import 'services/localization_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to language selection page after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LanguageSelectionPage(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4F1D4), // Light green background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Farm-Ops Logo - Placeholder
            _buildLogoPlaceholder(),
            const SizedBox(height: 20),
            const Text(
              'Farm-Ops',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Sun rays
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.orange.withOpacity(0.3), Colors.transparent],
            ),
          ),
        ),
        // Sun
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.wb_sunny, size: 60, color: Colors.white),
        ),
        // Farm field waves at bottom
        Positioned(
          bottom: 0,
          child: Container(
            width: 200,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green.shade400,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(100),
                bottomRight: Radius.circular(100),
              ),
            ),
            child: const Icon(Icons.grass, color: Colors.white, size: 30),
          ),
        ),
      ],
    );
  }
}
