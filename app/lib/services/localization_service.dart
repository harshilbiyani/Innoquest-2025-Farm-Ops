import 'package:flutter/material.dart';
import 'user_preferences.dart';

class LocalizationService extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  // Load saved language preference
  Future<void> loadLanguage() async {
    final languageCode = await UserPreferences.getLanguage();
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    await UserPreferences.saveLanguage(languageCode);
    notifyListeners();
  }

  // Get current language name
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'mr':
        return 'मराठी';
      default:
        return 'English';
    }
  }
}

// Extension to get translations
extension LocalizationExtension on BuildContext {
  AppLocalizations get localizations {
    return AppLocalizations.of(this);
  }
}

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Get translations based on locale
  Map<String, String> get _localizedStrings {
    switch (locale.languageCode) {
      case 'hi':
        return _hindiStrings;
      case 'mr':
        return _marathiStrings;
      default:
        return _englishStrings;
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Convenience getters for common strings
  String get appName => translate('app_name');
  String get selectLanguage => translate('select_language');
  String get next => translate('next');
  String get english => translate('english');
  String get hindi => translate('hindi');
  String get marathi => translate('marathi');
  
  // Login Page
  String get enterMobileNumber => translate('enter_mobile_number');
  String get mobileNumber => translate('mobile_number');
  String get getOTP => translate('get_otp');
  String get termsConditions => translate('terms_conditions');
  
  // OTP Page
  String get verifyOTP => translate('verify_otp');
  String get enterOTPSent => translate('enter_otp_sent');
  String get verify => translate('verify');
  String get resendOTP => translate('resend_otp');
  
  // Home Page
  String get welcomeBack => translate('welcome_back');
  String get exploreFeatures => translate('explore_features');
  String get locationBasedRecommendation => translate('location_based_recommendation');
  String get soilBasedCropRecommendation => translate('soil_based_crop_recommendation');
  String get professionalAdvisor => translate('professional_advisor');
  String get governmentSchemes => translate('government_schemes');
  String get weatherForecast => translate('weather_forecast');
  String get diseaseDetection => translate('disease_detection');
  String get marketAnalysis => translate('market_analysis');
  String get profitLossCalculator => translate('profit_loss_calculator');
  
  // Navigation
  String get home => translate('home');
  String get profile => translate('profile');
  String get logout => translate('logout');
  String get chatbot => translate('chatbot');
  
  // Common
  String get submit => translate('submit');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get yes => translate('yes');
  String get no => translate('no');
  String get close => translate('close');
  String get retry => translate('retry');
  
  // Profile Page
  String get myProfile => translate('my_profile');
  String get name => translate('name');
  String get location => translate('location');
  String get landSize => translate('land_size');
  String get editProfile => translate('edit_profile');
  String get saveProfile => translate('save_profile');
  
  // Location Recommendation
  String get locationRecommendation => translate('location_recommendation');
  String get fetchingLocation => translate('fetching_location');
  String get getCropRecommendation => translate('get_crop_recommendation');
  String get recommendedCrops => translate('recommended_crops');
  
  // Soil Recommendation
  String get soilRecommendation => translate('soil_recommendation');
  String get nitrogen => translate('nitrogen');
  String get phosphorus => translate('phosphorus');
  String get potassium => translate('potassium');
  String get temperature => translate('temperature');
  String get humidity => translate('humidity');
  String get ph => translate('ph');
  String get rainfall => translate('rainfall');
  
  // Weather Forecast
  String get weatherForecastTitle => translate('weather_forecast_title');
  String get currentWeather => translate('current_weather');
  String get forecast => translate('forecast');
  String get feelsLike => translate('feels_like');
  String get wind => translate('wind');
  String get pressure => translate('pressure');
  
  // Professional Advisor
  String get professionalAdvisorTitle => translate('professional_advisor_title');
  String get askQuestion => translate('ask_question');
  String get typeYourQuestion => translate('type_your_question');
  String get send => translate('send');
  
  // Government Schemes
  String get governmentSchemesTitle => translate('government_schemes_title');
  String get availableSchemes => translate('available_schemes');
  String get learnMore => translate('learn_more');
  
  // Disease Detection
  String get diseaseDetectionTitle => translate('disease_detection_title');
  String get uploadImage => translate('upload_image');
  String get takePhoto => translate('take_photo');
  String get selectFromGallery => translate('select_from_gallery');
  String get analyzing => translate('analyzing');
  String get diseaseDetected => translate('disease_detected');
  String get treatment => translate('treatment');
  
  // Market Analysis
  String get marketAnalysisTitle => translate('market_analysis_title');
  String get currentPrices => translate('current_prices');
  String get priceHistory => translate('price_history');
  String get cropName => translate('crop_name');
  String get price => translate('price');
  
  // Profit Loss Calculator
  String get profitLossCalculatorTitle => translate('profit_loss_calculator_title');
  String get cropCost => translate('crop_cost');
  String get sellingPrice => translate('selling_price');
  String get calculate => translate('calculate');
  String get profit => translate('profit');
  String get loss => translate('loss');
  
  // Chatbot
  String get chatbotTitle => translate('chatbot_title');
  String get typeMessage => translate('type_message');
  String get listening => translate('listening');
  String get speaking => translate('speaking');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'mr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// English Translations
const Map<String, String> _englishStrings = {
  'app_name': 'FarmOps',
  'select_language': 'Please, Select your language!',
  'next': 'Next',
  'english': 'English',
  'hindi': 'Hindi',
  'marathi': 'Marathi',
  
  // Login
  'enter_mobile_number': 'Enter your mobile number',
  'mobile_number': 'Mobile Number',
  'get_otp': 'Get OTP',
  'terms_conditions': 'By continuing, you agree to our Terms & Conditions',
  
  // OTP
  'verify_otp': 'Verify OTP',
  'enter_otp_sent': 'Enter the OTP sent to your mobile',
  'verify': 'Verify',
  'resend_otp': 'Resend OTP',
  
  // Home
  'welcome_back': 'Welcome Back!',
  'explore_features': 'Explore Features',
  'location_based_recommendation': 'Location Based\nRecommendation',
  'soil_based_crop_recommendation': 'Soil Based Crop\nRecommendation',
  'professional_advisor': 'Professional\nAdvisor',
  'government_schemes': 'Government\nSchemes',
  'weather_forecast': 'Weather\nForecast',
  'disease_detection': 'Disease\nDetection',
  'market_analysis': 'Market\nAnalysis',
  'profit_loss_calculator': 'Profit/Loss\nCalculator',
  
  // Navigation
  'home': 'Home',
  'profile': 'Profile',
  'logout': 'Logout',
  'chatbot': 'Chatbot',
  
  // Common
  'submit': 'Submit',
  'cancel': 'Cancel',
  'save': 'Save',
  'delete': 'Delete',
  'edit': 'Edit',
  'loading': 'Loading...',
  'error': 'Error',
  'success': 'Success',
  'yes': 'Yes',
  'no': 'No',
  'close': 'Close',
  'retry': 'Retry',
  
  // Profile
  'my_profile': 'My Profile',
  'name': 'Name',
  'location': 'Location',
  'land_size': 'Land Size',
  'edit_profile': 'Edit Profile',
  'save_profile': 'Save Profile',
  
  // Location Recommendation
  'location_recommendation': 'Location Based Recommendation',
  'fetching_location': 'Fetching Location...',
  'get_crop_recommendation': 'Get Crop Recommendation',
  'recommended_crops': 'Recommended Crops',
  
  // Soil Recommendation
  'soil_recommendation': 'Soil Based Recommendation',
  'nitrogen': 'Nitrogen',
  'phosphorus': 'Phosphorus',
  'potassium': 'Potassium',
  'temperature': 'Temperature',
  'humidity': 'Humidity',
  'ph': 'pH Level',
  'rainfall': 'Rainfall',
  
  // Weather Forecast
  'weather_forecast_title': 'Weather Forecast',
  'current_weather': 'Current Weather',
  'forecast': 'Forecast',
  'feels_like': 'Feels Like',
  'wind': 'Wind',
  'pressure': 'Pressure',
  
  // Professional Advisor
  'professional_advisor_title': 'Professional Advisor',
  'ask_question': 'Ask Your Question',
  'type_your_question': 'Type your question here...',
  'send': 'Send',
  
  // Government Schemes
  'government_schemes_title': 'Government Schemes',
  'available_schemes': 'Available Schemes',
  'learn_more': 'Learn More',
  
  // Disease Detection
  'disease_detection_title': 'Disease Detection',
  'upload_image': 'Upload Image',
  'take_photo': 'Take Photo',
  'select_from_gallery': 'Select from Gallery',
  'analyzing': 'Analyzing...',
  'disease_detected': 'Disease Detected',
  'treatment': 'Treatment',
  
  // Market Analysis
  'market_analysis_title': 'Market Analysis',
  'current_prices': 'Current Prices',
  'price_history': 'Price History',
  'crop_name': 'Crop Name',
  'price': 'Price',
  
  // Profit Loss Calculator
  'profit_loss_calculator_title': 'Profit/Loss Calculator',
  'crop_cost': 'Crop Cost',
  'selling_price': 'Selling Price',
  'calculate': 'Calculate',
  'profit': 'Profit',
  'loss': 'Loss',
  
  // Chatbot
  'chatbot_title': 'Chatbot',
  'type_message': 'Type a message...',
  'listening': 'Listening...',
  'speaking': 'Speaking...',
};

// Hindi Translations
const Map<String, String> _hindiStrings = {
  'app_name': 'फार्मऑप्स',
  'select_language': 'कृपया, अपनी भाषा चुनें!',
  'next': 'आगे',
  'english': 'अंग्रेज़ी',
  'hindi': 'हिंदी',
  'marathi': 'मराठी',
  
  // Login
  'enter_mobile_number': 'अपना मोबाइल नंबर दर्ज करें',
  'mobile_number': 'मोबाइल नंबर',
  'get_otp': 'ओटीपी प्राप्त करें',
  'terms_conditions': 'जारी रखकर, आप हमारी शर्तों और नियमों से सहमत हैं',
  
  // OTP
  'verify_otp': 'ओटीपी सत्यापित करें',
  'enter_otp_sent': 'अपने मोबाइल पर भेजा गया ओटीपी दर्ज करें',
  'verify': 'सत्यापित करें',
  'resend_otp': 'ओटीपी पुनः भेजें',
  
  // Home
  'welcome_back': 'वापसी पर स्वागत है!',
  'explore_features': 'सुविधाएं देखें',
  'location_based_recommendation': 'स्थान आधारित\nसिफारिश',
  'soil_based_crop_recommendation': 'मिट्टी आधारित फसल\nसिफारिश',
  'professional_advisor': 'पेशेवर\nसलाहकार',
  'government_schemes': 'सरकारी\nयोजनाएं',
  'weather_forecast': 'मौसम\nपूर्वानुमान',
  'disease_detection': 'रोग\nपहचान',
  'market_analysis': 'बाजार\nविश्लेषण',
  'profit_loss_calculator': 'लाभ/हानि\nकैलकुलेटर',
  
  // Navigation
  'home': 'होम',
  'profile': 'प्रोफ़ाइल',
  'logout': 'लॉगआउट',
  'chatbot': 'चैटबॉट',
  
  // Common
  'submit': 'जमा करें',
  'cancel': 'रद्द करें',
  'save': 'सहेजें',
  'delete': 'हटाएं',
  'edit': 'संपादित करें',
  'loading': 'लोड हो रहा है...',
  'error': 'त्रुटि',
  'success': 'सफलता',
  'yes': 'हाँ',
  'no': 'नहीं',
  'close': 'बंद करें',
  'retry': 'पुनः प्रयास करें',
  
  // Profile
  'my_profile': 'मेरी प्रोफ़ाइल',
  'name': 'नाम',
  'location': 'स्थान',
  'land_size': 'भूमि का आकार',
  'edit_profile': 'प्रोफ़ाइल संपादित करें',
  'save_profile': 'प्रोफ़ाइल सहेजें',
  
  // Location Recommendation
  'location_recommendation': 'स्थान आधारित सिफारिश',
  'fetching_location': 'स्थान प्राप्त किया जा रहा है...',
  'get_crop_recommendation': 'फसल सिफारिश प्राप्त करें',
  'recommended_crops': 'अनुशंसित फसलें',
  
  // Soil Recommendation
  'soil_recommendation': 'मिट्टी आधारित सिफारिश',
  'nitrogen': 'नाइट्रोजन',
  'phosphorus': 'फास्फोरस',
  'potassium': 'पोटैशियम',
  'temperature': 'तापमान',
  'humidity': 'आर्द्रता',
  'ph': 'पीएच स्तर',
  'rainfall': 'वर्षा',
  
  // Weather Forecast
  'weather_forecast_title': 'मौसम पूर्वानुमान',
  'current_weather': 'वर्तमान मौसम',
  'forecast': 'पूर्वानुमान',
  'feels_like': 'महसूस होता है',
  'wind': 'हवा',
  'pressure': 'दबाव',
  
  // Professional Advisor
  'professional_advisor_title': 'पेशेवर सलाहकार',
  'ask_question': 'अपना प्रश्न पूछें',
  'type_your_question': 'अपना प्रश्न यहाँ लिखें...',
  'send': 'भेजें',
  
  // Government Schemes
  'government_schemes_title': 'सरकारी योजनाएं',
  'available_schemes': 'उपलब्ध योजनाएं',
  'learn_more': 'अधिक जानें',
  
  // Disease Detection
  'disease_detection_title': 'रोग पहचान',
  'upload_image': 'छवि अपलोड करें',
  'take_photo': 'फोटो लें',
  'select_from_gallery': 'गैलरी से चुनें',
  'analyzing': 'विश्लेषण कर रहे हैं...',
  'disease_detected': 'रोग का पता लगा',
  'treatment': 'उपचार',
  
  // Market Analysis
  'market_analysis_title': 'बाजार विश्लेषण',
  'current_prices': 'वर्तमान कीमतें',
  'price_history': 'मूल्य इतिहास',
  'crop_name': 'फसल का नाम',
  'price': 'कीमत',
  
  // Profit Loss Calculator
  'profit_loss_calculator_title': 'लाभ/हानि कैलकुलेटर',
  'crop_cost': 'फसल की लागत',
  'selling_price': 'बिक्री मूल्य',
  'calculate': 'गणना करें',
  'profit': 'लाभ',
  'loss': 'हानि',
  
  // Chatbot
  'chatbot_title': 'चैटबॉट',
  'type_message': 'एक संदेश लिखें...',
  'listening': 'सुन रहा है...',
  'speaking': 'बोल रहा है...',
};

// Marathi Translations
const Map<String, String> _marathiStrings = {
  'app_name': 'फार्मऑप्स',
  'select_language': 'कृपया, तुमची भाषा निवडा!',
  'next': 'पुढे',
  'english': 'इंग्रजी',
  'hindi': 'हिंदी',
  'marathi': 'मराठी',
  
  // Login
  'enter_mobile_number': 'तुमचा मोबाईल नंबर प्रविष्ट करा',
  'mobile_number': 'मोबाईल नंबर',
  'get_otp': 'ओटीपी मिळवा',
  'terms_conditions': 'सुरू ठेवून, तुम्ही आमच्या अटी व शर्तींशी सहमत आहात',
  
  // OTP
  'verify_otp': 'ओटीपी सत्यापित करा',
  'enter_otp_sent': 'तुमच्या मोबाईलवर पाठवलेला ओटीपी प्रविष्ट करा',
  'verify': 'सत्यापित करा',
  'resend_otp': 'ओटीपी पुन्हा पाठवा',
  
  // Home
  'welcome_back': 'परत स्वागत आहे!',
  'explore_features': 'वैशिष्ट्ये एक्सप्लोर करा',
  'location_based_recommendation': 'स्थान आधारित\nशिफारस',
  'soil_based_crop_recommendation': 'माती आधारित पीक\nशिफारस',
  'professional_advisor': 'व्यावसायिक\nसल्लागार',
  'government_schemes': 'सरकारी\nयोजना',
  'weather_forecast': 'हवामान\nअंदाज',
  'disease_detection': 'रोग\nओळख',
  'market_analysis': 'बाजार\nविश्लेषण',
  'profit_loss_calculator': 'नफा/तोटा\nकॅल्क्युलेटर',
  
  // Navigation
  'home': 'होम',
  'profile': 'प्रोफाइल',
  'logout': 'लॉगआउट',
  'chatbot': 'चॅटबॉट',
  
  // Common
  'submit': 'सबमिट करा',
  'cancel': 'रद्द करा',
  'save': 'सेव्ह करा',
  'delete': 'हटवा',
  'edit': 'संपादित करा',
  'loading': 'लोड होत आहे...',
  'error': 'त्रुटी',
  'success': 'यशस्वी',
  'yes': 'होय',
  'no': 'नाही',
  'close': 'बंद करा',
  'retry': 'पुन्हा प्रयत्न करा',
  
  // Profile
  'my_profile': 'माझे प्रोफाइल',
  'name': 'नाव',
  'location': 'स्थान',
  'land_size': 'जमिनीचा आकार',
  'edit_profile': 'प्रोफाइल संपादित करा',
  'save_profile': 'प्रोफाइल सेव्ह करा',
  
  // Location Recommendation
  'location_recommendation': 'स्थान आधारित शिफारस',
  'fetching_location': 'स्थान मिळवत आहे...',
  'get_crop_recommendation': 'पीक शिफारस मिळवा',
  'recommended_crops': 'शिफारस केलेली पिके',
  
  // Soil Recommendation
  'soil_recommendation': 'माती आधारित शिफारस',
  'nitrogen': 'नायट्रोजन',
  'phosphorus': 'फॉस्फरस',
  'potassium': 'पोटॅशियम',
  'temperature': 'तापमान',
  'humidity': 'आर्द्रता',
  'ph': 'पीएच पातळी',
  'rainfall': 'पाऊस',
  
  // Weather Forecast
  'weather_forecast_title': 'हवामान अंदाज',
  'current_weather': 'सध्याचे हवामान',
  'forecast': 'अंदाज',
  'feels_like': 'असे वाटते',
  'wind': 'वारा',
  'pressure': 'दाब',
  
  // Professional Advisor
  'professional_advisor_title': 'व्यावसायिक सल्लागार',
  'ask_question': 'तुमचा प्रश्न विचारा',
  'type_your_question': 'तुमचा प्रश्न येथे टाइप करा...',
  'send': 'पाठवा',
  
  // Government Schemes
  'government_schemes_title': 'सरकारी योजना',
  'available_schemes': 'उपलब्ध योजना',
  'learn_more': 'अधिक जाणून घ्या',
  
  // Disease Detection
  'disease_detection_title': 'रोग ओळख',
  'upload_image': 'प्रतिमा अपलोड करा',
  'take_photo': 'फोटो घ्या',
  'select_from_gallery': 'गॅलरीमधून निवडा',
  'analyzing': 'विश्लेषण करत आहे...',
  'disease_detected': 'रोग आढळला',
  'treatment': 'उपचार',
  
  // Market Analysis
  'market_analysis_title': 'बाजार विश्लेषण',
  'current_prices': 'सध्याच्या किंमती',
  'price_history': 'किंमत इतिहास',
  'crop_name': 'पिकाचे नाव',
  'price': 'किंमत',
  
  // Profit Loss Calculator
  'profit_loss_calculator_title': 'नफा/तोटा कॅल्क्युलेटर',
  'crop_cost': 'पिकाची किंमत',
  'selling_price': 'विक्री किंमत',
  'calculate': 'गणना करा',
  'profit': 'नफा',
  'loss': 'तोटा',
  
  // Chatbot
  'chatbot_title': 'चॅटबॉट',
  'type_message': 'संदेश टाइप करा...',
  'listening': 'ऐकत आहे...',
  'speaking': 'बोलत आहे...',
};
