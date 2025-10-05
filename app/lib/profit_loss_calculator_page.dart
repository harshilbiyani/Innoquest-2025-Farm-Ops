import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/theme_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/localization_service.dart';

class ProfitLossCalculatorPage extends StatefulWidget {
  const ProfitLossCalculatorPage({super.key});

  @override
  State<ProfitLossCalculatorPage> createState() =>
      _ProfitLossCalculatorPageState();
}

class _ProfitLossCalculatorPageState extends State<ProfitLossCalculatorPage> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  String? selectedCrop; // Stores the crop key (e.g., 'rice')
  String? selectedCropName; // Stores the display name (e.g., 'Rice')

  // Dropdown selections
  String? selectedFarmArea;
  String? selectedExpectedYield;
  String? selectedMarketPrice;
  String? selectedSeedCost;
  String? selectedFertilizerCost;
  String? selectedPesticideCost;
  String? selectedLaborCost;
  String? selectedOtherCost;
  String? selectedLoanAmount;
  String? selectedInterestRate;

  // Dropdown options
  final List<String> farmAreaOptions = [
    '0.5 - 1 acre',
    '1 - 2 acres',
    '2 - 5 acres',
    '5 - 10 acres',
    '10 - 20 acres',
    '20+ acres',
  ];

  final List<String> costRangeOptions = [
    '₹0 - ₹5,000',
    '₹5,000 - ₹10,000',
    '₹10,000 - ₹20,000',
    '₹20,000 - ₹50,000',
    '₹50,000 - ₹1,00,000',
    '₹1,00,000 - ₹2,00,000',
    '₹2,00,000+',
  ];

  final List<String> loanAmountOptions = [
    'No Loan',
    '₹10,000 - ₹50,000',
    '₹50,000 - ₹1,00,000',
    '₹1,00,000 - ₹2,00,000',
    '₹2,00,000 - ₹5,00,000',
    '₹5,00,000+',
  ];

  final List<String> interestRateOptions = [
    '0% (No Loan)',
    '4% - 7% (Subsidized)',
    '7% - 10% (KCC)',
    '10% - 12% (Bank)',
    '12% - 15% (Private)',
    '15%+',
  ];

  final List<String> yieldOptions = [
    '5 - 10 quintals/acre',
    '10 - 15 quintals/acre',
    '15 - 25 quintals/acre',
    '25 - 100 quintals/acre',
    '100 - 200 quintals/acre',
    '200+ quintals/acre',
  ];

  final List<String> priceOptions = [
    '₹500 - ₹1,000/quintal',
    '₹1,000 - ₹2,000/quintal',
    '₹2,000 - ₹3,000/quintal',
    '₹3,000 - ₹5,000/quintal',
    '₹5,000 - ₹8,000/quintal',
    '₹8,000+/quintal',
  ];

  // Helper method to extract numeric value from dropdown selection
  double _extractValue(String? selection) {
    if (selection == null || selection.isEmpty) return 0;
    if (selection == 'No Loan' || selection == '0% (No Loan)') return 0;

    // Extract the first number from the string
    final regex = RegExp(r'[\d,]+');
    final match = regex.firstMatch(selection);
    if (match != null) {
      final numStr = match.group(0)!.replaceAll(',', '');
      return double.tryParse(numStr) ?? 0;
    }
    return 0;
  }

  // Helper method to get midpoint of range
  double _getMidpoint(String? selection) {
    if (selection == null || selection.isEmpty) return 0;
    if (selection == 'No Loan' || selection == '0% (No Loan)') return 0;

    // Handle "+" ranges (use lower bound)
    if (selection.contains('+')) {
      return _extractValue(selection);
    }

    // Extract both numbers for ranges
    final numbers = RegExp(r'[\d,]+')
        .allMatches(selection)
        .map((m) => double.parse(m.group(0)!.replaceAll(',', '')))
        .toList();

    if (numbers.length == 2) {
      return (numbers[0] + numbers[1]) / 2;
    } else if (numbers.length == 1) {
      return numbers[0];
    }
    return 0;
  }

  // Results
  bool showResults = false;
  double totalProduction = 0;
  double totalRevenue = 0;
  double operationalCosts = 0;
  double totalCosts = 0;
  double netProfit = 0;
  double profitMargin = 0;
  double roi = 0;
  double costPerAcre = 0;
  double revenuePerAcre = 0;
  double annualInterest = 0;
  double totalLoanRepayment = 0;
  double monthlyEMI = 0;

  List<String> suggestions = [];

  // Crop data
  final Map<String, Map<String, dynamic>> cropData = {
    'rice': {
      'name': 'Rice',
      'avgYield': 20.0,
      'avgPrice': 2500.0,
      'riskFactor': 0.8,
    },
    'wheat': {
      'name': 'Wheat',
      'avgYield': 15.0,
      'avgPrice': 2200.0,
      'riskFactor': 0.7,
    },
    'cotton': {
      'name': 'Cotton',
      'avgYield': 12.0,
      'avgPrice': 6000.0,
      'riskFactor': 0.9,
    },
    'sugarcane': {
      'name': 'Sugarcane',
      'avgYield': 600.0,
      'avgPrice': 350.0,
      'riskFactor': 0.6,
    },
    'soybean': {
      'name': 'Soybean',
      'avgYield': 14.0,
      'avgPrice': 4500.0,
      'riskFactor': 0.8,
    },
    'groundnut': {
      'name': 'Groundnut',
      'avgYield': 18.0,
      'avgPrice': 5500.0,
      'riskFactor': 0.8,
    },
    'tomato': {
      'name': 'Tomato',
      'avgYield': 250.0,
      'avgPrice': 1500.0,
      'riskFactor': 1.2,
    },
    'onion': {
      'name': 'Onion',
      'avgYield': 200.0,
      'avgPrice': 2000.0,
      'riskFactor': 1.0,
    },
    'potato': {
      'name': 'Potato',
      'avgYield': 180.0,
      'avgPrice': 1800.0,
      'riskFactor': 0.9,
    },
    'garlic': {
      'name': 'Garlic',
      'avgYield': 80.0,
      'avgPrice': 8000.0,
      'riskFactor': 1.1,
    },
    'jowar': {
      'name': 'Jowar',
      'avgYield': 12.0,
      'avgPrice': 2800.0,
      'riskFactor': 0.8,
    },
    'tur': {
      'name': 'Tur (Pigeon Pea)',
      'avgYield': 10.0,
      'avgPrice': 6500.0,
      'riskFactor': 0.9,
    },
  };

  @override
  void dispose() {
    // No controllers to dispose
    super.dispose();
  }

  void _onCropSelected(String? crop) {
    if (crop != null && cropData.containsKey(crop)) {
      setState(() {
        selectedCrop = crop;
        selectedCropName = cropData[crop]!['name'] as String;
        // Auto-select expected yield based on crop
        final avgYield = cropData[crop]!['avgYield'];
        if (avgYield <= 10) {
          selectedExpectedYield = '5 - 10 quintals/acre';
        } else if (avgYield <= 15) {
          selectedExpectedYield = '10 - 15 quintals/acre';
        } else if (avgYield <= 25) {
          selectedExpectedYield = '15 - 25 quintals/acre';
        } else if (avgYield <= 100) {
          selectedExpectedYield = '25 - 100 quintals/acre';
        } else if (avgYield <= 200) {
          selectedExpectedYield = '100 - 200 quintals/acre';
        } else {
          selectedExpectedYield = '200+ quintals/acre';
        }

        // Auto-select market price based on crop
        final avgPrice = cropData[crop]!['avgPrice'];
        if (avgPrice <= 2000) {
          selectedMarketPrice = '₹1,000 - ₹2,000/quintal';
        } else if (avgPrice <= 3000) {
          selectedMarketPrice = '₹2,000 - ₹3,000/quintal';
        } else if (avgPrice <= 5000) {
          selectedMarketPrice = '₹3,000 - ₹5,000/quintal';
        } else if (avgPrice <= 8000) {
          selectedMarketPrice = '₹5,000 - ₹8,000/quintal';
        } else {
          selectedMarketPrice = '₹8,000+/quintal';
        }
      });
    }
  }

  void _calculateProfitLoss() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if all required dropdowns are selected
    if (selectedCrop == null ||
        selectedFarmArea == null ||
        selectedExpectedYield == null ||
        selectedMarketPrice == null ||
        selectedSeedCost == null ||
        selectedFertilizerCost == null ||
        selectedPesticideCost == null ||
        selectedLaborCost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all required fields',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double farmArea = _getMidpoint(selectedFarmArea);
    final double expectedYield = _getMidpoint(selectedExpectedYield);
    final double marketPrice = _getMidpoint(selectedMarketPrice);
    final double seedCost = _getMidpoint(selectedSeedCost);
    final double fertilizerCost = _getMidpoint(selectedFertilizerCost);
    final double pesticideCost = _getMidpoint(selectedPesticideCost);
    final double laborCost = _getMidpoint(selectedLaborCost);
    final double otherCost = _getMidpoint(selectedOtherCost);
    final double loanAmount = _getMidpoint(selectedLoanAmount);
    final double interestRate = _extractValue(selectedInterestRate);

    setState(() {
      totalProduction = farmArea * expectedYield;
      totalRevenue = totalProduction * marketPrice;
      operationalCosts =
          seedCost + fertilizerCost + pesticideCost + laborCost + otherCost;

      annualInterest = (loanAmount * interestRate) / 100;
      totalLoanRepayment = loanAmount + annualInterest;
      monthlyEMI = totalLoanRepayment / 12;

      totalCosts = operationalCosts + totalLoanRepayment;
      netProfit = totalRevenue - totalCosts;
      profitMargin = totalRevenue > 0 ? ((netProfit / totalRevenue) * 100) : 0;
      roi = totalCosts > 0 ? ((netProfit / totalCosts) * 100) : 0;
      costPerAcre = totalCosts / farmArea;
      revenuePerAcre = totalRevenue / farmArea;

      showResults = true;
      _generateSuggestions();
    });

    // Scroll to results
    Future.delayed(const Duration(milliseconds: 300), () {
      // Scroll to bottom to show results
    });
  }

  void _generateSuggestions() {
    suggestions.clear();
    final cropInfo = cropData[selectedCrop];

    // Loan-specific suggestions
    if (totalLoanRepayment > 0) {
      final loanToRevenueRatio = (totalLoanRepayment / totalRevenue) * 100;

      if (totalRevenue < totalLoanRepayment) {
        suggestions.add(
          'Critical: Your revenue may not cover loan repayment. Consider crop insurance or alternative income sources.',
        );
      } else if (loanToRevenueRatio > 70) {
        suggestions.add(
          'High loan burden detected. Consider extending loan tenure or reducing interest rate through government schemes.',
        );
      } else if (loanToRevenueRatio < 30) {
        suggestions.add(
          'Good loan management! Your loan repayment is well within manageable limits.',
        );
      }

      final interestRate = _extractValue(selectedInterestRate);
      if (interestRate > 12) {
        suggestions.add(
          'High interest rate detected. Explore government subsidized loans or KCC (Kisan Credit Card) for better rates.',
        );
      }
    }

    // ROI-based suggestions
    if (roi < 0) {
      suggestions.add(
        'Consider switching to more profitable crops or reducing input costs by 15-20%.',
      );
    } else if (roi < 15) {
      suggestions.add(
        'Try to optimize fertilizer usage and explore bulk purchasing to reduce costs.',
      );
    } else if (roi > 30) {
      suggestions.add(
        'Excellent returns! Consider expanding cultivation area for this crop.',
      );
    }

    // Yield comparison
    if (cropInfo != null) {
      final expectedYield = _getMidpoint(selectedExpectedYield);
      if (expectedYield < cropInfo['avgYield'] * 0.8) {
        suggestions.add(
          'Your expected yield is below average. Consider using high-yield varieties or improving soil health.',
        );
      }

      final marketPrice = _getMidpoint(selectedMarketPrice);
      if (marketPrice < cropInfo['avgPrice'] * 0.9) {
        suggestions.add(
          'Market price seems low. Consider direct marketing or value addition to increase profits.',
        );
      }

      if (cropInfo['riskFactor'] > 1.0) {
        suggestions.add(
          'This crop has higher market volatility. Consider crop insurance and diversification.',
        );
      }
    }

    // Cost optimization
    final seedCost = _getMidpoint(selectedSeedCost);
    final fertilizerCost = _getMidpoint(selectedFertilizerCost);
    final pesticideCost = _getMidpoint(selectedPesticideCost);
    final laborCost = _getMidpoint(selectedLaborCost);

    final highestCost = [
      seedCost,
      fertilizerCost,
      pesticideCost,
      laborCost,
    ].reduce((a, b) => a > b ? a : b);

    if (laborCost == highestCost && laborCost > operationalCosts * 0.4) {
      suggestions.add(
        'Labor costs are high. Consider mechanization or efficient labor management.',
      );
    }

    if (fertilizerCost == highestCost &&
        fertilizerCost > operationalCosts * 0.3) {
      suggestions.add(
        'Consider soil testing to optimize fertilizer usage and reduce unnecessary costs.',
      );
    }

    // Financial planning
    if (totalLoanRepayment > 0 && netProfit > 0) {
      suggestions.add(
        'Consider reinvesting profits to reduce dependency on loans for next crop cycle.',
      );
    }

    if (totalLoanRepayment == 0 && netProfit > 50000) {
      suggestions.add(
        'Strong financial position! Consider investing in farm infrastructure or diversification.',
      );
    }

    final farmArea = _getMidpoint(selectedFarmArea);
    if (farmArea < 2) {
      suggestions.add(
        'Small farm size may limit profits. Consider contract farming or cooperative cultivation.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
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
                    children: [
                      const SizedBox(height: 10),

                      // Header card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.lightGreenBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/profitloss_calculator.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Profit/Loss Calculator',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Calculate your farming profit & loss with\nprecision and get smart recommendations',
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

                      // Input section
                      Text(
                        'Farming Inputs',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Crop selection
                      _buildDropdownField(
                        label: 'Crop Type',
                        value: selectedCropName,
                        items: cropData.keys
                            .map((key) => cropData[key]!['name'] as String)
                            .toList(),
                        onChanged: (value) {
                          final key = cropData.keys.firstWhere(
                            (k) => cropData[k]!['name'] == value,
                            orElse: () => '',
                          );
                          _onCropSelected(key);
                        },
                      ),
                      const SizedBox(height: 20),

                      // Two column layout for inputs
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Farm Area',
                              value: selectedFarmArea,
                              items: farmAreaOptions,
                              onChanged: (value) =>
                                  setState(() => selectedFarmArea = value),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Expected Yield',
                              value: selectedExpectedYield,
                              items: yieldOptions,
                              onChanged: (value) =>
                                  setState(() => selectedExpectedYield = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Market Price',
                              value: selectedMarketPrice,
                              items: priceOptions,
                              onChanged: (value) =>
                                  setState(() => selectedMarketPrice = value),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Seed Cost',
                              value: selectedSeedCost,
                              items: costRangeOptions,
                              onChanged: (value) =>
                                  setState(() => selectedSeedCost = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Fertilizer Cost',
                              value: selectedFertilizerCost,
                              items: costRangeOptions,
                              onChanged: (value) => setState(
                                () => selectedFertilizerCost = value,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Pesticide Cost',
                              value: selectedPesticideCost,
                              items: costRangeOptions,
                              onChanged: (value) =>
                                  setState(() => selectedPesticideCost = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Labor Cost',
                              value: selectedLaborCost,
                              items: costRangeOptions,
                              onChanged: (value) =>
                                  setState(() => selectedLaborCost = value),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Other Expenses',
                              value: selectedOtherCost,
                              items: ['No Other Expenses', ...costRangeOptions],
                              onChanged: (value) =>
                                  setState(() => selectedOtherCost = value),
                              isRequired: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Loan Amount',
                              value: selectedLoanAmount,
                              items: loanAmountOptions,
                              onChanged: (value) =>
                                  setState(() => selectedLoanAmount = value),
                              isRequired: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Interest Rate',
                              value: selectedInterestRate,
                              items: interestRateOptions,
                              onChanged: (value) =>
                                  setState(() => selectedInterestRate = value),
                              isRequired: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Calculate button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _calculateProfitLoss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2BC24A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Calculate Profit/Loss',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Results section
                      if (showResults) ...[
                        _buildResultsSection(),
                        const SizedBox(height: 24),
                        _buildSuggestionsSection(),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
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
    bool isRequired = true,
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
          isDense: true,
          decoration: InputDecoration(
            hintText: 'Select $label',
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: context.secondaryTextColor,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.borderColor, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.primaryColor, width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 11.5, color: context.textColor),
          dropdownColor: context.cardColor,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: context.secondaryTextColor,
            size: 18,
          ),
          iconSize: 18,
          selectedItemBuilder: (BuildContext context) {
            return items.map((String item) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: context.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList();
          },
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: context.textColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    final bool isProfit = netProfit >= 0;
    final Color profitColor = isProfit ? const Color(0xFF2BC24A) : Colors.red;

    String roiText = 'High Risk';
    Color roiColor = Colors.red;
    if (roi > 30) {
      roiText = 'Excellent ROI';
      roiColor = const Color(0xFF2BC24A);
    } else if (roi > 15) {
      roiText = 'Good ROI';
      roiColor = const Color(0xFF4CAF50);
    } else if (roi > 0) {
      roiText = 'Low ROI';
      roiColor = Colors.orange;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor, width: 1),
      ),
      child: Column(
        children: [
          Text(
            'Financial Analysis',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 20),

          // Net Profit/Loss
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: profitColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: profitColor.withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                Text(
                  isProfit ? 'Net Profit' : 'Net Loss',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: profitColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '₹${netProfit.abs().toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: profitColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ROI indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: roiColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roiColor, width: 1),
            ),
            child: Text(
              '$roiText: ${roi.toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: roiColor,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Loan Analysis (if applicable)
          if (totalLoanRepayment > 0) ...[
            Text(
              'Loan Analysis',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildMetricRow('Loan Amount', selectedLoanAmount ?? 'N/A'),
            _buildMetricRow('Interest Rate', selectedInterestRate ?? 'N/A'),
            _buildMetricRow(
              'Annual Interest',
              '₹${annualInterest.toStringAsFixed(2)}',
            ),
            _buildMetricRow(
              'Total Repayment',
              '₹${totalLoanRepayment.toStringAsFixed(2)}',
            ),
            _buildMetricRow('Monthly EMI', '₹${monthlyEMI.toStringAsFixed(2)}'),
            const SizedBox(height: 20),
          ],

          // Metrics grid with proper responsive sizing
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildMetricCard(
                    'Total Revenue',
                    '₹${_formatCompactNumber(totalRevenue)}',
                  ),
                  _buildMetricCard(
                    'Operational Costs',
                    '₹${_formatCompactNumber(operationalCosts)}',
                  ),
                  _buildMetricCard(
                    'Total Costs',
                    '₹${_formatCompactNumber(totalCosts)}',
                  ),
                  _buildMetricCard(
                    'Production',
                    '${totalProduction.toStringAsFixed(1)} Qt',
                  ),
                  _buildMetricCard(
                    'Profit Margin',
                    '${profitMargin.toStringAsFixed(1)}%',
                  ),
                  _buildMetricCard(
                    'Cost/Acre',
                    '₹${_formatCompactNumber(costPerAcre)}',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  
  String _formatCompactNumber(double number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(2)}Cr';
    } else if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(2)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    }
    return number.toStringAsFixed(2);
  }

  Widget _buildMetricCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.lightGreenBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.primaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: context.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  Widget _buildSuggestionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart Recommendations',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 16),
          ...suggestions.map(
            (suggestion) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.lightGreenBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: context.textColor,
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

  Widget _buildBottomNavBar() {
    return const BottomNavBar(currentPage: 'other');
  }
}
