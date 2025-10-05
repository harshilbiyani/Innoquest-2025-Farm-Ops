import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'network_service.dart';

class DiseaseDetectionService {
  // Dynamic backend URL - automatically detected
  static String? _baseUrl;

  /// Get the base URL for disease detection API
  static Future<String> _getBaseUrl() async {
    if (_baseUrl != null) {
      return _baseUrl!;
    }
    _baseUrl = await NetworkService.detectBackendUrl(port: 5000);
    return _baseUrl!;
  }

  /// Detects disease from an image file
  static Future<DiseaseResult> detectDisease(File imageFile) async {
    try {
      final baseUrl = await _getBaseUrl();
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/detect-disease'),
      );

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DiseaseResult.fromJson(data);
      } else {
        throw Exception('Failed to detect disease: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Disease detection error: $e');
      // Return mock data for demo purposes
      return _getMockResult();
    }
  }

  /// Mock result for testing when backend is not available
  static DiseaseResult _getMockResult() {
    return DiseaseResult(
      diseaseName: 'Late Blight',
      confidence: 87.5,
      description:
          'Late blight is a devastating disease caused by the fungus-like organism Phytophthora infestans. It affects leaves, stems, and tubers, causing dark, water-soaked lesions that rapidly expand.',
      treatment: [
        'Remove and destroy infected plant parts immediately',
        'Apply copper-based fungicides like Bordeaux mixture',
        'Use fungicides containing metalaxyl or mancozeb',
        'Improve air circulation by proper plant spacing',
        'Avoid overhead watering to reduce leaf wetness',
        'Apply preventive sprays during humid weather',
        'Rotate crops to prevent disease buildup',
      ],
      isHealthy: false,
    );
  }
}

/// Model class for disease detection results
class DiseaseResult {
  final String diseaseName;
  final double confidence;
  final String description;
  final List<String> treatment;
  final bool isHealthy;

  DiseaseResult({
    required this.diseaseName,
    required this.confidence,
    required this.description,
    required this.treatment,
    required this.isHealthy,
  });

  factory DiseaseResult.fromJson(Map<String, dynamic> json) {
    return DiseaseResult(
      diseaseName: json['disease_name'] ?? 'Unknown Disease',
      confidence: (json['confidence'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      treatment: List<String>.from(json['treatment'] ?? []),
      isHealthy: json['is_healthy'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disease_name': diseaseName,
      'confidence': confidence,
      'description': description,
      'treatment': treatment,
      'is_healthy': isHealthy,
    };
  }
}
