import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'services/theme_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/localization_service.dart';

class WaterConsumptionPage extends StatefulWidget {
  final String cropName;
  final Map<String, String>? soilData;
  final Map<String, String>? locationData;

  const WaterConsumptionPage({
    super.key,
    required this.cropName,
    this.soilData,
    this.locationData,
  });

  @override
  State<WaterConsumptionPage> createState() => _WaterConsumptionPageState();
}

class _WaterConsumptionPageState extends State<WaterConsumptionPage> {
  bool isLoading = true;
  Map<String, dynamic>? waterData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWaterConsumption();
  }

  Future<void> _loadWaterConsumption() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getWaterConsumption(
        cropName: widget.cropName,
        soilData: widget.soilData,
        locationData: widget.locationData,
      );

      if (mounted) {
        setState(() {
          isLoading = false;
          if (result['success']) {
            waterData = result;
          } else {
            errorMessage =
                result['message'] ?? 'Failed to load water consumption data';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      onPressed: () => Navigator.of(context).pop(),
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
                  const SizedBox(width: 48),
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

                    // Title Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.lightGreenBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.water_drop,
                            size: 60,
                            color: Color(0xFF008575),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Water Consumption',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF008575),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.cropName,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2BC24A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Loading State
                    if (isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(
                                color: Color(0xFF008575),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Loading water consumption data...',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: context.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Error State
                    if (errorMessage != null && !isLoading)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: GoogleFonts.poppins(
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Water Data Display
                    if (waterData != null && !isLoading) ...[
                      _buildWaterSummaryCard(),
                      const SizedBox(height: 20),
                      _buildWaterStagesCard(),
                      const SizedBox(height: 20),
                      _buildWaterTipsCard(),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom navigation bar
            const BottomNavBar(currentPage: 'other'),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF008575), Color(0xFF2BC24A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '💧 Total Water Requirement',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            waterData!['total_water'] ?? 'N/A',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'For entire growth cycle',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterStagesCard() {
    final stages = waterData!['stages'] as List?;
    if (stages == null || stages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.lightGreenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2BC24A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Water Needs by Growth Stage',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...stages.map((stage) => _buildStageItem(stage)).toList(),
        ],
      ),
    );
  }

  Widget _buildStageItem(Map<String, dynamic> stage) {
    final intensity = stage['intensity'] ?? 'medium';
    Color intensityColor;
    IconData intensityIcon;

    switch (intensity.toLowerCase()) {
      case 'high':
        intensityColor = const Color(0xFFE53E3E);
        intensityIcon = Icons.water_drop;
        break;
      case 'low':
        intensityColor = const Color(0xFF2BC24A);
        intensityIcon = Icons.water_drop_outlined;
        break;
      default:
        intensityColor = const Color(0xFFFFA726);
        intensityIcon = Icons.water_drop;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode ? context.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: intensityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(intensityIcon, color: intensityColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage['stage'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.isDarkMode ? Colors.white : const Color(0xFF008575),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage['water_amount'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: intensityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              intensity.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: intensityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTipsCard() {
    final tips = waterData!['irrigation_tips'] as List?;
    if (tips == null || tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.lightGreenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2BC24A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Color(0xFFFFA726), size: 24),
              const SizedBox(width: 8),
              Text(
                'Irrigation Tips',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💧 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: context.secondaryTextColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
