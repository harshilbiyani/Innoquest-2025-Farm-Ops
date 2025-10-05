import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/theme_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/localization_service.dart';

class ProfessionalAdvisorPage extends StatefulWidget {
  const ProfessionalAdvisorPage({super.key});

  @override
  State<ProfessionalAdvisorPage> createState() =>
      _ProfessionalAdvisorPageState();
}

class _ProfessionalAdvisorPageState extends State<ProfessionalAdvisorPage> {
  String _sortBy = 'rating';
  String _filterBy = 'all';
  String _searchQuery = '';

  final List<Map<String, dynamic>> experts = [
    {
      'name': 'Dr. Aditya Rajput',
      'speciality': 'Soil Fertility & Crop Nutrition',
      'rating': 5.0,
      'ratingCount': 120,
      'experience': '15+ years',
      'contact': 'aditya@agri.com | +91 9876543210',
      'bio':
          'Expert in soil fertility and crop nutrition with over 15 years of agricultural consultancy experience.',
      'photo': 'assets/images/profile.png',
    },
    {
      'name': 'Dr. Anjali Mehta',
      'speciality': 'Pest & Disease Management',
      'rating': 4.7,
      'ratingCount': 90,
      'experience': '12+ years',
      'contact': 'anjali@agri.com | +91 9123456780',
      'bio':
          'Specialist in pest and disease management helping farmers protect their crops effectively.',
      'photo': 'assets/images/profile.png',
    },
    {
      'name': 'Dr. Vivek Sharma',
      'speciality': 'Irrigation & Water Management',
      'rating': 4.5,
      'ratingCount': 75,
      'experience': '10+ years',
      'contact': 'vivek@agri.com | +91 9988776655',
      'bio':
          'Irrigation specialist with 10 years of expertise in water resource management and crop efficiency.',
      'photo': 'assets/images/profile.png',
    },
    {
      'name': 'Dr. Priya Deshmukh',
      'speciality': 'Organic Farming',
      'rating': 4.9,
      'ratingCount': 110,
      'experience': '18+ years',
      'contact': 'priya@agri.com | +91 9765432100',
      'bio':
          'Pioneer in organic farming practices with extensive experience in sustainable agriculture.',
      'photo': 'assets/images/profile.png',
    },
    {
      'name': 'Dr. Rajesh Kumar',
      'speciality': 'Soil Fertility & Crop Nutrition',
      'rating': 4.6,
      'ratingCount': 85,
      'experience': '14+ years',
      'contact': 'rajesh@agri.com | +91 9876509876',
      'bio':
          'Specializes in soil testing and nutrient management for maximum crop yield.',
      'photo': 'assets/images/profile.png',
    },
  ];

  List<Map<String, dynamic>> get filteredAndSortedExperts {
    var filtered = experts.where((expert) {
      bool matchesFilter =
          _filterBy == 'all' ||
          expert['speciality'].toString().toLowerCase() ==
              _filterBy.toLowerCase();
      bool matchesSearch =
          _searchQuery.isEmpty ||
          expert['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          expert['speciality'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchesFilter && matchesSearch;
    }).toList();

    if (_sortBy == 'rating') {
      filtered.sort((a, b) {
        double scoreA = a['rating'] + (a['ratingCount'] / 1000);
        double scoreB = b['rating'] + (b['ratingCount'] / 1000);
        return scoreB.compareTo(scoreA);
      });
    } else if (_sortBy == 'name') {
      filtered.sort((a, b) => a['name'].compareTo(b['name']));
    } else if (_sortBy == 'speciality') {
      filtered.sort((a, b) => a['speciality'].compareTo(b['speciality']));
    }

    return filtered;
  }

  void _showExpertDetails(Map<String, dynamic> expert) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(Icons.close, color: context.primaryColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Profile photo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: context.primaryColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(expert['photo'], fit: BoxFit.cover),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Text(
                    expert['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Speciality
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.lightGreenBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      expert['speciality'],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.primaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < expert['rating'].floor()
                              ? Icons.star
                              : (index < expert['rating']
                                    ? Icons.star_half
                                    : Icons.star_border),
                          color: const Color(0xFFFFD700),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${expert['rating']} (${expert['ratingCount']} ratings)',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: context.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Experience
                  _buildInfoRow(
                    Icons.work_outline,
                    'Experience',
                    expert['experience'],
                  ),

                  const SizedBox(height: 12),

                  // Contact
                  _buildInfoRow(
                    Icons.contact_phone_outlined,
                    'Contact',
                    expert['contact'],
                  ),

                  const SizedBox(height: 16),

                  // Bio
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.lightGreenBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          expert['bio'],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: context.secondaryTextColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Book Appointment Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _launchBookingForm(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2BC24A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Book an Appointment',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.secondaryTextColor,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: context.textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchBookingForm() async {
    final Uri url = Uri.parse('https://forms.gle/kNHEjsjsAjZb78TW9');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open booking form',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                          // Icon
                          Image.asset(
                            'assets/images/professional_advisor.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Professional Advisor Connect',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: context.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Consult trusted experts in the field\nof agriculture and farming',
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

                    // Search bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: context.textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name or speciality',
                          hintStyle: GoogleFonts.poppins(
                            color: context.secondaryTextColor,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: context.primaryColor),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Filters
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _sortBy,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: context.primaryColor,
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: context.textColor,
                                ),
                                focusColor: Colors.transparent,
                                dropdownColor: context.cardColor,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'rating',
                                    child: Text('Sort: Highest Rating'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'name',
                                    child: Text('Sort: Name (A-Z)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'speciality',
                                    child: Text('Sort: Speciality'),
                                  ),
                                ],
                                selectedItemBuilder: (BuildContext context) {
                                  return const [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Sort: Highest Rating'),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Sort: Name (A-Z)'),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Sort: Speciality'),
                                    ),
                                  ];
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _sortBy = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _filterBy,
                                icon: Icon(
                                  Icons.filter_list,
                                  color: context.primaryColor,
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: context.textColor,
                                ),
                                focusColor: Colors.transparent,
                                dropdownColor: context.cardColor,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All Specialities'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Soil Fertility & Crop Nutrition',
                                    child: Text('Soil & Nutrition'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Pest & Disease Management',
                                    child: Text('Pest & Disease'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Irrigation & Water Management',
                                    child: Text('Irrigation'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Organic Farming',
                                    child: Text('Organic Farming'),
                                  ),
                                ],
                                selectedItemBuilder: (BuildContext context) {
                                  return const [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('All Specialities'),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Soil & Nutrition'),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Pest & Disease'),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Irrigation'),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Organic Farming'),
                                    ),
                                  ];
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _filterBy = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Expert Cards
                    ...filteredAndSortedExperts.map((expert) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildExpertCard(expert),
                      );
                    }),

                    // No results message
                    if (filteredAndSortedExperts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 60,
                              color: context.secondaryTextColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No experts found',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: context.secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: context.secondaryTextColor,
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
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertCard(Map<String, dynamic> expert) {
    return GestureDetector(
      onTap: () => _showExpertDetails(expert),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.primaryColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.primaryColor, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(expert['photo'], fit: BoxFit.cover),
              ),
            ),

            const SizedBox(width: 16),

            // Expert info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expert['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expert['speciality'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: context.secondaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < expert['rating'].floor()
                              ? Icons.star
                              : (index < expert['rating']
                                    ? Icons.star_half
                                    : Icons.star_border),
                          color: const Color(0xFFFFD700),
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${expert['rating']} (${expert['ratingCount']})',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: context.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expert['experience'],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: context.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.lightGreenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return const BottomNavBar(currentPage: 'other');
  }
}
