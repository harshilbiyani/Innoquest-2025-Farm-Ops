import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';
import 'services/theme_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/localization_service.dart';

class GrowthTimelinePage extends StatefulWidget {
  final String cropName;
  final Map<String, String>? soilData;
  final Map<String, String>? locationData;

  const GrowthTimelinePage({
    super.key,
    required this.cropName,
    this.soilData,
    this.locationData,
  });

  @override
  State<GrowthTimelinePage> createState() => _GrowthTimelinePageState();
}

class _GrowthTimelinePageState extends State<GrowthTimelinePage> {
  bool isLoading = true;
  Map<String, dynamic>? timelineData;
  String? errorMessage;
  String? selectedSoilType;
  final List<Map<String, String>> soilTypes = [
    {'value': 'clayey_moist', 'label': '🟤 Clay Soil (holds water well)'},
    {'value': 'clayey_dry', 'label': '🟫 Clay Soil (gets hard when dry)'},
    {'value': 'sandy_moist', 'label': '🟨 Sandy Soil (drains water quickly)'},
    {'value': 'sandy_dry', 'label': '🟡 Sandy Soil (very dry)'},
    {
      'value': 'loamy_moist',
      'label': '🟢 Loamy Soil (best for farming - moist)',
    },
    {'value': 'loamy_dry', 'label': '🌱 Loamy Soil (good for farming - dry)'},
    {
      'value': 'black_cotton',
      'label': '⚫ Black Cotton Soil (rich and fertile)',
    },
    {'value': 'red_soil', 'label': '🔴 Red Soil (common in many areas)'},
    {'value': 'alluvial', 'label': '🟠 River/Alluvial Soil (near rivers)'},
    {'value': 'laterite', 'label': '🟣 Laterite Soil (red-orange clay)'},
  ];

  @override
  void initState() {
    super.initState();
    // If we don't have soil data, show soil type selector
    if (widget.soilData == null && widget.locationData == null) {
      setState(() {
        isLoading = false;
      });
    } else {
      _loadTimeline();
    }
  }

  Future<void> _loadTimeline() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.generateGrowthTimeline(
        cropName: widget.cropName,
        soilData: widget.soilData,
        locationData: widget.locationData,
        soilType: selectedSoilType,
      );

      if (mounted) {
        setState(() {
          isLoading = false;
          if (result['success']) {
            timelineData = result;
          } else {
            errorMessage = result['message'] ?? 'Failed to load timeline';
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

  void _onSoilTypeSelected() {
    if (selectedSoilType != null) {
      _loadTimeline();
    }
  }

  String _formatToIndianDate(String dateStr) {
    try {
      // Parse the date string (assuming format like "2024-01-15" or "15/01/2024")
      DateTime date;
      if (dateStr.contains('-')) {
        date = DateTime.parse(dateStr);
      } else if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else {
          return dateStr;
        }
      } else {
        return dateStr;
      }
      
      // Format to Indian date format: DD/MM/YYYY
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr; // Return original if parsing fails
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
                            Icons.timeline,
                            size: 60,
                            color: Color(0xFF008575),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Growth Timeline',
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

                    // Soil Type Selector (if needed)
                    if (widget.soilData == null &&
                        widget.locationData == null &&
                        selectedSoilType == null)
                      _buildSoilTypeSelector(),

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
                                'Generating your personalized timeline...',
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

                    // Timeline Data Display
                    if (timelineData != null && !isLoading) ...[
                      _buildSoilAdviceCard(),
                      const SizedBox(height: 20),
                      _buildTimelinePhases(),
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

  Widget _buildSoilTypeSelector() {
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
            '🏞️ Select Your Soil Type',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedSoilType,
            decoration: InputDecoration(
              filled: true,
              fillColor: context.isDarkMode ? context.cardColor : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2BC24A)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2BC24A)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            hint: Text(
              'Choose your soil type',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            items: soilTypes.map((soil) {
              return DropdownMenuItem<String>(
                value: soil['value'],
                child: Text(
                  soil['label']!,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedSoilType = value;
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedSoilType != null ? _onSoilTypeSelected : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2BC24A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Generate Timeline',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilAdviceCard() {
    final soilAdvice = timelineData!['soil_advice'];
    if (soilAdvice == null) return const SizedBox.shrink();

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
            '🌱 Soil Analysis',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            soilAdvice['description'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: context.secondaryTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Advantages
          if (soilAdvice['advantages'] != null) ...[
            Text(
              '✅ Advantages',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2BC24A),
              ),
            ),
            const SizedBox(height: 8),
            ...List<Widget>.from(
              (soilAdvice['advantages'] as List).map(
                (adv) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          adv,
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Challenges
          if (soilAdvice['challenges'] != null) ...[
            Text(
              '⚠️ Challenges',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFFA726),
              ),
            ),
            const SizedBox(height: 8),
            ...List<Widget>.from(
              (soilAdvice['challenges'] as List).map(
                (challenge) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          challenge,
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Recommendations
          if (soilAdvice['recommendations'] != null) ...[
            Text(
              '💡 Recommendations',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF008575),
              ),
            ),
            const SizedBox(height: 8),
            ...List<Widget>.from(
              (soilAdvice['recommendations'] as List).map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          rec,
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelinePhases() {
    final timeline = timelineData!['timeline'] as List?;
    if (timeline == null || timeline.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📅 Growth Phases',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ...timeline.map((phase) => _buildPhaseCard(phase)).toList(),
      ],
    );
  }

  Widget _buildPhaseCard(Map<String, dynamic> phase) {
    final categoryColors = {
      'Critical': Color(0xFFE53E3E),
      'High': Color(0xFFFFA726),
      'Normal': Color(0xFF2BC24A),
      'Treatment': Color(0xFF9C27B0),
    };

    final color = categoryColors[phase['category']] ?? const Color(0xFF008575);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  phase['task_name'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.isDarkMode ? Colors.white : const Color(0xFF008575),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  phase['category'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatToIndianDate(phase['start_date'])} → ${_formatToIndianDate(phase['end_date'])}',
                  style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                'Duration: ${phase['duration']} days',
                style: GoogleFonts.poppins(fontSize: 13, color: context.textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
