import 'dart:convert';
import 'package:http/http.dart' as http;
import 'network_service.dart';

class MarketAnalysisService {
  // Dynamic backend URL - automatically detected
  static String? _baseUrl;

  /// Get the base URL for market analysis API
  static Future<String> _getBaseUrl() async {
    if (_baseUrl != null) {
      return _baseUrl!;
    }
    final backendUrl = await NetworkService.detectBackendUrl(port: 5000);
    _baseUrl = '$backendUrl/api/market';
    return _baseUrl!;
  }

  /// Manually set the backend URL (useful for testing)
  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// Fetch all available states for market analysis
  static Future<List<String>> fetchStates() async {
    try {
      final baseUrl = await _getBaseUrl();
      print('🌐 Fetching states from: $baseUrl/data');
      final response = await http
          .get(
            Uri.parse('$baseUrl/data'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print(
        '📦 Response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final states = data.keys.toList()..sort();
        print('✅ Successfully fetched ${states.length} states');
        return states;
      } else {
        throw Exception('Failed to load states: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching states: $e');
      rethrow;
    }
  }

  /// Fetch mandis (markets) for a specific state
  static Future<List<String>> fetchMandis(String state) async {
    try {
      final baseUrl = await _getBaseUrl();
      print('🌐 Fetching mandis for state: $state');
      final response = await http
          .get(
            Uri.parse('$baseUrl/mandis/${Uri.encodeComponent(state)}'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      print('📡 Mandis response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        print('✅ Successfully fetched ${data.length} mandis');
        return data.cast<String>()..sort();
      } else {
        throw Exception('Failed to load mandis: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching mandis: $e');
      rethrow;
    }
  }

  /// Fetch crops available in a specific mandi of a state
  static Future<List<String>> fetchCrops(String state, String mandi) async {
    try {
      final baseUrl = await _getBaseUrl();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/crops/${Uri.encodeComponent(state)}/${Uri.encodeComponent(mandi)}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.cast<String>()..sort();
      } else {
        throw Exception('Failed to load crops: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching crops: $e');
      rethrow;
    }
  }

  /// Fetch price data for a specific crop in a mandi
  static Future<Map<String, dynamic>> fetchPrices({
    required String state,
    required String mandi,
    required String crop,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final queryParams = {'state': state, 'mandi': mandi, 'crop': crop};

      final uri = Uri.parse(
        '$baseUrl/prices',
      ).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Check if there's an error in the response
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }

        return data;
      } else if (response.statusCode == 404) {
        throw Exception('No data found for the selected filters');
      } else {
        throw Exception('Failed to load prices: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching prices: $e');
      rethrow;
    }
  }
}
