import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/market_analysis_service.dart';
import 'services/theme_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/localization_service.dart';

class MarketAnalysisPage extends StatefulWidget {
  const MarketAnalysisPage({super.key});

  @override
  State<MarketAnalysisPage> createState() => _MarketAnalysisPageState();
}

class _MarketAnalysisPageState extends State<MarketAnalysisPage> {
  List<String> states = [];
  List<String> mandis = [];
  List<String> crops = [];

  String? selectedState;
  String? selectedMandi;
  String? selectedCrop;

  Map<String, dynamic>? priceData;
  bool isLoadingStates = true;
  bool isLoadingMandis = false;
  bool isLoadingCrops = false;
  bool isLoadingPrices = false;

  @override
  void initState() {
    super.initState();
    fetchStates();
  }

  Future<void> fetchStates() async {
    setState(() => isLoadingStates = true);
    try {
      final fetchedStates = await MarketAnalysisService.fetchStates();
      setState(() {
        states = fetchedStates;
        isLoadingStates = false;
      });
    } catch (e) {
      print('Error fetching states: $e');
      setState(() => isLoadingStates = false);
      _showErrorSnackBar(
        'Failed to load states. Please check backend connection.',
      );
    }
  }

  Future<void> fetchMandis(String state) async {
    setState(() {
      isLoadingMandis = true;
      mandis = [];
      crops = [];
      selectedMandi = null;
      selectedCrop = null;
      priceData = null;
    });

    try {
      final fetchedMandis = await MarketAnalysisService.fetchMandis(state);
      setState(() {
        mandis = fetchedMandis;
        isLoadingMandis = false;
      });
    } catch (e) {
      print('Error fetching mandis: $e');
      setState(() => isLoadingMandis = false);
      _showErrorSnackBar('Failed to load mandis');
    }
  }

  Future<void> fetchCrops(String state, String mandi) async {
    setState(() {
      isLoadingCrops = true;
      crops = [];
      selectedCrop = null;
      priceData = null;
    });

    try {
      final fetchedCrops = await MarketAnalysisService.fetchCrops(state, mandi);
      setState(() {
        crops = fetchedCrops;
        isLoadingCrops = false;
      });
    } catch (e) {
      print('Error fetching crops: $e');
      setState(() => isLoadingCrops = false);
      _showErrorSnackBar('Failed to load crops');
    }
  }

  Future<void> fetchPrices(String state, String mandi, String crop) async {
    setState(() => isLoadingPrices = true);

    try {
      final data = await MarketAnalysisService.fetchPrices(
        state: state,
        mandi: mandi,
        crop: crop,
      );

      setState(() {
        priceData = data;
        isLoadingPrices = false;
      });
    } catch (e) {
      print('Error fetching prices: $e');
      setState(() {
        priceData = null;
        isLoadingPrices = false;
      });
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
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
                    _buildHeaderCard(),

                    const SizedBox(height: 24),

                    // Filter card
                    _buildFilterCard(),

                    const SizedBox(height: 24),

                    // Price data display
                    if (priceData != null) _buildPriceTicker(),
                    const SizedBox(height: 24),
                    if (priceData != null) ...[
                      _buildPriceTable(),
                    ] else if (isLoadingPrices)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF008575),
                            ),
                          ),
                        ),
                      )
                    else
                      _buildEmptyState(),

                    const SizedBox(height: 24),
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

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.lightGreenBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Market icon
          Image.asset(
            'assets/images/market_analysis.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          Text(
            'Market Analysis',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check real-time market prices for crops\nacross different states and mandis',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Location & Crop',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildDropdown(
            label: 'State',
            value: selectedState,
            items: states,
            onChanged: (value) {
              setState(() => selectedState = value);
              if (value != null) fetchMandis(value);
            },
            isLoading: isLoadingStates,
            hint: 'Select State',
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Mandi',
            value: selectedMandi,
            items: mandis,
            onChanged: (value) {
              setState(() => selectedMandi = value);
              if (value != null && selectedState != null) {
                fetchCrops(selectedState!, value);
              }
            },
            isLoading: isLoadingMandis,
            isEnabled: selectedState != null && mandis.isNotEmpty,
            hint: 'Select Mandi',
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Crop',
            value: selectedCrop,
            items: crops,
            onChanged: (value) {
              setState(() => selectedCrop = value);
              if (value != null &&
                  selectedState != null &&
                  selectedMandi != null) {
                fetchPrices(selectedState!, selectedMandi!, value);
              }
            },
            isLoading: isLoadingCrops,
            isEnabled: selectedMandi != null && crops.isNotEmpty,
            hint: 'Select Crop',
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isLoading,
    bool isEnabled = true,
    String hint = 'Select',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isEnabled ? context.cardColor : context.lightGreenBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled ? context.primaryColor : context.borderColor,
              width: 1.5,
            ),
          ),
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading...',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: context.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: Text(
                    hint,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: context.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: context.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: isEnabled
                        ? context.primaryColor
                        : context.secondaryTextColor,
                  ),
                  dropdownColor: context.cardColor,
                  items: items.isEmpty
                      ? [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              'No options',
                              style: GoogleFonts.poppins(
                                color: context.secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ]
                      : items.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                  onChanged: isEnabled ? onChanged : null,
                ),
        ),
      ],
    );
  }

  Widget _buildPriceTicker() {
    final latest = priceData!['latest'];
    final crop = priceData!['crop'];
    final modalPrice = latest['modal_price'];
    final changePct = latest['change_pct'];
    final pricePerKg = (modalPrice / 100).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF008575),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Crop name with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                crop,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main price - per kg
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Today\'s Price',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      pricePerKg,
                      style: GoogleFonts.poppins(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'per kg',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Price change indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: changePct >= 0
                  ? Colors.lightGreenAccent.withOpacity(0.25)
                  : Colors.redAccent.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  changePct >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  changePct >= 0 ? '(Up)' : '(Down)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Additional info - quintal price
          Text(
            '₹${modalPrice.toStringAsFixed(0)} per quintal (100 kg)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTable() {
    final history = (priceData!['history'] as List).reversed.take(7).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: context.primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'Past Prices',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(
              color: context.primaryColor.withOpacity(0.3),
              width: 1,
            ),
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: context.lightGreenBg),
                children: [
                  _buildTableHeader('Date'),
                  _buildTableHeader('Price per kg'),
                ],
              ),
              ...history.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                final price = row['modal_price'];
                final perKg = (price / 100).toStringAsFixed(2);

                return TableRow(
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? context.lightGreenBg.withOpacity(0.3)
                        : context.cardColor,
                  ),
                  children: [
                    _buildTableCell(row['date']),
                    _buildTableCell('₹$perKg', isBold: true),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Note: 1 quintal = 100 kg',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: context.secondaryTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: context.primaryColor,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: context.textColor,
          fontSize: isBold ? 15 : 13,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: context.secondaryTextColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Please select state, market and crop to view prices',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: context.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return const BottomNavBar(currentPage: 'other');
  }
}
