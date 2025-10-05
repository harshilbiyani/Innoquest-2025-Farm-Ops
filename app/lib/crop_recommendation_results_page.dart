import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/crop_evaluation_service.dart';
import 'services/theme_provider.dart';
import 'growth_timeline_page.dart';
import 'water_consumption_page.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/localization_service.dart';

class CropRecommendationResultsPage extends StatelessWidget {
  final Map<String, String> results;
  final Map<String, String>? soilData;
  final Map<String, String>? locationData;

  const CropRecommendationResultsPage({
    super.key,
    required this.results,
    this.soilData,
    this.locationData,
  });

  @override
  Widget build(BuildContext context) {
    // Group crops by suitability
    final highlySuitable = <String>[];
    final moderatelySuitable = <String>[];
    final notSuitable = <String>[];

    results.forEach((crop, suitability) {
      if (suitability == "Highly Suitable") {
        highlySuitable.add(crop);
      } else if (suitability == "Moderately Suitable") {
        moderatelySuitable.add(crop);
      } else {
        notSuitable.add(crop);
      }
    });

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and logo
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: context.textColor,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Farm-Ops',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Header card with icon and title
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.lightGreenBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Crop prediction icon
                          Image.asset(
                            'assets/images/crop_prediction_result.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your Crop Recommendations',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF008575),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Based on your soil and climate data',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Highly Suitable Section
                    if (highlySuitable.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Highly Suitable',
                        const Color(0xFF2BC24A),
                        highlySuitable.length,
                      ),
                      const SizedBox(height: 12),
                      _buildCropCards(
                        context,
                        highlySuitable,
                        const Color(0xFF2BC24A),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Moderately Suitable Section
                    if (moderatelySuitable.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Moderately Suitable',
                        const Color(0xFFFFA726),
                        moderatelySuitable.length,
                      ),
                      const SizedBox(height: 12),
                      _buildCropCards(
                        context,
                        moderatelySuitable,
                        const Color(0xFFFFA726),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Not Suitable Section
                    if (notSuitable.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Not Suitable',
                        const Color(0xFFE57373),
                        notSuitable.length,
                      ),
                      const SizedBox(height: 12),
                      _buildCropCards(
                        context,
                        notSuitable,
                        const Color(0xFFE57373),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Note card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.lightGreenBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2BC24A),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: context.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Recommendations based on your soil and climate data. Consult local agricultural experts for best results.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: context.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom navigation bar
            _buildBottomNavBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return const BottomNavBar(currentPage: 'other');
  }

  Widget _buildSectionTitle(String title, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCropCards(
    BuildContext context,
    List<String> crops,
    Color color,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate card width to fit 2 cards per row with spacing
        final cardWidth = (constraints.maxWidth - 12) / 2; // 12 is the spacing between cards
        
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: crops
              .map((crop) => SizedBox(
                    width: cardWidth,
                    child: _buildCropCard(context, crop, color),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildCropCard(BuildContext context, String cropName, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crop icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: context.isDarkMode ? context.cardColor : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              CropEvaluationService.getCropIcon(cropName),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          // Crop name
          Text(
            cropName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.isDarkMode ? Colors.white : const Color(0xFF008575),
            ),
          ),
          const SizedBox(height: 10),
          // Growth Timeline Button
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: () => _showGrowthTimeline(context, cropName),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008575),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                elevation: 2,
              ),
              child: Text(
                'Growth Timeline',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Water Consumption Button
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: () => _showWaterConsumption(context, cropName),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.isDarkMode ? context.cardColor : Colors.white,
                foregroundColor: const Color(0xFF008575),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF008575), width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                elevation: 1,
              ),
              child: Text(
                'Water Consumption',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGrowthTimeline(BuildContext context, String cropName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GrowthTimelinePage(
          cropName: cropName,
          soilData: soilData,
          locationData: locationData,
        ),
      ),
    );
  }

  void _showWaterConsumption(BuildContext context, String cropName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaterConsumptionPage(
          cropName: cropName,
          soilData: soilData,
          locationData: locationData,
        ),
      ),
    );
  }
}
