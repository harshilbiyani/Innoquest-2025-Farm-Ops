import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'mobile_login_page.dart';
import 'services/theme_provider.dart';
import 'services/localization_service.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  String selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFE2FCE1), // Brand light green background
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Farm-Ops Logo (includes text in logo)
            Image.asset(context.farmOpsLogo, width: 220, height: 220),

            const SizedBox(height: 20),

            // Language selection card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.localizations.selectLanguage,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // English option
                    _buildLanguageOption('English', 'English'),
                    const SizedBox(height: 16),

                    // Hindi option
                    _buildLanguageOption('हिंदी', 'Hindi'),
                    const SizedBox(height: 16),

                    // Marathi option
                    _buildLanguageOption('मराठी', 'Marathi'),
                    const SizedBox(height: 32),

                    // Next button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Save language preference
                          final localizationService = Provider.of<LocalizationService>(context, listen: false);
                          String languageCode = 'en'; // default
                          if (selectedLanguage == 'Hindi') {
                            languageCode = 'hi';
                          } else if (selectedLanguage == 'Marathi') {
                            languageCode = 'mr';
                          }
                          await localizationService.changeLanguage(languageCode);
                          
                          // Navigate to mobile login page
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MobileLoginPage(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2BC24A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          context.localizations.next,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Farmer Illustration - with constrained height
            Image.asset(
              'assets/images/farmer_illustration.png',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String text, String value) {
    bool isSelected = selectedLanguage == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLanguage = value;
        });
      },
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF2BC24A) : Colors.grey,
                width: 2,
              ),
              color: isSelected ? const Color(0xFF2BC24A) : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.circle, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: context.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
