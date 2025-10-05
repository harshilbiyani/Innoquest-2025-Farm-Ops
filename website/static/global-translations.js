/**
 * Global Translation System for FarmOps
 * Works across all pages of the website
 */

// Global translation data
const GLOBAL_TRANSLATIONS = {
  en: {
    // Navigation
    'nav.home': 'HOME',
    'nav.language': 'SELECT LANGUAGE',
    'nav.solutions': 'SOLUTIONS', 
    'nav.feedback': 'FEEDBACK',
    'nav.logout': 'LOGOUT',
    'nav.features': 'FEATURES',
    'nav.about': 'ABOUT US',
    
    // Hero Section
    'hero.title': 'Crop Intelligence Advisor',
    'hero.explore': 'EXPLORE FARMING SOLUTIONS',
    'hero.about': 'ABOUT US',
    'hero.smart_crop': 'Smart Crop Advisory',
    
    // About Section
    'about.title': 'About Us',
    'about.description1': 'At Farm Ops, we blend agriculture with smart technology to make farming efficient, profitable, and sustainable. Our AI-powered platform offers crop suitability prediction and GPS-based land suggestions to help farmers choose the right crops and maximize land use.',
    'about.description2': 'Beyond cultivation, we provide market (mandi) guidance for better pricing decisions and expert consultation for personalized solutions. What makes us unique is our multilingual chatbot, accessible via text and voice in regional languages.',
    'about.commitment': 'Farm Ops is committed to empowering every farmer — big or small — with tools that simplify decisions, increase productivity, and build a smarter, more inclusive future for agriculture.',
    
    // Features Page
    'features.title': 'FarmOps Features',
    'features.heading': 'Explore Farming Solutions',
    'features.location.title': 'Location Based Crop Suggestion',
    'features.location.desc': 'Recommends suitable crops based on regional climate and geography.\nHelps farmers maximize yield by aligning with local environmental conditions.',
    'features.soil.title': 'Soil Data Based Crop Suggestion',
    'features.soil.desc': 'Suggests crops by analyzing soil health, nutrients, and fertility.\nEnsures better productivity by matching crops with soil requirements.',
    'features.mandi.title': 'Mandi Recommendation',
    'features.mandi.desc': 'Guides farmers to nearby markets offering better prices for their produce.\nEnables smarter selling decisions and higher profitability.',
    'features.expert.title': 'Ask an Expert',
    'features.expert.desc': 'Connects users directly with agricultural experts for personalized advice.\nSupports quick solutions to farming challenges and doubts.',
    'features.weather.title': 'Know Weather',
    'features.weather.desc': 'Provides real-time weather updates and forecasts for informed farming decisions.\nReduces risk by helping plan irrigation, sowing, and harvesting activities.',
    'features.disease.title': 'Crop Disease Identification',
    'features.disease.desc': 'AI-powered models analyze crop images to detect early signs of diseases. This helps farmers take timely preventive measures and reduce crop losses.',
    
    // Manual Input page
    'manual.title': 'Manual Input',
    'manual.heading': 'Enter Soil and Climate Attributes',
    'manual.select': '-- Select --',
    'manual.predict': 'Predict Crop Suitability',
    
    // YieldWise page
    'yieldwise.title': 'YieldWise - Profit Loss Calculator',
    'yieldwise.subtitle': 'Calculate your farming profit & loss with precision and get smart recommendations',
    'yieldwise.input.title': 'Farming Inputs',
    'yieldwise.results.title': 'Financial Analysis',
    'yieldwise.results.empty': 'Fill in your farming details to see profit/loss analysis',
    'yieldwise.state.label': 'State:',
    'yieldwise.district.label': 'District:',
    'yieldwise.block.label': 'Block:',
    'yieldwise.village.label': 'Village:',
    'yieldwise.crop.label': 'Crop Type:',
    'yieldwise.area.label': 'Farm Area (acres):',
    'yieldwise.yield.label': 'Expected Yield (quintals/acre):',
    'yieldwise.price.label': 'Market Price (₹/quintal):',
    'yieldwise.seeds.label': 'Seed Cost (₹):',
    'yieldwise.fertilizer.label': 'Fertilizer Cost (₹):',
    'yieldwise.pesticide.label': 'Pesticide Cost (₹):',
    'yieldwise.labor.label': 'Labor Cost (₹):',
    'yieldwise.other.label': 'Other Expenses (₹):',
    'yieldwise.calculate': 'Calculate Profit/Loss',
    'yieldwise.chart.breakdown': 'Cost Breakdown',
    'yieldwise.chart.comparison': 'Revenue vs Costs',
    'yieldwise.suggestions.title': 'Smart Recommendations',
    'nav.back': '← Back to Features',
    'features.mandi': 'Mandi Recommendation',
    'features.mandi_desc': 'Guides farmers to nearby markets offering better prices for their produce. Enables smarter selling decisions and higher profitability.',
    'features.expert': 'Ask an Expert',
    'features.expert_desc': 'Connects users directly with agricultural experts for personalized advice. Supports quick solutions to farming challenges and doubts.',
    'features.weather': 'Know Weather',
    'features.weather_desc': 'Provides real-time weather updates and forecasts for informed farming decisions. Reduces risk by helping plan irrigation, sowing, and harvesting activities.',
    'features.disease': 'Crop Disease Identification',
    'features.disease_desc': 'AI-powered models analyze crop images to detect early signs of diseases. This helps farmers take timely preventive measures and reduce crop losses.',
    
    // Manual Input Page
    'manual.title': 'Soil Nutrient Analysis',
    'manual.subtitle': 'Enter your soil analysis data for personalized crop recommendations',
    'manual.nitrogen': 'Nitrogen (N)',
    'manual.phosphorus': 'Phosphorus (P)',
    'manual.potassium': 'Potassium (K)',
    'manual.ph': 'pH Level',
    'manual.submit': 'Get Crop Recommendations',
    'manual.loading': 'Analyzing your soil data...',
    
    // Weather Page
    'weather.title': 'Weather Forecast',
    'weather.current': 'Current Weather',
    'weather.forecast': '7-Day Forecast',
    'weather.temperature': 'Temperature',
    'weather.humidity': 'Humidity',
    'weather.rainfall': 'Rainfall',
    
    // Common Elements
    'common.submit': 'Submit',
    'common.cancel': 'Cancel',
    'common.loading': 'Loading...',
    'common.error': 'An error occurred',
    'common.success': 'Success!',
    'common.close': 'Close',
    'common.next': 'Next',
    'common.previous': 'Previous',
    'common.save': 'Save',
    'common.delete': 'Delete',
    'common.edit': 'Edit',
    'common.view': 'View',
    'common.search': 'Search',
    'common.filter': 'Filter',
    'common.sort': 'Sort',
    'common.export': 'Export',
    'common.import': 'Import'
  },
  
  hi: {
    // Navigation
    'nav.home': 'होम',
    'nav.language': 'भाषा चुनें',
    'nav.solutions': 'समाधान',
    'nav.feedback': 'फीडबैक',
    'nav.logout': 'लॉगआउट',
    'nav.features': 'सुविधाएं',
    'nav.about': 'हमारे बारे में',
    
    // Hero Section
    'hero.title': 'फसल बुद्धि सलाहकार',
    'hero.explore': 'कृषि समाधान देखें',
    'hero.about': 'हमारे बारे में',
    'hero.smart_crop': 'स्मार्ट फसल सलाहकार',
    
    // About Section
    'about.title': 'हमारे बारे में',
    'about.description1': 'फार्म ऑप्स में, हम कृषि को स्मार्ट तकनीक के साथ मिलाकर खेती को कुशल, लाभदायक और टिकाऊ बनाते हैं। हमारा AI-संचालित प्लेटफॉर्म फसल उपयुक्तता भविष्यवाणी और GPS-आधारित भूमि सुझाव प्रदान करता है।',
    'about.description2': 'खेती के अलावा, हम बेहतर मूल्य निर्णयों के लिए बाजार (मंडी) मार्गदर्शन और व्यक्तिगत समाधानों के लिए विशेषज्ञ सलाह प्रदान करते हैं। हमारी विशेषता हमारा बहुभाषी चैटबॉट है।',
    'about.commitment': 'फार्म ऑप्स हर किसान को — छोटे या बड़े — ऐसे उपकरण प्रदान करने के लिए प्रतिबद्ध है जो निर्णयों को सरल बनाते हैं, उत्पादकता बढ़ाते हैं।',
    
    // Features Page
    'features.title': 'फार्मऑप्स विशेषताएं',
    'features.heading': 'कृषि समाधान देखें',
    'features.location.title': 'स्थान आधारित फसल सुझाव',
    'features.location.desc': 'क्षेत्रीय जलवायु और भूगोल के आधार पर उपयुक्त फसलों की सिफारिश करता है।\nस्थानीय पर्यावरणीय परिस्थितियों के साथ तालमेल बिठाकर किसानों को अधिकतम उपज प्राप्त करने में मदद करता है।',
    'features.soil.title': 'मिट्टी डेटा आधारित फसल सुझाव',
    'features.soil.desc': 'मिट्टी के स्वास्थ्य, पोषक तत्वों और उर्वरता का विश्लेषण करके फसलों का सुझाव देता है।\nफसल की आवश्यकताओं के साथ मिट्टी का मिलान करके बेहतर उत्पादकता सुनिश्चित करता है।',
    'features.mandi.title': 'मंडी सिफारिश',
    'features.mandi.desc': 'किसानों को उनकी उपज के लिए बेहतर कीमत देने वाले नजदीकी बाजारों का मार्गदर्शन करता है।\nस्मार्ट बिक्री निर्णय और उच्च लाभप्रदता को सक्षम बनाता है।',
    'features.expert.title': 'विशेषज्ञ से पूछें',
    'features.expert.desc': 'व्यक्तिगत सलाह के लिए उपयोगकर्ताओं को सीधे कृषि विशेषज्ञों से जोड़ता है।\nखेती की चुनौतियों और संदेहों के त्वरित समाधान का समर्थन करता है।',
    'features.weather.title': 'मौसम जानें',
    'features.weather.desc': 'सूचित खेती के निर्णयों के लिए वास्तविक समय मौसम अपडेट और पूर्वानुमान प्रदान करता है।\nसिंचाई, बुआई और कटाई गतिविधियों की योजना बनाने में मदद करके जोखिम कम करता है।',
    'features.disease.title': 'फसल रोग पहचान',
    'features.disease.desc': 'AI-संचालित मॉडल रोगों के प्रारंभिक संकेतों का पता लगाने के लिए फसल छवियों का विश्लेषण करते हैं। यह किसानों को समय पर निवारक उपाय करने और फसल हानि को कम करने में मदद करता है।',
    
    // Manual Input page  
    'manual.title': 'मैनुअल इनपुट',
    'manual.heading': 'मिट्टी और जलवायु विशेषताएं दर्ज करें',
    'manual.select': '-- चुनें --',
    'manual.predict': 'फसल उपयुक्तता की भविष्यवाणी',
    
    // YieldWise page
    'yieldwise.title': 'यील्डवाइज़ - लाभ हानि कैलकुलेटर',
    'yieldwise.subtitle': 'सटीकता के साथ अपनी खेती के लाभ और हानि की गणना करें और स्मार्ट सुझाव प्राप्त करें',
    'yieldwise.input.title': 'खेती की जानकारी',
    'yieldwise.results.title': 'वित्तीय विश्लेषण',
    'yieldwise.results.empty': 'लाभ/हानि विश्लेषण देखने के लिए अपनी खेती का विवरण भरें',
    'yieldwise.state.label': 'राज्य:',
    'yieldwise.district.label': 'जिला:',
    'yieldwise.block.label': 'ब्लॉक:',
    'yieldwise.village.label': 'गाँव:',
    'yieldwise.crop.label': 'फसल का प्रकार:',
    'yieldwise.area.label': 'खेत का क्षेत्रफल (एकड़):',
    'yieldwise.yield.label': 'अपेक्षित उत्पादन (क्विंटल/एकड़):',
    'yieldwise.price.label': 'बाजार मूल्य (₹/क्विंटल):',
    'yieldwise.seeds.label': 'बीज की लागत (₹):',
    'yieldwise.fertilizer.label': 'उर्वरक की लागत (₹):',
    'yieldwise.pesticide.label': 'कीटनाशक की लागत (₹):',
    'yieldwise.labor.label': 'श्रम लागत (₹):',
    'yieldwise.other.label': 'अन्य खर्च (₹):',
    'yieldwise.calculate': 'लाभ/हानि की गणना करें',
    'yieldwise.chart.breakdown': 'लागत विवरण',
    'yieldwise.chart.comparison': 'राजस्व बनाम लागत',
    'yieldwise.suggestions.title': 'स्मार्ट सुझाव',
    'nav.back': '← फीचर्स पर वापस जाएं',
    'features.location_crop': 'स्थान आधारित फसल सुझाव',
    'features.location_desc': 'क्षेत्रीय जलवायु और भूगोल के आधार पर उपयुक्त फसलों की सिफारिश करता है। स्थानीय पर्यावरणीय स्थितियों के साथ संरेखित करके किसानों को अधिकतम उपज प्राप्त करने में मदद करता है।',
    'features.soil_crop': 'मिट्टी डेटा आधारित फसल सुझाव',
    'features.soil_desc': 'मिट्टी के स्वास्थ्य, पोषक तत्वों और उर्वरता का विश्लेषण करके फसलों का सुझाव देता है। फसलों को मिट्टी की आवश्यकताओं के साथ मिलाकर बेहतर उत्पादकता सुनिश्चित करता है।',
    'features.mandi': 'मंडी सिफारिश',
    'features.mandi_desc': 'किसानों को अपनी उपज के लिए बेहतर कीमत देने वाले नजदीकी बाजारों के लिए मार्गदर्शन करता है। स्मार्ट बिक्री निर्णय और उच्च लाभप्रदता को सक्षम बनाता है।',
    'features.expert': 'एक विशेषज्ञ से पूछें',
    'features.expert_desc': 'व्यक्तिगत सलाह के लिए उपयोगकर्ताओं को सीधे कृषि विशेषज्ञों से जोड़ता है। खेती की चुनौतियों और संदेहों के त्वरित समाधान का समर्थन करता है।',
    'features.weather': 'मौसम जानें',
    'features.weather_desc': 'सूचित कृषि निर्णयों के लिए वास्तविक समय मौसम अपडेट और पूर्वानुमान प्रदान करता है। सिंचाई, बुआई और कटाई गतिविधियों की योजना बनाने में मदद करके जोखिम को कम करता है।',
    'features.disease': 'फसल रोग पहचान',
    'features.disease_desc': 'AI-संचालित मॉडल फसल छवियों का विश्लेषण करके रोगों के प्रारंभिक संकेतों का पता लगाते हैं। यह किसानों को समय पर निवारक उपाय करने और फसल हानि को कम करने में मदद करता है।',
    
    // Manual Input Page
    'manual.title': 'मिट्टी पोषक तत्व विश्लेषण',
    'manual.subtitle': 'व्यक्तिगत फसल सिफारिशों के लिए अपना मिट्टी विश्लेषण डेटा दर्ज करें',
    'manual.nitrogen': 'नाइट्रोजन (N)',
    'manual.phosphorus': 'फास्फोरस (P)',
    'manual.potassium': 'पोटेशियम (K)',
    'manual.ph': 'pH स्तर',
    'manual.submit': 'फसल सिफारिशें प्राप्त करें',
    'manual.loading': 'आपकी मिट्टी डेटा का विश्लेषण...',
    
    // Weather Page
    'weather.title': 'मौसम पूर्वानुमान',
    'weather.current': 'वर्तमान मौसम',
    'weather.forecast': '7-दिन पूर्वानुमान',
    'weather.temperature': 'तापमान',
    'weather.humidity': 'नमी',
    'weather.rainfall': 'वर्षा',
    
    // Common Elements
    'common.submit': 'जमा करें',
    'common.cancel': 'रद्द करें',
    'common.loading': 'लोड हो रहा है...',
    'common.error': 'एक त्रुटि हुई',
    'common.success': 'सफलता!',
    'common.close': 'बंद करें',
    'common.next': 'अगला',
    'common.previous': 'पिछला',
    'common.save': 'सहेजें',
    'common.delete': 'हटाएं',
    'common.edit': 'संपादित करें',
    'common.view': 'देखें',
    'common.search': 'खोजें',
    'common.filter': 'फ़िल्टर',
    'common.sort': 'क्रमबद्ध करें',
    'common.export': 'निर्यात',
    'common.import': 'आयात'
  },
  
  mr: {
    // Navigation
    'nav.home': 'होम',
    'nav.language': 'भाषा निवडा',
    'nav.solutions': 'उपाय',
    'nav.feedback': 'फीडबॅक',
    'nav.logout': 'लॉगआउट',
    'nav.features': 'वैशिष्ट्ये',
    'nav.about': 'आमच्याबद्दल',
    
    // Hero Section
    'hero.title': 'पीक बुद्धिमत्ता सल्लागार',
    'hero.explore': 'शेती उपाय पहा',
    'hero.about': 'आमच्याबद्दल',
    'hero.smart_crop': 'स्मार्ट पीक सल्लागार',
    
    // Features Page
    'features.title': 'फार्मऑप्स: शेती उपाय पहा',
    'features.location_crop': 'स्थान आधारित पीक सूचना',
    'features.location_desc': 'प्रादेशिक हवामान आणि भूगोलावर आधारित योग्य पिकांची शिफारस करते।',
    'features.soil_crop': 'माती डेटा आधारित पीक सूचना',
    'features.soil_desc': 'मातीचे आरोग्य, पोषक घटक आणि सुपीकता यांचे विश्लेषण करून पिकांची सूचना देते।',
    
    // Common Elements
    'common.submit': 'सबमिट करा',
    'common.cancel': 'रद्द करा',
    'common.loading': 'लोड होत आहे...',
    'common.success': 'यश!',
    'common.close': 'बंद करा'
  },
  
  gu: {
    // Navigation
    'nav.home': 'હોમ',
    'nav.language': 'ભાષા પસંદ કરો',
    'nav.solutions': 'ઉકેલો',
    'nav.feedback': 'ફીડબેક',
    'nav.logout': 'લૉગઆઉટ',
    'nav.features': 'સુવિધાઓ',
    'nav.about': 'અમારા વિશે',
    
    // Hero Section
    'hero.title': 'પાક બુદ્ધિ સલાહકાર',
    'hero.explore': 'ખેતી ઉકેલો શોધો',
    'hero.about': 'અમારા વિશે',
    'hero.smart_crop': 'સ્માર્ટ પાક સલાહકાર',
    
    // Common Elements
    'common.submit': 'સબમિટ કરો',
    'common.cancel': 'રદ કરો',
    'common.loading': 'લોડ થઈ રહ્યું છે...',
    'common.success': 'સફળતા!',
    'common.close': 'બંધ કરો'
  },
  
  pa: {
    // Navigation
    'nav.home': 'ਘਰ',
    'nav.language': 'ਭਾਸ਼ਾ ਚੁਣੋ',
    'nav.solutions': 'ਹੱਲ',
    'nav.feedback': 'ਫੀਡਬੈਕ',
    'nav.logout': 'ਲਾਗਆਉਟ',
    'nav.features': 'ਵਿਸ਼ੇਸ਼ਤਾਵਾਂ',
    'nav.about': 'ਸਾਡੇ ਬਾਰੇ',
    
    // Hero Section
    'hero.title': 'ਫਸਲ ਬੁੱਧੀ ਸਲਾਹਕਾਰ',
    'hero.explore': 'ਖੇਤੀ ਹੱਲ ਵੇਖੋ',
    'hero.about': 'ਸਾਡੇ ਬਾਰੇ',
    
    // Common Elements
    'common.submit': 'ਜਮ੍ਹਾਂ ਕਰੋ',
    'common.cancel': 'ਰੱਦ ਕਰੋ',
    'common.loading': 'ਲੋਡ ਹੋ ਰਿਹਾ ਹੈ...',
    'common.success': 'ਸਫਲਤਾ!',
    'common.close': 'ਬੰਦ ਕਰੋ'
  },
  
  ta: {
    // Navigation
    'nav.home': 'வீடு',
    'nav.language': 'மொழி தேர்வு',
    'nav.solutions': 'தீர்வுகள்',
    'nav.feedback': 'கருத்து',
    'nav.logout': 'வெளியேறு',
    'nav.features': 'அம்சங்கள்',
    'nav.about': 'எங்களைப் பற்றி',
    
    // Hero Section
    'hero.title': 'பயிர் அறிவுத் ஆலோசகர்',
    'hero.explore': 'விவசாய தீர்வுகள் காண',
    'hero.about': 'எங்களைப் பற்றி',
    
    // Common Elements
    'common.submit': 'சமர்ப்பிக்கவும்',
    'common.cancel': 'ரத்து செய்',
    'common.loading': 'ஏற்றப்படுகிறது...',
    'common.success': 'வெற்றி!',
    'common.close': 'மூடு'
  },
  
  te: {
    // Navigation
    'nav.home': 'హోమ్',
    'nav.language': 'భాష ఎంచుకోండి',
    'nav.solutions': 'పరిష్కారాలు',
    'nav.feedback': 'అభిప్రాయం',
    'nav.logout': 'లాగ్ అవుట్',
    'nav.features': 'లక్షణాలు',
    'nav.about': 'మా గురించి',
    
    // Hero Section
    'hero.title': 'పంట మేధస్సు సలహాదారు',
    'hero.explore': 'వ్యవసాయ పరిష్కారాలు చూడండి',
    'hero.about': 'మా గురించి',
    
    // Common Elements
    'common.submit': 'సమర్పించండి',
    'common.cancel': 'రద్దు చేయండి',
    'common.loading': 'లోడ్ అవుతోంది...',
    'common.success': 'విజయం!',
    'common.close': 'మూసివేయండి'
  },
  
  kn: {
    // Navigation
    'nav.home': 'ಮುಖ್ಯಪುಟ',
    'nav.language': 'ಭಾಷೆ ಆಯ್ಕೆ',
    'nav.solutions': 'ಪರಿಹಾರಗಳು',
    'nav.feedback': 'ಅಭಿಪ್ರಾಯ',
    'nav.logout': 'ಲಾಗ್ ಔಟ್',
    'nav.features': 'ವೈಶಿಷ್ಟ್ಯಗಳು',
    'nav.about': 'ನಮ್ಮ ಬಗ್ಗೆ',
    
    // Hero Section
    'hero.title': 'ಬೆಳೆ ಬುದ್ಧಿಮತ್ತೆ ಸಲಹೆಗಾರ',
    'hero.explore': 'ಕೃಷಿ ಪರಿಹಾರಗಳನ್ನು ಅನ್ವೇಷಿಸಿ',
    'hero.about': 'ನಮ್ಮ ಬಗ್ಗೆ',
    
    // Common Elements
    'common.submit': 'ಸಲ್ಲಿಸಿ',
    'common.cancel': 'ರದ್ದುಮಾಡಿ',
    'common.loading': 'ಲೋಡ್ ಆಗುತ್ತಿದೆ...',
    'common.success': 'ಯಶಸ್ಸು!',
    'common.close': 'ಮುಚ್ಚಿ'
  },
  
  bn: {
    // Navigation
    'nav.home': 'হোম',
    'nav.language': 'ভাষা নির্বাচন',
    'nav.solutions': 'সমাধান',
    'nav.feedback': 'মতামত',
    'nav.logout': 'লগআউট',
    'nav.features': 'বৈশিষ্ট্য',
    'nav.about': 'আমাদের সম্পর্কে',
    
    // Hero Section
    'hero.title': 'ফসল বুদ্ধিমত্তা পরামর্শদাতা',
    'hero.explore': 'কৃষি সমাধান দেখুন',
    'hero.about': 'আমাদের সম্পর্কে',
    
    // Common Elements
    'common.submit': 'জমা দিন',
    'common.cancel': 'বাতিল',
    'common.loading': 'লোড হচ্ছে...',
    'common.success': 'সফল!',
    'common.close': 'বন্ধ করুন'
  }
};

