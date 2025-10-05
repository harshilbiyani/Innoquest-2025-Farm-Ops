import 'dart:io';
import 'package:http/http.dart' as http;

class NetworkService {
  static String? _cachedBackendUrl;
  static String? _cachedDeviceIp;

  /// Get the device's local IP address
  static Future<String?> getDeviceIpAddress() async {
    if (_cachedDeviceIp != null) {
      return _cachedDeviceIp;
    }

    try {
      // Get all network interfaces
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // Look for the first non-loopback IP address
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Skip loopback addresses (127.0.0.1)
          if (!addr.isLoopback) {
            _cachedDeviceIp = addr.address;
            print('📱 Device IP found: ${addr.address}');
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('❌ Error getting device IP: $e');
    }
    return null;
  }

  /// Detect the backend URL by trying different possible addresses
  static Future<String> detectBackendUrl({int port = 5000}) async {
    // Return cached URL if available
    if (_cachedBackendUrl != null) {
      print('✅ Using cached backend URL: $_cachedBackendUrl');
      return _cachedBackendUrl!;
    }

    print('🔍 Detecting backend server...');

    // Get device IP to generate possible backend IPs
    final deviceIp = await getDeviceIpAddress();

    // List of possible backend URLs to try
    final possibleUrls = <String>[];

    // 1. Try common emulator/simulator addresses first
    possibleUrls.add('http://10.0.2.2:$port'); // Android emulator
    possibleUrls.add('http://localhost:$port'); // iOS simulator / Desktop
    possibleUrls.add('http://127.0.0.1:$port'); // Local machine

    // 2. If we have device IP, generate possible backend IPs in same subnet
    if (deviceIp != null) {
      final parts = deviceIp.split('.');
      if (parts.length == 4) {
        final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

        // Common IPs in the subnet to try
        final commonLastOctets = [
          1,
          100,
          101,
          124,
          137,
        ]; // Router and common PC IPs

        for (var lastOctet in commonLastOctets) {
          possibleUrls.add('http://$subnet.$lastOctet:$port');
        }

        // Also try scanning a range of IPs in the subnet (optional, can be slow)
        // This is commented out by default to avoid delays
        // for (int i = 1; i < 255; i++) {
        //   possibleUrls.add('http://$subnet.$i:$port');
        // }
      }
    }

    // Remove duplicates while preserving order
    final uniqueUrls = possibleUrls.toSet().toList();

    print('🔍 Testing ${uniqueUrls.length} possible backend URLs...');

    // Try each URL with a timeout
    for (var url in uniqueUrls) {
      try {
        print('   Testing: $url');
        final response = await http
            .get(Uri.parse('$url/api/health'))
            .timeout(
              const Duration(seconds: 2),
              onTimeout: () =>
                  http.Response('Timeout', HttpStatus.requestTimeout),
            );

        if (response.statusCode == 200 || response.statusCode == 404) {
          // 404 is also acceptable as it means server is responding
          // (health endpoint might not exist, but server is there)
          _cachedBackendUrl = url;
          print('✅ Backend server found at: $url');
          return url;
        }
      } catch (e) {
        // Silently continue to next URL
        continue;
      }
    }

    // If no backend found, use default fallback
    final fallbackUrl = 'http://192.168.137.124:$port';
    print('⚠️  No backend server detected, using fallback: $fallbackUrl');
    print('💡 Make sure your backend server is running and accessible');

    _cachedBackendUrl = fallbackUrl;
    return fallbackUrl;
  }

  /// Force refresh the backend URL detection
  static Future<String> refreshBackendUrl({int port = 5000}) async {
    _cachedBackendUrl = null;
    _cachedDeviceIp = null;
    return await detectBackendUrl(port: port);
  }

  /// Clear cached URLs (useful for testing or when network changes)
  static void clearCache() {
    _cachedBackendUrl = null;
    _cachedDeviceIp = null;
    print('🔄 Network cache cleared');
  }

  /// Check if a specific URL is reachable
  static Future<bool> isUrlReachable(String url) async {
    try {
      final response = await http
          .get(Uri.parse('$url/api/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      return false;
    }
  }

  /// Check if chatbot service is available at URL
  static Future<bool> isChatbotAvailable(String url) async {
    try {
      // Try both /health and /chat endpoints
      final healthResponse = await http
          .get(Uri.parse('$url/health'))
          .timeout(const Duration(seconds: 3));

      if (healthResponse.statusCode == 200) {
        return true;
      }

      // Try chat endpoint with a test message
      final chatResponse = await http
          .post(
            Uri.parse('$url/chat'),
            headers: {'Content-Type': 'application/json'},
            body: '{"message": "test"}',
          )
          .timeout(const Duration(seconds: 3));

      return chatResponse.statusCode == 200 || chatResponse.statusCode == 400;
    } catch (e) {
      return false;
    }
  }

  /// Get network info for debugging
  static Future<Map<String, dynamic>> getNetworkInfo() async {
    final deviceIp = await getDeviceIpAddress();
    final backendUrl = _cachedBackendUrl ?? 'Not detected yet';

    return {
      'deviceIp': deviceIp ?? 'Not found',
      'backendUrl': backendUrl,
      'cached': _cachedBackendUrl != null,
    };
  }
}
