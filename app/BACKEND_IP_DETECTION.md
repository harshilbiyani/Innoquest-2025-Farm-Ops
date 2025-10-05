# Automatic Backend IP Detection Feature

## Overview
The FarmOps app now automatically detects the backend server IP address, eliminating the need to manually change hardcoded IP addresses when your network configuration changes.

## How It Works

### NetworkService
The new `NetworkService` class (`lib/services/network_service.dart`) provides:

1. **Automatic Device IP Detection**: Finds the device's local IP address
2. **Smart Backend Detection**: Tests multiple possible backend URLs to find the active server
3. **Caching**: Stores the detected URL to avoid repeated scans
4. **Flexibility**: Allows manual override when needed

### Detection Strategy
The service tries backend URLs in this order:
1. Common emulator/simulator addresses:
   - `http://10.0.2.2:5000` (Android emulator)
   - `http://localhost:5000` (iOS simulator/Desktop)
   - `http://127.0.0.1:5000` (Local machine)

2. Device subnet IPs (if device IP is detected):
   - Common router/PC IPs in same subnet (e.g., `192.168.1.1`, `192.168.1.100`, etc.)

3. Fallback to previous default: `http://192.168.137.124:5000`

## Updated Services

All API services now use dynamic IP detection:
- ✅ `ApiService` (OTP and user management)
- ✅ `MarketAnalysisService`
- ✅ `DiseaseDetectionService`

## Usage

### Automatic Mode (Default)
No changes needed! The app will automatically detect the backend:
```dart
// Just call API methods as before
final result = await ApiService.sendOtp(phoneNumber);
```

### Manual Override (Optional)
If you need to specify a custom backend URL:
```dart
// Set custom backend URL
ApiService.setBaseUrl('http://192.168.1.100:5000');

// For other services
MarketAnalysisService.setBaseUrl('http://192.168.1.100:5000/api/market');
```

### Force Refresh
If network changes and you need to re-detect:
```dart
await ApiService.refreshBackendUrl();
await NetworkService.refreshBackendUrl();
```

### Debug Information
Get current network configuration:
```dart
final networkInfo = await NetworkService.getNetworkInfo();
print('Device IP: ${networkInfo['deviceIp']}');
print('Backend URL: ${networkInfo['backendUrl']}');
```

## Benefits

1. **No More Manual IP Changes**: Works automatically across different networks
2. **OTP Works Everywhere**: No more OTP failures due to IP mismatch
3. **Development Friendly**: Works seamlessly on emulators, simulators, and physical devices
4. **Production Ready**: Easy to configure for production servers

## Backend Requirements

For automatic detection to work optimally, add a health check endpoint:
```python
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'ok'}), 200
```

Note: The detection also accepts 404 responses, so it works even without this endpoint!

## Troubleshooting

### If backend isn't detected:
1. Ensure your backend server is running
2. Check that your device and PC are on the same network
3. Verify firewall isn't blocking connections
4. Check console logs for detection attempts

### Console Output:
The service provides detailed logs:
```
🔍 Detecting backend server...
🔍 Testing 8 possible backend URLs...
   Testing: http://10.0.2.2:5000
   Testing: http://localhost:5000
   ...
✅ Backend server found at: http://192.168.1.100:5000
```

### Force Manual Configuration:
If automatic detection fails, manually set the backend URL in your code or add it to app settings.

## Migration Notes

If you had hardcoded IPs in your code:
- **Old**: `static const String baseUrl = 'http://192.168.137.124:5000';`
- **New**: Automatically detected! No hardcoded IPs needed.

The app will automatically detect and use the correct IP address based on your network configuration.
