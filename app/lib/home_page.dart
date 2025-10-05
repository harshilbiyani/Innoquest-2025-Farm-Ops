import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'language_selection_page.dart';
import 'services/user_preferences.dart';
import 'services/theme_provider.dart';
import 'services/localization_service.dart';
import 'widgets/bottom_nav_bar.dart';
import 'location_recommendation_page.dart';
import 'soil_recommendation_page.dart';
import 'professional_advisor_page.dart';
import 'weather_forecast_page.dart';
import 'market_analysis_page.dart';
import 'government_schemes_page.dart';
import 'disease_detection_page.dart';
import 'profit_loss_calculator_page.dart';

class HomePage extends StatefulWidget {
  final String mobileNumber;

  const HomePage({super.key, required this.mobileNumber});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Feature data - dynamically get titles based on language
  List<Map<String, dynamic>> _getFeatures(BuildContext context) {
    final loc = context.localizations;
    return [
      {
        'title': loc.locationBasedRecommendation,
        'image': 'assets/images/location_recommendation.png',
        'route': '/location-recommendation',
      },
      {
        'title': loc.soilBasedCropRecommendation,
        'image': 'assets/images/soil_recommendation.png',
        'route': '/soil-recommendation',
      },
      {
        'title': loc.professionalAdvisor,
        'image': 'assets/images/professional_advisor.png',
        'route': '/professional-advisor',
      },
      {
        'title': loc.governmentSchemes,
        'image': 'assets/images/government_schemes.png',
        'route': '/government-schemes',
      },
      {
        'title': loc.weatherForecast,
        'image': 'assets/images/weather_forecast.png',
        'route': '/weather-forecast',
      },
      {
        'title': loc.diseaseDetection,
        'image': 'assets/images/disease_detection.png',
        'route': '/disease-detection',
      },
      {
        'title': loc.marketAnalysis,
        'image': 'assets/images/market_analysis.png',
        'route': '/market-analysis',
      },
      {
        'title': loc.profitLossCalculator,
        'image': 'assets/images/profitloss_calculator.png',
        'route': '/profit-loss-calculator',
      },
    ];
  }

  void _onFeatureTap(String route, String title) {
    // Navigate to feature pages
    print('Navigate to: $route');

    if (route == '/location-recommendation') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const LocationRecommendationPage(),
        ),
      );
    } else if (route == '/soil-recommendation') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SoilRecommendationPage()),
      );
    } else if (route == '/professional-advisor') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ProfessionalAdvisorPage(),
        ),
      );
    } else if (route == '/weather-forecast') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const WeatherForecastPage()),
      );
    } else if (route == '/market-analysis') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const MarketAnalysisPage()),
      );
    } else if (route == '/government-schemes') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const GovernmentSchemesPage()),
      );
    } else if (route == '/disease-detection') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const DiseaseDetectionPage()),
      );
    } else if (route == '/profit-loss-calculator') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ProfitLossCalculatorPage(),
        ),
      );
    } else {
      // Show coming soon for other features
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title - Coming Soon!', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFF2BC24A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    final loc = context.localizations;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            loc.logout,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 7, 250, 120),
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color.fromARGB(255, 72, 231, 24),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                loc.cancel,
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                // Clear user session
                await UserPreferences.clearUserSession();
                print('🚪 User logged out - session cleared');

                // Navigate to language selection page (start of app)
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LanguageSelectionPage(),
                    ),
                    (route) => false, // Remove all previous routes
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2BC24A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                loc.logout,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with logout button and logo
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logout button on the left
                  GestureDetector(
                    onTap: _showLogoutDialog,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logout.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  // Logo in the center
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        context.farmOpsLogo,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Dark mode toggle on the right
                  GestureDetector(
                    onTap: () {
                      final themeProvider = Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      );
                      themeProvider.toggleTheme();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return Icon(
                            themeProvider.isDarkMode
                                ? Icons.light_mode
                                : Icons.dark_mode,
                            color: const Color(0xFF008575),
                            size: 24,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Features Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _getFeatures(context).length,
                  itemBuilder: (context, index) {
                    final features = _getFeatures(context);
                    return _buildFeatureCard(
                      features[index]['title'],
                      features[index]['image'],
                      features[index]['route'],
                    );
                  },
                ),
              ),
            ),

            // Bottom navigation bar
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String imagePath, String route) {
    return GestureDetector(
      onTap: () => _onFeatureTap(route, title),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF008575), // Teal green color
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Feature icon/image
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 90,
                    maxWidth: 90,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 8),
              // Feature title
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavBar(currentPage: 'home', mobileNumber: widget.mobileNumber);
  }
}
