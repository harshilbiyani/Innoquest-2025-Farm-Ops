import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'services/api_service.dart';
import 'services/localization_service.dart';

class MobileLoginPage extends StatefulWidget {
  const MobileLoginPage({super.key});

  @override
  State<MobileLoginPage> createState() => _MobileLoginPageState();
}

class _MobileLoginPageState extends State<MobileLoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  String selectedLanguage = 'en';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2FCE1), // Brand light green background
      body: SafeArea(
        child: Column(
          children: [
            // Top row with back button and language selector
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF000000),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),

                  // Language selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/india_flag.png',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'en',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Color(0xFF000000),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Registration heading
                    Text(
                      'Registration',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF000000),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Mobile login illustration
                    Image.asset(
                      'assets/images/mobile_login.png',
                      width: 280,
                      height: 280,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 40),

                    // Enter your Mobile Number heading
                    Text(
                      context.localizations.enterMobileNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF000000),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtext
                    Text(
                      'We will send you 4 digit verification code',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF000000),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Phone number input field
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF000000),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Country code selector
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/india_flag.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+91',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF000000),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 20,
                                  color: Color(0xFF000000),
                                ),
                              ],
                            ),
                          ),

                          // Vertical divider
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey.shade400,
                          ),

                          // Phone number input
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: InputDecoration(
                                hintText: context.localizations.mobileNumber,
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: const Color(0xFF000000),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGetStarted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2BC24A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey.shade400,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Get Started',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Already a User? Login here
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already a User? ',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Navigate to login page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Login here',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF2BC24A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGetStarted() async {
    String phoneNumber = _phoneController.text.trim();

    if (phoneNumber.length != 10) {
      _showSnackBar(
        'Please enter a valid 10-digit mobile number',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First check if user already exists
      final checkResult = await ApiService.checkUser(phoneNumber);

      if (!mounted) return;

      if (checkResult['success']) {
        if (checkResult['exists'] == true) {
          // User already exists, redirect to login page
          setState(() {
            _isLoading = false;
          });

          _showSnackBar(
            'Account already exists! Redirecting to login...',
            isError: false,
          );

          // Wait a moment for user to see the message
          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            // Navigate to login page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
          return;
        }
      }

      // User doesn't exist, create account directly
      final createResult = await ApiService.createUser(phoneNumber);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (createResult['success']) {
          _showSnackBar(
            'Account created successfully! Welcome!',
            isError: false,
          );

          // Wait a moment for user to see the message
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            // Navigate directly to home page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(mobileNumber: phoneNumber),
              ),
            );
          }
        } else {
          _showSnackBar(
            createResult['message'] ?? 'Failed to create account',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Network error: ${e.toString()}', isError: true);
        print('❌ Error creating account: $e');
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red : const Color(0xFF2BC24A),
      ),
    );
  }
}