// Global language system class
class GlobalTranslationSystem {
  constructor() {
    this.currentLanguage = localStorage.getItem('selectedLanguage') || 'en';
    this.init();
  }
  
  init() {
    console.log('🌍 Global Translation System Initialized');
    this.loadSavedLanguage();
    this.setupLanguageDropdown();
    this.setupLanguageOptions();
  }
  
  loadSavedLanguage() {
    if (this.currentLanguage !== 'en') {
      this.changeLanguage(this.currentLanguage);
    }
  }
  
  setupLanguageDropdown() {
    const languageBtn = document.getElementById('languageBtn');
    if (languageBtn) {
      languageBtn.addEventListener('click', (e) => {
        e.preventDefault();
        const dropdown = document.querySelector('.language-dropdown');
        if (dropdown) {
          dropdown.classList.toggle('active');
        }
      });
    }
  }
  
  setupLanguageOptions() {
    // Setup for inline onclick handlers
    window.changeLanguage = (lang) => this.changeLanguage(lang);
    
    // Also setup event listeners for non-inline handlers
    document.querySelectorAll('[data-lang]').forEach(option => {
      option.addEventListener('click', (e) => {
        e.preventDefault();
        const lang = option.getAttribute('data-lang');
        this.changeLanguage(lang);
      });
    });
  }
  
