import 'dart:convert';
import 'package:http/http.dart' as http;
import 'network_service.dart';

class ApiService {
  // Dynamic backend URL - automatically detected based on network configuration
  // The NetworkService will try multiple possible addresses:
  // - Android emulator: 10.0.2.2
  // - iOS simulator/Desktop: localhost/127.0.0.1
  // - Physical device: Auto-detect IPs in same subnet
  static String? _baseUrl;

  /// Get the base URL, detecting it automatically if not already set
  static Future<String> getBaseUrl() async {
    if (_baseUrl != null) {
      return _baseUrl!;
    }
    _baseUrl = await NetworkService.detectBackendUrl(port: 5000);
    return _baseUrl!;
  }

  /// Force refresh the backend URL (useful when network changes)
  static Future<void> refreshBackendUrl() async {
    _baseUrl = null;
    _baseUrl = await NetworkService.refreshBackendUrl(port: 5000);
  }

  /// Manually set the backend URL (useful for testing or specific configurations)
  static void setBaseUrl(String url) {
    _baseUrl = url;
    print('✅ Backend URL manually set to: $url');
  }

  /// Get current backend URL without triggering detection
  static String? getCurrentBaseUrl() {
    return _baseUrl;
  }

  /// Check if user exists in database
  static Future<Map<String, dynamic>> checkUser(String mobilePhone) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/check-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile_phone': mobilePhone}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'exists': data['exists'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to check user',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Create a new user account
  static Future<Map<String, dynamic>> createUser(String mobilePhone) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/create-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile_phone': mobilePhone}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'User created successfully',
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create user',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Send OTP to mobile number
  static Future<Map<String, dynamic>> sendOtp(String mobilePhone) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile_phone': mobilePhone}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'otp': data['otp'] ?? '', // Only available in testing mode
          'testing_mode': data['testing_mode'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Verify OTP and create/login user
  static Future<Map<String, dynamic>> verifyOtp(
    String mobilePhone,
    String otp,
  ) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile_phone': mobilePhone, 'otp': otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get all users (for testing purposes)
  static Future<Map<String, dynamic>> getUsers() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'users': data['users'],
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch users',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== CROP RECOMMENDATION APIs ====================

  /// Get list of all states
  static Future<Map<String, dynamic>> getStates() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/crop/states'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'states': List<String>.from(data['states']),
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch states',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get list of districts for a state
  static Future<Map<String, dynamic>> getDistricts(String state) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/crop/districts/${Uri.encodeComponent(state)}'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'districts': List<String>.from(data['districts']),
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch districts',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get list of blocks for a district
  static Future<Map<String, dynamic>> getBlocks(
    String state,
    String district,
  ) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/crop/blocks/${Uri.encodeComponent(state)}/${Uri.encodeComponent(district)}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'blocks': List<String>.from(data['blocks']),
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch blocks',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get list of villages for a block
  static Future<Map<String, dynamic>> getVillages(
    String state,
    String district,
    String block,
  ) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/crop/villages/${Uri.encodeComponent(state)}/${Uri.encodeComponent(district)}/${Uri.encodeComponent(block)}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'villages': List<String>.from(data['villages']),
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch villages',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get crop suitability for a specific location
  static Future<Map<String, dynamic>> getCropSuitability({
    required String state,
    required String district,
    required String block,
    required String village,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/crop/suitability'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'state': state,
          'district': district,
          'block': block,
          'village': village,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'location': data['location'],
          'crops': data['crops'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch crop suitability',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get attribute options for soil recommendation form
  static Future<Map<String, dynamic>> getCropAttributes() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/crop/attributes'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'attributes': data['attributes']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch attributes',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Evaluate crops based on soil and climate data
  static Future<Map<String, dynamic>> evaluateCrops(
    Map<String, String> soilData,
  ) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/crop/evaluate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(soilData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'crops': data['crops'],
          'grouped': data['grouped'],
          'summary': data['summary'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to evaluate crops',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Generate growth timeline for a crop
  static Future<Map<String, dynamic>> generateGrowthTimeline({
    required String cropName,
    Map<String, String>? soilData,
    Map<String, String>? locationData,
    String? soilType,
  }) async {
    try {
      final baseUrl = await getBaseUrl();

      Map<String, dynamic> requestBody = {'crop_name': cropName.toLowerCase()};

      if (soilType != null) {
        requestBody['soil_type'] = soilType;
      }

      if (soilData != null) {
        requestBody['soil_data'] = soilData;
      }

      if (locationData != null) {
        requestBody['location_data'] = locationData;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/crop/growth-timeline'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'timeline': data['timeline'],
          'soil_advice': data['soil_advice'],
          'crop_name': data['crop_name'],
          'soil_type': data['soil_type'],
          'total_days': data['total_days'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to generate timeline',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get water consumption data for a crop
  static Future<Map<String, dynamic>> getWaterConsumption({
    required String cropName,
    Map<String, String>? soilData,
    Map<String, String>? locationData,
  }) async {
    try {
      final baseUrl = await getBaseUrl();

      Map<String, dynamic> requestBody = {'crop_name': cropName.toLowerCase()};

      if (soilData != null) {
        requestBody['soil_data'] = soilData;
      }

      if (locationData != null) {
        requestBody['location_data'] = locationData;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/crop/water-consumption'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'total_water': data['total_water'],
          'stages': data['stages'],
          'irrigation_tips': data['irrigation_tips'],
          'crop_name': data['crop_name'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get water consumption data',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== CHATBOT APIs ====================

  /// Send a message to the agricultural chatbot
  static Future<Map<String, dynamic>> sendChatMessage(
    String message, {
    String? userId,
  }) async {
    try {
      final baseUrl = await getBaseUrl();

      Map<String, dynamic> requestBody = {'message': message.trim()};

      if (userId != null) {
        requestBody['user_id'] = userId;
      }

      print('🤖 Sending message to chatbot at $baseUrl/chat');

      final response = await http
          .post(
            Uri.parse('$baseUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Chatbot response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'response': data['response'],
          'timestamp': data['timestamp'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get chatbot response',
        };
      }
    } catch (e) {
      print('❌ Chatbot API error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Check chatbot health status
  static Future<bool> checkChatbotHealth() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Chatbot health check failed: $e');
      return false;
    }
  }
}
