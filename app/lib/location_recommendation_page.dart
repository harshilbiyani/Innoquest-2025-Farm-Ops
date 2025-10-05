import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/theme_provider.dart';
import 'services/api_service.dart';
import 'crop_recommendation_results_page.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/localization_service.dart';

class LocationRecommendationPage extends StatefulWidget {
  const LocationRecommendationPage({super.key});

  @override
  State<LocationRecommendationPage> createState() =>
      _LocationRecommendationPageState();
}

class _LocationRecommendationPageState
    extends State<LocationRecommendationPage> {
  String? selectedState;
  String? selectedDistrict;
  String? selectedBlock;
  String? selectedVillage;

  // Dynamic data from backend
  List<String> states = [];
  List<String> districts = [];
  List<String> blocks = [];
  List<String> villages = [];

  bool isLoadingStates = false;
  bool isLoadingDistricts = false;
  bool isLoadingBlocks = false;
  bool isLoadingVillages = false;
  bool isRecommending = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    setState(() {
      isLoadingStates = true;
    });

    try {
      final result = await ApiService.getStates();

      if (result['success'] && mounted) {
        setState(() {
          states = List<String>.from(result['states']);
          isLoadingStates = false;
        });
      } else if (mounted) {
        setState(() {
          isLoadingStates = false;
        });
        _showSnackBar(
          result['message'] ?? 'Failed to load states',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingStates = false;
        });
        _showSnackBar('Error loading states: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _loadDistricts(String state) async {
    setState(() {
      isLoadingDistricts = true;
      districts = [];
      blocks = [];
      villages = [];
      selectedDistrict = null;
      selectedBlock = null;
      selectedVillage = null;
    });

    try {
      final result = await ApiService.getDistricts(state);

      if (result['success'] && mounted) {
        setState(() {
          districts = List<String>.from(result['districts']);
          isLoadingDistricts = false;
        });
      } else if (mounted) {
        setState(() {
          isLoadingDistricts = false;
        });
        _showSnackBar(
          result['message'] ?? 'Failed to load districts',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingDistricts = false;
        });
        _showSnackBar(
          'Error loading districts: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadBlocks(String state, String district) async {
    setState(() {
      isLoadingBlocks = true;
      blocks = [];
      villages = [];
      selectedBlock = null;
      selectedVillage = null;
    });

    try {
      final result = await ApiService.getBlocks(state, district);

      if (result['success'] && mounted) {
        setState(() {
          blocks = List<String>.from(result['blocks']);
          isLoadingBlocks = false;
        });
      } else if (mounted) {
        setState(() {
          isLoadingBlocks = false;
        });
        _showSnackBar(
          result['message'] ?? 'Failed to load blocks',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingBlocks = false;
        });
        _showSnackBar('Error loading blocks: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _loadVillages(
    String state,
    String district,
    String block,
  ) async {
    setState(() {
      isLoadingVillages = true;
      villages = [];
      selectedVillage = null;
    });

    try {
      final result = await ApiService.getVillages(state, district, block);

      if (result['success'] && mounted) {
        setState(() {
          villages = List<String>.from(result['villages']);
          isLoadingVillages = false;
        });
      } else if (mounted) {
        setState(() {
          isLoadingVillages = false;
        });
        _showSnackBar(
          result['message'] ?? 'Failed to load villages',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingVillages = false;
        });
        _showSnackBar('Error loading villages: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _recommendCrops() async {
    if (selectedState == null ||
        selectedDistrict == null ||
        selectedBlock == null ||
        selectedVillage == null) {
      _showSnackBar('Please fill all fields', isError: true);
      return;
    }

    setState(() {
      isRecommending = true;
    });

    try {
      final result = await ApiService.getCropSuitability(
        state: selectedState!,
        district: selectedDistrict!,
        block: selectedBlock!,
        village: selectedVillage!,
      );

      if (mounted) {
        setState(() {
          isRecommending = false;
        });

        if (result['success']) {
          // Navigate to results page with crop data
          final Map<String, String> cropData = {};
          final crops = result['crops'] as Map<String, dynamic>;
          crops.forEach((key, value) {
            cropData[key] = value.toString();
          });

          // Prepare location data for timeline generation
          final Map<String, String> locationData = {
            'state': selectedState!,
            'district': selectedDistrict!,
            'block': selectedBlock!,
            'village': selectedVillage!,
          };

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CropRecommendationResultsPage(
                results: cropData,
                locationData: locationData,
              ),
            ),
          );
        } else {
          _showSnackBar(
            result['message'] ?? 'Failed to get recommendations',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isRecommending = false;
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
              child: SingleChildScrollView(
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
                          // Location icon
                          Image.asset(
                            'assets/images/location_recommendation.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Location Based Crop Recommendation',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Discover which crops grow best for\nyou, based on your location',
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

                    // State dropdown
                    _buildDropdownField(
                      label: 'State',
                      hint: 'Your state name',
                      value: selectedState,
                      items: states,
                      isLoading: isLoadingStates,
                      onChanged: (value) {
                        setState(() {
                          selectedState = value;
                          selectedDistrict = null;
                          selectedBlock = null;
                          selectedVillage = null;
                        });
                        if (value != null) {
                          _loadDistricts(value);
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // District dropdown
                    _buildDropdownField(
                      label: 'District',
                      hint: 'Your district name',
                      value: selectedDistrict,
                      items: districts,
                      isLoading: isLoadingDistricts,
                      onChanged: selectedState != null
                          ? (value) {
                              setState(() {
                                selectedDistrict = value;
                                selectedBlock = null;
                                selectedVillage = null;
                              });
                              if (value != null) {
                                _loadBlocks(selectedState!, value);
                              }
                            }
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // Block dropdown
                    _buildDropdownField(
                      label: 'Block',
                      hint: 'Your block name',
                      value: selectedBlock,
                      items: blocks,
                      isLoading: isLoadingBlocks,
                      onChanged: selectedDistrict != null
                          ? (value) {
                              setState(() {
                                selectedBlock = value;
                                selectedVillage = null;
                              });
                              if (value != null) {
                                _loadVillages(
                                  selectedState!,
                                  selectedDistrict!,
                                  value,
                                );
                              }
                            }
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // Village dropdown
                    _buildDropdownField(
                      label: 'Village',
                      hint: 'Your village name',
                      value: selectedVillage,
                      items: villages,
                      isLoading: isLoadingVillages,
                      onChanged: selectedBlock != null
                          ? (value) {
                              setState(() {
                                selectedVillage = value;
                              });
                            }
                          : null,
                    ),

                    const SizedBox(height: 32),

                    // Recommend Crops button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isRecommending ? null : _recommendCrops,
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
                        child: isRecommending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
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
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
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
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Loading...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: value,
                    hint: Text(
                      hint,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: context.secondaryTextColor,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: context.secondaryTextColor,
                    ),
                    focusColor: Colors.transparent,
                    dropdownColor: context.cardColor,
                    items: items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: context.textColor,
                          ),
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
                              fontSize: 14,
                              color: context.textColor,
                            ),
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
