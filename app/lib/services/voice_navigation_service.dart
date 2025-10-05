import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service to handle voice recognition and navigation commands
class VoiceNavigationService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;
  String _lastWords = '';

  // Navigation command mappings
  final Map<String, Map<String, String>> _navigationCommands = {
    // Location Recommendation
    'location': {
      'route': '/location-recommendation',
      'title': 'Location Based Recommendation',
    },
    'location recommendation': {
      'route': '/location-recommendation',
      'title': 'Location Based Recommendation',
    },
    'location based': {
      'route': '/location-recommendation',
      'title': 'Location Based Recommendation',
    },
    'recommend location': {
      'route': '/location-recommendation',
      'title': 'Location Based Recommendation',
    },

    // Soil Recommendation
    'soil': {
      'route': '/soil-recommendation',
      'title': 'Soil Based Crop Recommendation',
    },
    'soil recommendation': {
      'route': '/soil-recommendation',
      'title': 'Soil Based Crop Recommendation',
    },
    'soil based': {
      'route': '/soil-recommendation',
      'title': 'Soil Based Crop Recommendation',
    },
    'crop recommendation': {
      'route': '/soil-recommendation',
      'title': 'Soil Based Crop Recommendation',
    },

    // Professional Advisor / Chatbot
    'advisor': {
      'route': '/professional-advisor',
      'title': 'Professional Advisor',
    },
    'professional advisor': {
      'route': '/professional-advisor',
      'title': 'Professional Advisor',
    },
    'chatbot': {
      'route': '/professional-advisor',
      'title': 'Professional Advisor',
    },
    'chat': {'route': '/professional-advisor', 'title': 'Professional Advisor'},
    'advisor chat': {
      'route': '/professional-advisor',
      'title': 'Professional Advisor',
    },

    // Government Schemes
    'government': {
      'route': '/government-schemes',
      'title': 'Government Schemes',
    },
    'government schemes': {
      'route': '/government-schemes',
      'title': 'Government Schemes',
    },
    'schemes': {'route': '/government-schemes', 'title': 'Government Schemes'},
    'subsidy': {'route': '/government-schemes', 'title': 'Government Schemes'},

    // Weather Forecast
    'weather': {'route': '/weather-forecast', 'title': 'Weather Forecast'},
    'weather forecast': {
      'route': '/weather-forecast',
      'title': 'Weather Forecast',
    },
    'forecast': {'route': '/weather-forecast', 'title': 'Weather Forecast'},
    'climate': {'route': '/weather-forecast', 'title': 'Weather Forecast'},

    // Disease Detection
    'disease': {'route': '/disease-detection', 'title': 'Disease Detection'},
    'disease detection': {
      'route': '/disease-detection',
      'title': 'Disease Detection',
    },
    'plant disease': {
      'route': '/disease-detection',
      'title': 'Disease Detection',
    },
    'crop disease': {
      'route': '/disease-detection',
      'title': 'Disease Detection',
    },

    // Market Analysis
    'market': {'route': '/market-analysis', 'title': 'Market Analysis'},
    'market analysis': {
      'route': '/market-analysis',
      'title': 'Market Analysis',
    },
    'price': {'route': '/market-analysis', 'title': 'Market Analysis'},
    'market price': {'route': '/market-analysis', 'title': 'Market Analysis'},

    // Profit/Loss Calculator
    'profit': {
      'route': '/profit-loss-calculator',
      'title': 'Profit/Loss Calculator',
    },
    'loss': {
      'route': '/profit-loss-calculator',
      'title': 'Profit/Loss Calculator',
    },
    'calculator': {
      'route': '/profit-loss-calculator',
      'title': 'Profit/Loss Calculator',
    },
    'profit loss': {
      'route': '/profit-loss-calculator',
      'title': 'Profit/Loss Calculator',
    },
    'profit loss calculator': {
      'route': '/profit-loss-calculator',
      'title': 'Profit/Loss Calculator',
    },

    // Profile
    'profile': {'route': '/profile', 'title': 'Profile'},
    'my profile': {'route': '/profile', 'title': 'Profile'},

    // Home
    'home': {'route': '/home', 'title': 'Home'},
    'go home': {'route': '/home', 'title': 'Home'},
    'main page': {'route': '/home', 'title': 'Home'},
  };

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech status: $status'),
      );

      // Initialize TTS
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      debugPrint('Voice navigation service initialized: $_speechEnabled');
      return _speechEnabled;
    } catch (e) {
      debugPrint('Error initializing voice service: $e');
      return false;
    }
  }

  /// Check if speech recognition is available
  bool get isAvailable => _speechEnabled;

  /// Get the last recognized words
  String get lastWords => _lastWords;

  /// Start listening for voice commands
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    Function(String)? onError,
  }) async {
    if (!_speechEnabled) {
      debugPrint('Speech not enabled');
      if (onError != null) {
        onError('Speech recognition not enabled');
      }
      return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords.toLowerCase();
          debugPrint('Recognized: $_lastWords');

          if (result.finalResult) {
            onResult(_lastWords);
          } else if (onPartialResult != null) {
            onPartialResult(_lastWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false, // Don't cancel on error, handle it gracefully
        listenMode: ListenMode.confirmation,
        onSoundLevelChange: (level) {
          // Optional: can be used for visual feedback
          debugPrint('Sound level: $level');
        },
      );
    } catch (e) {
      debugPrint('Error starting listening: $e');
      if (onError != null) {
        onError(e.toString());
      }
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  /// Check if currently listening
  bool get isListening => _speechToText.isListening;

  /// Parse voice command and return navigation info
  Map<String, String>? parseCommand(String command) {
    String normalizedCommand = command.toLowerCase().trim();

    // Direct match
    if (_navigationCommands.containsKey(normalizedCommand)) {
      return _navigationCommands[normalizedCommand];
    }

    // Partial match - find if command contains any keywords
    for (var entry in _navigationCommands.entries) {
      String keyword = entry.key;
      // Check if the command contains the keyword
      if (normalizedCommand.contains(keyword)) {
        return entry.value;
      }
    }

    // Check for "go to" or "open" patterns
    if (normalizedCommand.startsWith('go to ') ||
        normalizedCommand.startsWith('open ') ||
        normalizedCommand.startsWith('show ')) {
      String target = normalizedCommand
          .replaceFirst('go to ', '')
          .replaceFirst('open ', '')
          .replaceFirst('show ', '')
          .trim();

      for (var entry in _navigationCommands.entries) {
        if (target.contains(entry.key) || entry.key.contains(target)) {
          return entry.value;
        }
      }
    }

    return null;
  }

  /// Speak text using TTS
  Future<void> speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  /// Get all available commands for help
  List<String> getAvailableCommands() {
    return _navigationCommands.keys.toList();
  }

  /// Get help text
  String getHelpText() {
    return '''
Voice Navigation Commands:

📍 Location: "location", "location recommendation"
🌱 Soil: "soil", "crop recommendation"
👨‍🌾 Advisor: "advisor", "chatbot", "chat"
🏛️ Government: "government schemes", "subsidy"
🌤️ Weather: "weather", "forecast"
🦠 Disease: "disease detection", "plant disease"
💰 Market: "market", "price", "market analysis"
📊 Calculator: "profit loss calculator"
👤 Profile: "profile", "my profile"
🏠 Home: "home", "go home"

Try saying: "Go to weather" or "Open chatbot"
    ''';
  }

  /// Dispose resources
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
  }
}
