# Quick Start Guide - Auto IP Detection

## What Changed?

Your FarmOps app now **automatically detects** the backend server IP address! No more manual IP changes when your network changes.

## Immediate Benefits

✅ **OTP will work** regardless of network changes  
✅ **No manual IP configuration** needed  
✅ **Works on emulators and physical devices** automatically  

## How It Works

1. **On first API call**, the app automatically:
   - Detects your device's IP address
   - Scans common backend URLs
   - Finds and connects to your backend server
   - Caches the URL for future use

2. **Smart detection tries**:
   - Android emulator: `10.0.2.2:5000`
   - iOS simulator: `localhost:5000`
   - Physical devices: Auto-detects IPs in your network
   - Falls back to: `192.168.137.124:5000`

## Testing Right Now

### Option 1: Just Run Your App
```bash
flutter run
```
- Use OTP login as normal
- Check console for detection logs
- It will automatically find your backend!

### Option 2: Test with Diagnostics Page
Add this button to your home page temporarily:

```dart
// Add to home_page.dart or any page
FloatingActionButton(
  child: Icon(Icons.network_check),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NetworkDiagnosticsPage(),
      ),
    );
  },
)
```

Then:
1. Run the app
2. Click the network diagnostics button
3. See your detected IPs
4. Test connection
5. Done!

## Console Output to Expect

When you run the app and trigger any API call, you'll see:

```
🔍 Detecting backend server...
📱 Device IP found: 192.168.1.45
🔍 Testing 8 possible backend URLs...
   Testing: http://10.0.2.2:5000
   Testing: http://localhost:5000
   Testing: http://127.0.0.1:5000
   Testing: http://192.168.1.1:5000
   Testing: http://192.168.1.100:5000
   Testing: http://192.168.1.101:5000
✅ Backend server found at: http://192.168.1.100:5000
```

## If Something Goes Wrong

### Backend Not Detected?
```dart
// Manually set the backend URL
import 'package:farmops_flutter/services/api_service.dart';

void main() {
  // Set before running app
  ApiService.setBaseUrl('http://YOUR_PC_IP:5000');
  runApp(MyApp());
}
```

### Network Changed?
The app will detect it automatically on next API call, but you can force refresh:
```dart
await ApiService.refreshBackendUrl();
```

### Still Having Issues?
1. Make sure your backend is running
2. Check both devices are on same WiFi
3. Disable firewall temporarily to test
4. Use the Network Diagnostics page to debug

## Backend Requirements

### Optional: Add Health Check Endpoint
For optimal detection, add this to your Flask backend:

```python
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'ok'}), 200
```

**Note**: Not required! Detection works even without this endpoint.

## Quick Test Checklist

- [ ] Backend server is running (`python main.py`)
- [ ] Phone/emulator and PC on same network
- [ ] Run `flutter run`
- [ ] Try OTP login
- [ ] Check console for detection logs
- [ ] OTP works! ✅

## Files to Review

- `lib/services/network_service.dart` - Core auto-detection logic
- `lib/services/api_service.dart` - Updated to use dynamic URLs
- `lib/network_diagnostics_page.dart` - Diagnostics UI
- `BACKEND_IP_DETECTION.md` - Full documentation
- `CHANGES_SUMMARY.md` - Detailed changes

## Need Help?

Check the logs! The auto-detection provides detailed console output showing:
- Which IPs are being tested
- Which one succeeded
- Any errors encountered

Happy coding! 🚀
