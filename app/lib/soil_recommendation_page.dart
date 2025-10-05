import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/api_service.dart';
import 'services/theme_provider.dart';
import 'crop_recommendation_results_page.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/localization_service.dart';

class SoilRecommendationPage extends StatefulWidget {
  const SoilRecommendationPage({super.key});

  @override
  State<SoilRecommendationPage> createState() => _SoilRecommendationPageState();
}

class _SoilRecommendationPageState extends State<SoilRecommendationPage> {
  // Dropdown values
  String? nitrogen;
  String? phosphorus;
  String? potassium;
  String? oc;
  String? ec;
  String? ph;
  String? copper;
  String? boron;
  String? sulphur;
  String? iron;
  String? zinc;
  String? manganese;
  String? tempSummer;
  String? tempWinter;
  String? tempMonsoon;
  String? rainfall;

  // Dynamic attribute options from backend
  Map<String, List<String>> attributes = {};
  bool isLoadingAttributes = false;
  bool isEvaluating = false;

  @override
  void initState() {
    super.initState();
    _loadAttributes();
  }

  Future<void> _loadAttributes() async {
    setState(() {
      isLoadingAttributes = true;
    });

    try {
      final result = await ApiService.getCropAttributes();

      if (result['success'] && mounted) {
        final Map<String, dynamic> attributesData = result['attributes'];
        final Map<String, List<String>> loadedAttributes = {};

        attributesData.forEach((key, value) {
          if (value is List) {
            loadedAttributes[key] = List<String>.from(value);
          }
        });

        setState(() {
          attributes = loadedAttributes;
          isLoadingAttributes = false;
        });
      } else if (mounted) {
        setState(() {
          isLoadingAttributes = false;
        });
        _showSnackBar(
          result['message'] ?? 'Failed to load attributes',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingAttributes = false;
        });
        _showSnackBar(
          'Error loading attributes: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _recommendCrops() async {
    if (nitrogen == null ||
        phosphorus == null ||
        potassium == null ||
        oc == null ||
        ec == null ||
        ph == null ||
        copper == null ||
        boron == null ||
        sulphur == null ||
        iron == null ||
        zinc == null ||
        manganese == null ||
        tempSummer == null ||
        tempWinter == null ||
        tempMonsoon == null ||
        rainfall == null) {
      _showSnackBar('Please fill all fields', isError: true);
      return;
    }

    setState(() {
      isEvaluating = true;
    });

    // Prepare input data for evaluation
    Map<String, String> inputData = {
      'Nitrogen': nitrogen!,
      'Phosphorus': phosphorus!,
      'Potassium': potassium!,
      'OC': oc!,
      'EC': ec!,
      'pH': ph!,
      'Copper': copper!,
      'Boron': boron!,
      'Sulphur': sulphur!,
      'Iron': iron!,
      'Zinc': zinc!,
      'Manganese': manganese!,
      'Temperature_Summer': tempSummer!,
      'Temperature_Winter': tempWinter!,
      'Temperature_Monsoon': tempMonsoon!,
      'Rainfall': rainfall!,
    };

    try {
      final result = await ApiService.evaluateCrops(inputData);

      if (mounted) {
        setState(() {
          isEvaluating = false;
        });

        if (result['success']) {
          // Convert crops map to Map<String, String>
          final Map<String, String> cropResults = {};
          final crops = result['crops'] as Map<String, dynamic>;
          crops.forEach((key, value) {
            cropResults[key] = value.toString();
          });

          // Navigate to results page with soil data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CropRecommendationResultsPage(
                results: cropResults,
                soilData: inputData,
              ),
            ),
          );
        } else {
          _showSnackBar(
            result['message'] ?? 'Failed to evaluate crops',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isEvaluating = false;
        });
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red : const Color(0xFF2BC24A),
      ),
    );
  }

  Future<void> _showSoilTestDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.science_outlined,
                color: Color(0xFF2BC24A),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Soil Test',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF008575),
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Do you want to take a soil test through our platform?\n\nWe\'ll help you get accurate soil nutrient data for better crop recommendations.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color.fromARGB(255, 7, 234, 56),
              height: 1.5,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'No, I have data',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Launch Google Form
                final Uri url = Uri.parse(
                  'https://forms.gle/hXhmFMqmxAHEckyy5',
                );
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (mounted) {
                    _showSnackBar(
                      'Could not open the form. Please check your internet connection.',
                      isError: true,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2BC24A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Yes, take test',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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
            // Header with back button and logo
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
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
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
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Content
            Expanded(
              child: isLoadingAttributes
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF2BC24A),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading form...',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
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
                                // Soil icon
                                Image.asset(
                                  'assets/images/soil_recommendation.png',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Soil Based Crop Recommendation',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: context.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Discover which crops grow best for\nyou, based on your soil nutrients',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: context.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Soil Test Prompt Card
                          GestureDetector(
                            onTap: _showSoilTestDialog,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2BC24A),
                                    Color(0xFF1EA337),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2BC24A,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.science_outlined,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Need a Soil Test?',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Get accurate soil analysis through our platform',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // All fields in 2-column layout
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Nitrogen',
                                  value: nitrogen,
                                  items: attributes["Nitrogen"]!,
                                  onChanged: (val) =>
                                      setState(() => nitrogen = val),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Phosphorus',
                                  value: phosphorus,
                                  items: attributes["Phosphorus"]!,
                                  onChanged: (val) =>
                                      setState(() => phosphorus = val),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Potassium',
                                  value: potassium,
                                  items: attributes["Potassium"]!,
                                  onChanged: (val) =>
                                      setState(() => potassium = val),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'OC',
                                  value: oc,
                                  items: attributes["OC"]!,
                                  onChanged: (val) => setState(() => oc = val),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'EC',
                                  value: ec,
                                  items: attributes["EC"]!,
                                  onChanged: (val) => setState(() => ec = val),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'pH',
                                  value: ph,
                                  items: attributes["pH"]!,
                                  onChanged: (val) => setState(() => ph = val),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Copper',
                                  value: copper,
                                  items: attributes["Copper"]!,
                                  onChanged: (val) =>
                                      setState(() => copper = val),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Boron',
                                  value: boron,
                                  items: attributes["Boron"]!,
                                  onChanged: (val) =>
                                      setState(() => boron = val),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Sulphur',
                                  value: sulphur,
                                  items: attributes["Sulphur"]!,
                                  onChanged: (val) =>
                                      setState(() => sulphur = val),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Iron',
                                  value: iron,
                                  items: attributes["Iron"]!,
                                  onChanged: (val) =>
                                      setState(() => iron = val),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Zinc',
                                  value: zinc,
                                  items: attributes["Zinc"]!,
                                  onChanged: (val) =>
                                      setState(() => zinc = val),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Manganese',
                                  value: manganese,
                                  items: attributes["Manganese"]!,
                                  onChanged: (val) =>
                                      setState(() => manganese = val),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Temperature Summer',
                                  value: tempSummer,
                                  items: attributes["Temperature_Summer"]!,
                                  onChanged: (val) =>
                                      setState(() => tempSummer = val),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Temperature Winter',
                                  value: tempWinter,
                                  items: attributes["Temperature_Winter"]!,
                                  onChanged: (val) =>
                                      setState(() => tempWinter = val),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Temperature Monsoon',
                                  value: tempMonsoon,
                                  items: attributes["Temperature_Monsoon"]!,
                                  onChanged: (val) =>
                                      setState(() => tempMonsoon = val),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Rainfall',
                                  value: rainfall,
                                  items: attributes["Rainfall"]!,
                                  onChanged: (val) =>
                                      setState(() => rainfall = val),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Recommend Crops button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isEvaluating ? null : _recommendCrops,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2BC24A),
                                disabledBackgroundColor: const Color(
                                  0xFF2BC24A,
                                ).withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: isEvaluating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Recommend Crops',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
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
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: context.borderColor, width: 1.5),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(
                'Select',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: context.secondaryTextColor,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: context.secondaryTextColor,
                size: 20,
              ),
              focusColor: Colors.transparent,
              dropdownColor: context.cardColor,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: context.textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              selectedItemBuilder: (BuildContext context) {
                return items.map((String item) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: context.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return const BottomNavBar(currentPage: 'other');
  }
}
