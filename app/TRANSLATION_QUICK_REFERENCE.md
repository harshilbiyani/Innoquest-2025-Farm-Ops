# 🚀 Quick Reference - Multi-Language Usage

## Import Statement (Add to every page)
```dart
import 'services/localization_service.dart';
```

## Basic Usage Pattern
```dart
// Get localizations
final loc = context.localizations;

// Use in widgets
Text(loc.keyName)
```

## Common Translations Quick Reference

### Navigation & Actions
```dart
loc.home                // Home / होम / होम
loc.profile             // Profile / प्रोफ़ाइल / प्रोफाइल
loc.logout              // Logout / लॉगआउट / लॉगआउट
loc.chatbot             // Chatbot / चैटबॉट / चॅटबॉट
loc.save                // Save / सहेजें / सेव्ह करा
loc.cancel              // Cancel / रद्द करें / रद्द करा
loc.submit              // Submit / जमा करें / सबमिट करा
loc.edit                // Edit / संपादित करें / संपादित करा
loc.delete              // Delete / हटाएं / हटवा
loc.next                // Next / आगे / पुढे
loc.yes                 // Yes / हाँ / होय
loc.no                  // No / नहीं / नाही
loc.close               // Close / बंद करें / बंद करा
loc.retry               // Retry / पुनः प्रयास करें / पुन्हा प्रयत्न करा
```

### Status Messages
```dart
loc.loading             // Loading... / लोड हो रहा है... / लोड होत आहे...
loc.error               // Error / त्रुटि / त्रुटी
loc.success             // Success / सफलता / यशस्वी
```

### Authentication
```dart
loc.enterMobileNumber   // Enter your mobile number
loc.mobileNumber        // Mobile Number
loc.getOTP              // Get OTP
loc.verifyOTP           // Verify OTP
loc.verify              // Verify
loc.resendOTP           // Resend OTP
```

### Home Features
```dart
loc.locationBasedRecommendation     // Location Based Recommendation
loc.soilBasedCropRecommendation     // Soil Based Crop Recommendation
loc.professionalAdvisor             // Professional Advisor
loc.governmentSchemes               // Government Schemes
loc.weatherForecast                 // Weather Forecast
loc.diseaseDetection                // Disease Detection
loc.marketAnalysis                  // Market Analysis
loc.profitLossCalculator            // Profit/Loss Calculator
```

### Profile
```dart
loc.myProfile           // My Profile
loc.name                // Name
loc.location            // Location
loc.landSize            // Land Size
loc.editProfile         // Edit Profile
loc.saveProfile         // Save Profile
```

### Soil Parameters
```dart
loc.nitrogen            // Nitrogen / नाइट्रोजन / नायट्रोजन
loc.phosphorus          // Phosphorus / फास्फोरस / फॉस्फरस
loc.potassium           // Potassium / पोटैशियम / पोटॅशियम
loc.temperature         // Temperature / तापमान / तापमान
loc.humidity            // Humidity / आर्द्रता / आर्द्रता
loc.ph                  // pH Level / पीएच स्तर / पीएच पातळी
loc.rainfall            // Rainfall / वर्षा / पाऊस
```

### Weather
```dart
loc.currentWeather      // Current Weather
loc.forecast            // Forecast
loc.feelsLike           // Feels Like
loc.wind                // Wind
loc.pressure            // Pressure
```

### Market
```dart
loc.currentPrices       // Current Prices
loc.priceHistory        // Price History
loc.cropName            // Crop Name
loc.price               // Price
```

### Disease Detection
```dart
loc.uploadImage         // Upload Image
loc.takePhoto           // Take Photo
loc.selectFromGallery   // Select from Gallery
loc.analyzing           // Analyzing...
loc.diseaseDetected     // Disease Detected
loc.treatment           // Treatment
```

### Chatbot
```dart
loc.typeMessage         // Type a message...
loc.listening           // Listening...
loc.speaking            // Speaking...
```

## Real Examples

### Example 1: Button
```dart
ElevatedButton(
  onPressed: () {},
  child: Text(context.localizations.submit),
)
```

### Example 2: Dialog
```dart
AlertDialog(
  title: Text(context.localizations.logout),
  actions: [
    TextButton(
      child: Text(context.localizations.cancel),
      onPressed: () => Navigator.pop(context),
    ),
    ElevatedButton(
      child: Text(context.localizations.yes),
      onPressed: () {
        // Logout logic
      },
    ),
  ],
)
```

### Example 3: Form Field
```dart
TextField(
  decoration: InputDecoration(
    labelText: context.localizations.name,
    hintText: context.localizations.name,
  ),
)
```

### Example 4: AppBar
```dart
AppBar(
  title: Text(context.localizations.myProfile),
)
```

### Example 5: SnackBar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(context.localizations.success),
  ),
)
```

## Language Codes
- English: `'en'`
- Hindi: `'hi'`
- Marathi: `'mr'`

## Change Language Programmatically
```dart
import 'package:provider/provider.dart';
import 'services/localization_service.dart';

// In your function
final localizationService = Provider.of<LocalizationService>(
  context, 
  listen: false
);
await localizationService.changeLanguage('hi'); // or 'en', 'mr'
```

## Check Current Language
```dart
final currentLang = Provider.of<LocalizationService>(context).locale.languageCode;
// Returns: 'en', 'hi', or 'mr'
```

## Get Current Language Name
```dart
final languageName = Provider.of<LocalizationService>(context).currentLanguageName;
// Returns: 'English', 'हिंदी', or 'मराठी'
```

---
**Tip**: Keep this file open while updating pages for quick reference! 📖
