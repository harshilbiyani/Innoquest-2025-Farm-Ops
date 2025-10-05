import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/theme_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/localization_service.dart';

class WaterRecommendationPage extends StatefulWidget {
  final String cropName;
  final Map<String, String>? soilData;
  final Map<String, String>? locationData;

  const WaterRecommendationPage({
    super.key,
    required this.cropName,
    this.soilData,
    this.locationData,
  });

  @override
  State<WaterRecommendationPage> createState() =>
      _WaterRecommendationPageState();
}

class _WaterRecommendationPageState extends State<WaterRecommendationPage> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  double landArea = 1.0;
  String growthStage = 'vegetative';
  String soilType = 'loamy';
  String season = 'kharif';
  String irrigationMethod = 'drip';

  bool showResults = false;
  Map<String, dynamic>? calculatedData;

  // Dropdown options
  final Map<String, String> growthStages = {
    'vegetative': 'Vegetative Growth',
    'flowering': 'Flowering/Reproductive',
    'maturity': 'Maturity/Harvest',
  };

  final Map<String, String> soilTypes = {
    'loamy': 'Loamy (Ideal)',
    'sandy': 'Sandy',
    'clay': 'Clay',
    'black_cotton': 'Black Cotton',
    'red_soil': 'Red Soil',
    'sandy_dry': 'Sandy Dry',
    'laterite': 'Laterite',
  };

  final Map<String, String> seasons = {
    'kharif': 'Kharif (Monsoon)',
    'rabi': 'Rabi (Winter)',
    'summer': 'Summer',
  };

  final Map<String, String> irrigationMethods = {
    'drip': 'Drip Irrigation (Most Efficient)',
    'sprinkler': 'Sprinkler System',
    'furrow': 'Furrow Irrigation',
    'flood': 'Flood Irrigation',
  };

  @override
  void initState() {
    super.initState();
    _setDefaultsBasedOnCrop();
  }

  void _setDefaultsBasedOnCrop() {
    final crop = widget.cropName.toLowerCase();

    // Set season defaults
    if (['rice', 'cotton', 'soybean'].contains(crop)) {
      season = 'kharif';
    } else if (['wheat', 'potato', 'garlic'].contains(crop)) {
      season = 'rabi';
    }

    // Set irrigation method defaults
    if (['tomato', 'onion'].contains(crop)) {
      irrigationMethod = 'drip';
    } else if (crop == 'rice') {
      irrigationMethod = 'flood';
    }
  }

  void _calculateWaterRequirements() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        calculatedData = _performCalculations();
        showResults = true;
      });
    }
  }

  Map<String, dynamic> _performCalculations() {
    // Base water requirement per hectare per day (in liters)
    // These are typical values - in production, you'd use crop-specific data
    final baseWaterPerHectare = _getBaseWaterRequirement();

    // Apply multipliers
    final stageMultiplier = _getStageMultiplier();
    final soilMultiplier = _getSoilMultiplier();
    final seasonMultiplier = _getSeasonMultiplier();
    final methodEfficiency = _getMethodEfficiency();

    // Calculate daily requirement
    final dailyPerHectare =
        baseWaterPerHectare *
        stageMultiplier *
        soilMultiplier *
        seasonMultiplier;
    final dailyTotal = dailyPerHectare * landArea / methodEfficiency;
    final weeklyTotal = dailyTotal * 7;
    final monthlyTotal = dailyTotal * 30;

    // Cost calculation (₹0.50 per 1000 liters as example)
    final costPer1000L = 0.50;
    final dailyCost = (dailyTotal / 1000) * costPer1000L;
    final monthlyCost = (monthlyTotal / 1000) * costPer1000L;

    // Water saved with drip if using other methods
    final waterSavedWithDrip = irrigationMethod != 'drip'
        ? dailyTotal * (1 - methodEfficiency / 0.90)
        : 0.0;
    final costSavedWithDrip = (waterSavedWithDrip / 1000) * costPer1000L;

    return {
      'water_requirements': {
        'daily_liters': dailyTotal.round(),
        'weekly_liters': weeklyTotal.round(),
        'monthly_liters': monthlyTotal.round(),
        'daily_per_hectare': dailyPerHectare.round(),
        'season_total_liters': (monthlyTotal * 4).round(),
      },
      'cost_estimate': {
        'daily_cost': dailyCost.toStringAsFixed(2),
        'monthly_cost': monthlyCost.toStringAsFixed(2),
        'cost_per_1000l': costPer1000L.toStringAsFixed(2),
      },
      'irrigation_schedule': {
        'frequency': _getIrrigationFrequency(),
        'duration': _getIrrigationDuration(),
        'best_time': 'Early morning (5-8 AM) or evening (5-7 PM)',
        'weekly_sessions': _getWeeklySessions(),
        'stage_note': _getStageNote(),
        'special_instructions': _getSpecialInstructions(),
      },
      'conservation_tips': _getConservationTips(),
      'efficiency_data': {
        'water_saved_with_drip': waterSavedWithDrip.round(),
        'cost_saved_with_drip': costSavedWithDrip.toStringAsFixed(2),
        'method_efficiency': '${(methodEfficiency * 100).round()}%',
      },
      'critical_stages': _getCriticalStages(),
      'land_area': landArea,
      'soil_type': soilTypes[soilType],
      'season': seasons[season],
    };
  }

  double _getBaseWaterRequirement() {
    // Base water per hectare per day in liters
    final crop = widget.cropName.toLowerCase();
    final baseWater = {
      'rice': 10000.0,
      'sugarcane': 8000.0,
      'cotton': 6000.0,
      'wheat': 5000.0,
      'soybean': 5500.0,
      'potato': 5000.0,
      'tomato': 6000.0,
      'onion': 5500.0,
      'garlic': 5000.0,
      'jowar': 4500.0,
      'tur': 5000.0,
      'groundnut': 5500.0,
    };
    return baseWater[crop] ?? 5500.0;
  }

  double _getStageMultiplier() {
    return {
          'vegetative': 1.2,
          'flowering': 1.5,
          'maturity': 0.8,
        }[growthStage] ??
        1.0;
  }

  double _getSoilMultiplier() {
    return {
          'loamy': 1.0,
          'sandy': 1.3,
          'clay': 0.9,
          'black_cotton': 0.95,
          'red_soil': 1.1,
          'sandy_dry': 1.4,
          'laterite': 1.2,
        }[soilType] ??
        1.0;
  }

  double _getSeasonMultiplier() {
    return {
          'kharif': 0.8, // Monsoon - natural rainfall
          'rabi': 1.0,
          'summer': 1.3,
        }[season] ??
        1.0;
  }

  double _getMethodEfficiency() {
    return {
          'drip': 0.90,
          'sprinkler': 0.75,
          'furrow': 0.60,
          'flood': 0.50,
        }[irrigationMethod] ??
        0.70;
  }

  String _getIrrigationFrequency() {
    if (soilType == 'sandy' || soilType == 'sandy_dry') {
      return 'Every 2-3 days';
    } else if (soilType == 'clay' || soilType == 'black_cotton') {
      return 'Every 5-7 days';
    }
    return 'Every 3-5 days';
  }

  String _getIrrigationDuration() {
    if (irrigationMethod == 'drip') {
      return '2-3 hours per session';
    } else if (irrigationMethod == 'sprinkler') {
      return '3-4 hours per session';
    }
    return '4-6 hours per session';
  }

  int _getWeeklySessions() {
    if (soilType == 'sandy' || soilType == 'sandy_dry') {
      return growthStage == 'flowering' ? 4 : 3;
    }
    return growthStage == 'flowering' ? 3 : 2;
  }

  String _getStageNote() {
    return {
          'vegetative': 'Focus on consistent moisture for root development',
          'flowering':
              'Critical stage - never let plants stress from water deficit',
          'maturity': 'Reduce irrigation to improve quality and storability',
        }[growthStage] ??
        '';
  }

  String _getSpecialInstructions() {
    final crop = widget.cropName.toLowerCase();
    if (crop == 'rice') {
      return 'Maintain 5-10 cm standing water during active growth';
    } else if (crop == 'potato' || crop == 'tomato') {
      return 'Avoid overhead irrigation after flowering to prevent disease';
    } else if (crop == 'wheat') {
      return 'Critical irrigation at crown root, flowering, and grain filling';
    }
    return 'Monitor soil moisture regularly and adjust based on weather';
  }

  List<String> _getConservationTips() {
    return [
      '💧 Use mulching to reduce water evaporation by 30-40%',
      '⏰ Irrigate during early morning or late evening to minimize losses',
      '📊 Install soil moisture sensors for precise irrigation',
      '🌱 Practice drip irrigation for up to 50% water savings',
      '🌾 Use drought-resistant varieties when possible',
      '💡 Collect and reuse rainwater during monsoon season',
    ];
  }

  List<String> _getCriticalStages() {
    final crop = widget.cropName.toLowerCase();
    if (crop == 'wheat') {
      return [
        'crown_root_initiation',
        'tillering',
        'flowering',
        'grain_filling',
      ];
    } else if (crop == 'rice') {
      return ['tillering', 'panicle_initiation', 'flowering', 'grain_filling'];
    } else if (crop == 'cotton') {
      return ['square_formation', 'flowering', 'boll_development'];
    }
    return ['vegetative_growth', 'flowering', 'fruit_development'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: context.primaryColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Farm-Ops',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: context.primaryColor,
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // Header Card
                      Container(
                        width: double.infinity,
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
                          children: [
                            const Icon(
                              Icons.water_drop,
                              size: 60,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${widget.cropName} Water Requirements',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Calculate precise water needs based on your farming conditions',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Input Form
                      _buildInputSection(),

                      const SizedBox(height: 24),

                      // Calculate Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _calculateWaterRequirements,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2BC24A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            '💧 Calculate Water Requirements',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Results Section
                      if (showResults && calculatedData != null) ...[
                        _buildResultsSection(),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.lightGreenBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildNumberInput(
            label: '🌾 Land Area (Hectares)',
            value: landArea,
            onChanged: (val) => setState(() => landArea = val),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: '🌱 Growth Stage',
            value: growthStage,
            items: growthStages,
            onChanged: (val) => setState(() => growthStage = val!),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: '🏔️ Soil Type',
            value: soilType,
            items: soilTypes,
            onChanged: (val) => setState(() => soilType = val!),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: '🌤️ Growing Season',
            value: season,
            items: seasons,
            onChanged: (val) => setState(() => season = val!),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: '💧 Irrigation Method',
            value: irrigationMethod,
            items: irrigationMethods,
            onChanged: (val) => setState(() => irrigationMethod = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required double value,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value.toString(),
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(fontSize: 14, color: context.textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Required';
            final num = double.tryParse(val);
            if (num == null || num <= 0) return 'Must be > 0';
            return null;
          },
          onChanged: (val) {
            final num = double.tryParse(val);
            if (num != null && num > 0) onChanged(num);
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14, color: context.textColor),
          dropdownColor: context.cardColor,
          items: items.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    final waterReq = calculatedData!['water_requirements'];
    final cost = calculatedData!['cost_estimate'];
    final schedule = calculatedData!['irrigation_schedule'];
    final tips = calculatedData!['conservation_tips'] as List;
    final efficiency = calculatedData!['efficiency_data'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Water Requirements',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.primaryColor,
          ),
        ),
        const SizedBox(height: 16),

        // Quick Stats Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard(
              '${_formatNumber(waterReq['daily_liters'])} L',
              'Per Day',
            ),
            _buildStatCard(
              '${_formatNumber(waterReq['weekly_liters'])} L',
              'Per Week',
            ),
            _buildStatCard(
              '${_formatNumber(waterReq['monthly_liters'])} L',
              'Per Month',
            ),
            _buildStatCard('₹${cost['daily_cost']}', 'Daily Cost'),
          ],
        ),

        const SizedBox(height: 24),

        // Irrigation Schedule
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📅 Irrigation Schedule',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildScheduleRow('Frequency', schedule['frequency']),
              _buildScheduleRow('Duration', schedule['duration']),
              _buildScheduleRow('Best Time', schedule['best_time']),
              _buildScheduleRow(
                'Weekly Sessions',
                schedule['weekly_sessions'].toString(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.lightGreenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  schedule['stage_note'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Conservation Tips
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💡 Water Conservation Tips',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 12),
              ...tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    tip,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: context.secondaryTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (efficiency['water_saved_with_drip'] > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💧 Efficiency Improvement Opportunity',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Water Savings with Drip: ${_formatNumber(efficiency['water_saved_with_drip'])} L/day',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                  ),
                ),
                Text(
                  'Cost Savings: ₹${efficiency['cost_saved_with_drip']}/day',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE2FCE1), Color(0xFFF0FFF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: context.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: context.secondaryTextColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }

  Widget _buildBottomNavBar() {
    return const BottomNavBar(currentPage: 'other');
  }
}
