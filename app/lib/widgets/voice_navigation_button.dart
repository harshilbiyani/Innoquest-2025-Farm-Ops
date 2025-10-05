import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../services/voice_navigation_service.dart';
import '../location_recommendation_page.dart';
import '../soil_recommendation_page.dart';
import '../professional_advisor_page.dart';
import '../government_schemes_page.dart';
import '../weather_forecast_page.dart';
import '../disease_detection_page.dart';
import '../market_analysis_page.dart';
import '../profit_loss_calculator_page.dart';
import '../profile_page.dart';

class VoiceNavigationButton extends StatefulWidget {
  final String? mobileNumber;

  const VoiceNavigationButton({super.key, this.mobileNumber});

  @override
  State<VoiceNavigationButton> createState() => _VoiceNavigationButtonState();
}

class _VoiceNavigationButtonState extends State<VoiceNavigationButton> {
  final VoiceNavigationService _voiceService = VoiceNavigationService();
  bool _isListening = false;
  bool _isInitialized = false;
  String _statusText = '';
  String _recognizedText = '';
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    final initialized = await _voiceService.initialize();
    setState(() {
      _isInitialized = initialized;
      if (!initialized) {
        _statusText = 'Voice recognition not available';
      }
    });
  }

  void _toggleListening() {
    if (!_isInitialized) {
      _showErrorDialog('Voice recognition is not available on this device.');
      return;
    }

    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _statusText = 'Listening...';
      _recognizedText = '';
    });

    await _voiceService.speak('How can I help you?');

    await _voiceService.startListening(
      onResult: (recognizedWords) {
        debugPrint('Final result: $recognizedWords');
        if (recognizedWords.isNotEmpty) {
          _retryCount = 0; // Reset retry count on successful recognition
          _processVoiceCommand(recognizedWords);
        } else {
          // Empty result, retry
          _handleEmptyResult();
        }
      },
      onPartialResult: (partialWords) {
        if (mounted) {
          setState(() {
            _recognizedText = partialWords;
            _statusText = 'Recognizing...';
          });
        }
      },
      onError: (error) {
        debugPrint('Recognition error: $error');
        _handleRecognitionError(error);
      },
    );
  }

  Future<void> _handleEmptyResult() async {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      setState(() {
        _statusText = 'Didn\'t catch that. Please try again...';
      });

      await _voiceService.speak('I didn\'t hear anything. Please speak again.');
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted && _isListening) {
        // Restart listening
        await _voiceService.stopListening();
        await Future.delayed(const Duration(milliseconds: 500));
        _startListening();
      }
    } else {
      _retryCount = 0;
      await _voiceService.speak(
        'I couldn\'t hear you clearly. Please try again.',
      );
      _stopListening();
    }
  }

  Future<void> _handleRecognitionError(String error) async {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      setState(() {
        _statusText = 'Error occurred. Retrying...';
      });

      debugPrint('Retry attempt $_retryCount of $_maxRetries');
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted && _isListening) {
        // Restart listening
        await _voiceService.stopListening();
        await Future.delayed(const Duration(milliseconds: 500));
        _startListening();
      }
    } else {
      _retryCount = 0;
      setState(() {
        _statusText = 'Voice recognition error';
      });
      await _voiceService.speak(
        'Sorry, voice recognition encountered an error.',
      );
      _stopListening();
    }
  }

  Future<void> _stopListening() async {
    await _voiceService.stopListening();
    setState(() {
      _isListening = false;
      _statusText = '';
      _recognizedText = '';
      _retryCount = 0; // Reset retry count
    });
  }

  void _processVoiceCommand(String command) async {
    final navigationInfo = _voiceService.parseCommand(command);

    if (navigationInfo != null) {
      final route = navigationInfo['route']!;
      final title = navigationInfo['title']!;

      setState(() {
        _statusText = 'Opening $title...';
      });

      await _voiceService.speak('Opening $title');

      // Wait a moment for TTS to complete
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        _navigateToPage(route, title);
      }

      _stopListening();
    } else {
      // Command not recognized, offer to retry
      if (_retryCount < _maxRetries) {
        _retryCount++;
        setState(() {
          _statusText = 'Command not recognized. Try again...';
        });

        await _voiceService.speak(
          'Sorry, I didn\'t understand. Please say the command again.',
        );

        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted && _isListening) {
          // Restart listening for another attempt
          await _voiceService.stopListening();
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() {
            _statusText = 'Listening...';
            _recognizedText = '';
          });
          _startListening();
        }
      } else {
        // Max retries reached, show help
        _retryCount = 0;
        setState(() {
          _statusText = 'Command not recognized';
        });

        await _voiceService.speak(
          'I still didn\'t understand. Let me show you the available commands.',
        );

        // Show help dialog
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _showHelpDialog();
        }
        _stopListening();
      }
    }
  }

  void _navigateToPage(String route, String title) {
    Widget? page;

    switch (route) {
      case '/location-recommendation':
        page = const LocationRecommendationPage();
        break;
      case '/soil-recommendation':
        page = const SoilRecommendationPage();
        break;
      case '/professional-advisor':
        page = const ProfessionalAdvisorPage();
        break;
      case '/government-schemes':
        page = const GovernmentSchemesPage();
        break;
      case '/weather-forecast':
        page = const WeatherForecastPage();
        break;
      case '/disease-detection':
        page = const DiseaseDetectionPage();
        break;
      case '/market-analysis':
        page = const MarketAnalysisPage();
        break;
      case '/profit-loss-calculator':
        page = const ProfitLossCalculatorPage();
        break;
      case '/profile':
        page = const ProfilePage();
        break;
      case '/home':
        // Pop back to home
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
    }

    if (page != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => page!));
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.mic, color: Color(0xFF2BC24A)),
            const SizedBox(width: 8),
            Text(
              'Voice Commands',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            _voiceService.getHelpText(),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Restart listening when user wants to retry
              _retryCount = 0;
              _startListening();
            },
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                color: const Color(0xFF008575),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it!',
              style: GoogleFonts.poppins(
                color: const Color(0xFF2BC24A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: const Color(0xFF2BC24A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status text (if listening)
        if (_isListening)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                Text(
                  _statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2BC24A),
                  ),
                ),
                if (_recognizedText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '"$_recognizedText"',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

        // Voice button with glow animation
        Stack(
          alignment: Alignment.center,
          children: [
            // Glowing effect when listening
            if (_isListening)
              AvatarGlow(
                glowColor: const Color(0xFF2BC24A),
                glowShape: BoxShape.circle,
                animate: _isListening,
                curve: Curves.fastOutSlowIn,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                ),
              ),

            // Main button
            GestureDetector(
              onTap: _toggleListening,
              onLongPress: _showHelpDialog,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? const Color(0xFF2BC24A)
                      : const Color(0xFF008575),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isListening
                                  ? const Color(0xFF2BC24A)
                                  : const Color(0xFF008575))
                              .withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),

        // Help hint
        if (!_isListening)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Tap to speak • Long press for help',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }
}