  changeLanguage(lang) {
    console.log(`🔄 Changing language to: ${lang}`);
    
    if (!GLOBAL_TRANSLATIONS[lang]) {
      console.error(`❌ Language ${lang} not found`);
      return;
    }
    
    this.currentLanguage = lang;
    localStorage.setItem('selectedLanguage', lang);
    
    // Translate all elements
    const elements = document.querySelectorAll('[data-translate]');
    console.log(`📝 Found ${elements.length} translatable elements`);
    
    elements.forEach((element, index) => {
      const key = element.getAttribute('data-translate');
      if (GLOBAL_TRANSLATIONS[lang][key]) {
        const oldText = element.textContent;
        element.textContent = GLOBAL_TRANSLATIONS[lang][key];
        console.log(`  ${index + 1}. "${key}": "${oldText}" → "${GLOBAL_TRANSLATIONS[lang][key]}"`);
      }
    });
    
    // Close dropdown
    const dropdown = document.querySelector('.language-dropdown');
    if (dropdown) {
      dropdown.classList.remove('active');
    }
    
    // Update document language
    document.documentElement.setAttribute('lang', lang);
    
    // Show success notification
    this.showSuccessNotification(lang);
    
    console.log(`✅ Language changed to ${lang} successfully`);
  }
  
  showSuccessNotification(lang) {
    const languageNames = {
      'en': 'English',
      'hi': 'हिंदी',
      'mr': 'मराठी',
      'gu': 'ગુજરાતી',
      'pa': 'ਪੰਜਾਬੀ',
      'ta': 'தமிழ்',
      'te': 'తెలుగు',
      'kn': 'ಕನ್ನಡ',
      'bn': 'বাংলা'
    };
    
    // Create notification
    const notification = document.createElement('div');
    notification.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: linear-gradient(45deg, #e8ff5a, #90EE90);
      color: #222;
      padding: 15px 25px;
      border-radius: 10px;
      font-weight: bold;
      font-size: 14px;
      z-index: 10000;
      box-shadow: 0 5px 15px rgba(0,0,0,0.3);
      animation: slideInRight 0.3s ease;
    `;
    notification.innerHTML = `✅ Language changed to ${languageNames[lang]}`;
    
    // Add animation
    const style = document.createElement('style');
    style.textContent = `
      @keyframes slideInRight {
        from { opacity: 0; transform: translateX(100px); }
        to { opacity: 1; transform: translateX(0); }
      }
    `;
    document.head.appendChild(style);
    
    document.body.appendChild(notification);
    
    // Remove after 3 seconds
    setTimeout(() => {
      notification.remove();
      style.remove();
    }, 3000);
  }
  
  // Get current language
  getCurrentLanguage() {
    return this.currentLanguage;
  }
  
  // Get translation for a key
  getTranslation(key, lang = null) {
    const targetLang = lang || this.currentLanguage;
    return GLOBAL_TRANSLATIONS[targetLang]?.[key] || key;
  }
}

// Make it available globally - let individual pages initialize as needed
window.GlobalTranslationSystem = GlobalTranslationSystem;
window.GLOBAL_TRANSLATIONS = GLOBAL_TRANSLATIONS;