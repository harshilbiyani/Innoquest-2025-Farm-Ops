import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'services/api_service.dart';
import 'services/user_preferences.dart';
import 'services/localization_service.dart';
import 'home_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final String mobileNumber;

  const OtpVerificationPage({super.key, required this.mobileNumber});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  int _remainingSeconds = 180; // 3 minutes
  Timer? _timer;
  bool _isResendEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 180;
    _isResendEnabled = false;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isResendEnabled = true;
          _timer?.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _resendOtp() async {
    if (_isResendEnabled) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Call API to resend OTP
        final result = await ApiService.sendOtp(widget.mobileNumber);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (result['success']) {
            // Clear OTP fields
            for (var controller in _otpControllers) {
              controller.clear();
            }

            // Restart timer
            _startTimer();

            // Show OTP in development mode
            if (result['otp'] != null) {
              print('🔐 Development OTP: ${result['otp']}');
            }

            _showSnackBar(
              'OTP has been resent to +91${widget.mobileNumber}',
              isError: false,
            );
          } else {
            _showSnackBar(
              result['message'] ?? 'Failed to resend OTP',
              isError: true,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('An error occurred. Please try again.', isError: true);
        }
      }
    }
  }

  void _verifyOtp() async {
    String otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 4) {
      _showSnackBar('Please enter complete OTP', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call API to verify OTP
      final result = await ApiService.verifyOtp(widget.mobileNumber, otp);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Store user data
          final user = result['user'];
          final String userId = user['user_id'] ?? '';
          final String mobileNumber =
              user['mobile_phone'] ?? widget.mobileNumber;

          // Save user session for persistent login
          await UserPreferences.saveUserSession(
            mobileNumber: mobileNumber,
            userId: userId,
          );

          print('✅ User logged in: $mobileNumber');
          print('   User ID: $userId');
          print('   Session saved for persistent login');

          _showSnackBar(
            result['message'] ?? 'Login successful!',
            isError: false,
          );

          // Navigate to home page
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) =>
                    HomePage(mobileNumber: widget.mobileNumber),
              ),
              (route) => false, // Remove all previous routes
            );
          }
        } else {
          _showSnackBar(result['message'] ?? 'Invalid OTP', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('An error occurred. Please try again.', isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2FCE1), // Brand light green background
      body: SafeArea(
        child: Column(
          children: [
            // Back button at top left
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
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
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // OTP verification card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                        children: [
                          // OTP illustration
                          Image.asset(
                            'assets/images/otp.png',
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(height: 24),

                          // Verification code heading
                          Text(
                            'Verification code',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF000000),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Instruction text
                          Text(
                            'Please enter the OTP which\nyou have received on your\nmobile number.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // OTP input boxes - wrapped in Flexible to prevent overflow
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              return Flexible(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _otpControllers[index],
                                    focusNode: _focusNodes[index],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    color: const Color(0xFF000000),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 3) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                  },
                                ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 24),

                          // Timer
                          Text(
                            _formatTime(_remainingSeconds),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Resend OTP button
                          GestureDetector(
                            onTap: _resendOtp,
                            child: Text(
                              'Resend OTP',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _isResendEnabled
                                    ? const Color(0xFF2BC24A)
                                    : Colors.grey.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
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
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
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
}
