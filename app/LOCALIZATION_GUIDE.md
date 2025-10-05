# 🌍 Localization Guide - FarmOps App

This guide explains how to use the multi-language support (English, Hindi, and Marathi) in the FarmOps app.

## 📋 Table of Contents
1. [Setup Overview](#setup-overview)
2. [How It Works](#how-it-works)
3. [Using Translations in Your Pages](#using-translations-in-your-pages)
4. [Adding New Translations](#adding-new-translations)
5. [Changing Language at Runtime](#changing-language-at-runtime)

## 🔧 Setup Overview

The localization system has been implemented with the following components:

### Files Created/Modified:
- **`lib/services/localization_service.dart`** - Main localization service with all translations
- **`lib/services/user_preferences.dart`** - Updated to store language preference
- **`lib/language_selection_page.dart`** - Updated to save language choice
- **`lib/main.dart`** - Updated to support localization
- **`pubspec.yaml`** - Added flutter_localizations dependency

### Supported Languages:
- 🇬🇧 English (en)
- 🇮🇳 Hindi (hi)
- 🇮🇳 Marathi (mr)

## 🎯 How It Works

### 1. Language Selection
When the user first opens the app, they are presented with a language selection screen. The selected language is:
- Saved in SharedPreferences
- Remembered across app restarts
- Applied to the entire app

### 2. Language Persistence
The language choice is stored using `SharedPreferences` and is automatically loaded when the app starts.

### 3. Automatic Translation
All UI text uses the localization service to display content in the user's selected language.

## 💻 Using Translations in Your Pages

### Basic Usage

To use translations in any page, you need to import the localization service and use the extension:

```dart
import 'services/localization_service.dart';

// In your build method or any method that has BuildContext:
final loc = context.localizations;

// Use translations:
Text(loc.home)  // Displays: "Home" / "होम" / "होम"
Text(loc.profile)  // Displays: "Profile" / "प्रोफ़ाइल" / "प्रोफाइल"
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/localization_service.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = context.localizations;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.myProfile),
      ),
      body: Column(
        children: [
          Text(loc.name),
          Text(loc.location),
          Text(loc.landSize),
          ElevatedButton(
            onPressed: () {},
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }
}
```

### In Dialogs and Alerts

```dart
showDialog(
  context: context,
  builder: (context) {
    final loc = context.localizations;
    return AlertDialog(
      title: Text(loc.logout),
      content: Text('Are you sure you want to logout?'), // Add this to translations
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            // Logout logic
          },
          child: Text(loc.yes),
        ),
      ],
    );
  },
);
```

### In SnackBars

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(context.localizations.success),
  ),
);
```

## 📝 Available Translations

Here are all the currently available translation keys (from `localization_service.dart`):

### App General
- `appName` - FarmOps
- `selectLanguage` - Please, Select your language!
- `next` - Next
- `english`, `hindi`, `marathi` - Language names

### Login & Authentication
- `enterMobileNumber`, `mobileNumber`, `getOTP`, `termsConditions`
- `verifyOTP`, `enterOTPSent`, `verify`, `resendOTP`

### Home Page Features
- `welcomeBack`, `exploreFeatures`
- `locationBasedRecommendation`
- `soilBasedCropRecommendation`
- `professionalAdvisor`
- `governmentSchemes`
- `weatherForecast`
- `diseaseDetection`
- `marketAnalysis`
- `profitLossCalculator`

### Navigation
- `home`, `profile`, `logout`, `chatbot`

### Common Actions
- `submit`, `cancel`, `save`, `delete`, `edit`
- `loading`, `error`, `success`, `yes`, `no`, `close`, `retry`

### Profile
- `myProfile`, `name`, `location`, `landSize`
- `editProfile`, `saveProfile`

### Location Recommendation
- `locationRecommendation`, `fetchingLocation`
- `getCropRecommendation`, `recommendedCrops`

### Soil Recommendation
- `soilRecommendation`, `nitrogen`, `phosphorus`, `potassium`
- `temperature`, `humidity`, `ph`, `rainfall`

### Weather Forecast
- `weatherForecastTitle`, `currentWeather`, `forecast`
- `feelsLike`, `wind`, `pressure`

### Professional Advisor
- `professionalAdvisorTitle`, `askQuestion`
- `typeYourQuestion`, `send`

### Government Schemes
- `governmentSchemesTitle`, `availableSchemes`, `learnMore`

### Disease Detection
- `diseaseDetectionTitle`, `uploadImage`, `takePhoto`
- `selectFromGallery`, `analyzing`, `diseaseDetected`, `treatment`

### Market Analysis
- `marketAnalysisTitle`, `currentPrices`, `priceHistory`
- `cropName`, `price`

### Profit/Loss Calculator
- `profitLossCalculatorTitle`, `cropCost`, `sellingPrice`
- `calculate`, `profit`, `loss`

### Chatbot
- `chatbotTitle`, `typeMessage`, `listening`, `speaking`

## ➕ Adding New Translations

To add a new translation string:

### Step 1: Add to English Translations
In `lib/services/localization_service.dart`, add to `_englishStrings`:

```dart
const Map<String, String> _englishStrings = {
  // ... existing translations
  'my_new_key': 'My English Text',
};
```

### Step 2: Add to Hindi Translations
Add to `_hindiStrings`:

```dart
const Map<String, String> _hindiStrings = {
  // ... existing translations
  'my_new_key': 'मेरा हिंदी पाठ',
};
```

### Step 3: Add to Marathi Translations
Add to `_marathiStrings`:

```dart
const Map<String, String> _marathiStrings = {
  // ... existing translations
  'my_new_key': 'माझा मराठी मजकूर',
};
```

### Step 4: Add Convenience Getter
In the `AppLocalizations` class:

```dart
class AppLocalizations {
  // ... existing getters
  String get myNewKey => translate('my_new_key');
}
```

### Step 5: Use in Your Code
```dart
final loc = context.localizations;
Text(loc.myNewKey)
```

## 🔄 Changing Language at Runtime

If you want to allow users to change language without logging out:

```dart
import 'package:provider/provider.dart';
import 'services/localization_service.dart';

// In your settings page or language selector:
void changeLanguage(BuildContext context, String languageCode) async {
  final localizationService = Provider.of<LocalizationService>(
    context, 
    listen: false
  );
  await localizationService.changeLanguage(languageCode);
  
  // The entire app will rebuild with new translations
}

// Usage:
ElevatedButton(
  onPressed: () => changeLanguage(context, 'hi'), // Change to Hindi
  child: Text('हिंदी'),
)
```

### Language Codes:
- `'en'` - English
- `'hi'` - Hindi
- `'mr'` - Marathi

## 🎨 Example: Updating a Page with Translations

### Before (Hardcoded English):
```dart
Text('Welcome Back!')
ElevatedButton(
  child: Text('Submit'),
)
```

### After (With Translations):
```dart
import 'services/localization_service.dart';

Text(context.localizations.welcomeBack)
ElevatedButton(
  child: Text(context.localizations.submit),
)
```

## 📱 Testing Different Languages

To test the app in different languages:

1. Run the app
2. On the language selection screen, choose Hindi or Marathi
3. Navigate through the app to see translations
4. To test changing languages, logout and select a different language

## 🐛 Troubleshooting

### Translation not showing
- Make sure you've imported `services/localization_service.dart`
- Verify the translation key exists in all three language maps
- Check that you're using `context.localizations.yourKey`

### App not rebuilding after language change
- Make sure LocalizationService is provided using Provider in main.dart
- Verify that the language change is calling `notifyListeners()`

### Language not persisting
- Check that `flutter_localizations` is added to pubspec.yaml
- Ensure SharedPreferences is working properly
- Verify UserPreferences.saveLanguage() is being called

## 📚 Best Practices

1. **Always use translations** - Never hardcode user-facing text
2. **Keep keys consistent** - Use snake_case for translation keys
3. **Add all three languages** - When adding new translations, update all three language maps
4. **Test all languages** - Test new features in all supported languages
5. **Use descriptive keys** - Make translation keys self-explanatory (e.g., `save_profile` not `btn1`)

## 🔮 Future Enhancements

Potential improvements:
- Add more languages (Punjabi, Bengali, Tamil, etc.)
- Support RTL languages
- Add language-specific date/time formatting
- Implement regional crop name translations
- Add language-specific voice recognition

---

**Note**: This localization system is now fully integrated into your FarmOps app. The language choice is remembered across app restarts, and the entire app can be easily translated by following the patterns shown in this guide.
