import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/disease_detection_service.dart';
import 'services/theme_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/localization_service.dart';

class DiseaseDetectionPage extends StatefulWidget {
  const DiseaseDetectionPage({super.key});

  @override
  State<DiseaseDetectionPage> createState() => _DiseaseDetectionPageState();
}

class _DiseaseDetectionPageState extends State<DiseaseDetectionPage> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  DiseaseResult? _result;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _result = null; // Clear previous results
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      _showErrorMessage('Please select an image first');
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Call disease detection service
      final result = await DiseaseDetectionService.detectDisease(
        _selectedImage!,
      );

      setState(() {
        _result = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorMessage('Analysis failed: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetDetection() {
    setState(() {
      _selectedImage = null;
      _result = null;
      _isAnalyzing = false;
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Image Source',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildSourceOption(
              icon: Icons.camera_alt,
              title: 'Camera',
              subtitle: 'Take a new photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _buildSourceOption(
              icon: Icons.photo_library,
              title: 'Gallery',
              subtitle: 'Choose from gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.lightGreenBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.primaryColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.primaryColor,
            ),
          ],
        ),
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
                      onPressed: () => Navigator.pop(context),
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

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    _buildHeaderCard(),
                    const SizedBox(height: 24),

                    // How it works section
                    _buildHowItWorksCard(),
                    const SizedBox(height: 24),

                    // Image upload/display section
                    if (_selectedImage == null)
                      _buildUploadSection()
                    else
                      _buildImagePreviewSection(),

                    const SizedBox(height: 24),

                    // Analyze button
                    if (_selectedImage != null && _result == null)
                      _buildAnalyzeButton(),

                    // Results section
                    if (_result != null) ...[
                      _buildResultsSection(),
                      const SizedBox(height: 20),
                      _buildNewScanButton(),
                    ],

                    // Previous scans section (placeholder)
                    if (_selectedImage == null && _result == null)
                      _buildPreviousScansSection(),
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
          // Icon
          Image.asset(
            'assets/images/disease_detection.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.health_and_safety,
                size: 80,
                color: context.primaryColor,
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Disease Detection',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload crop photos to identify diseases\nand get instant solutions',
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

  Widget _buildHowItWorksCard() {
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
          Text(
            'How It Works',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStep(Icons.camera_alt, 'Scan', '1'),
              const SizedBox(width: 8),
              _buildArrow(),
              const SizedBox(width: 8),
              _buildStep(Icons.assessment, 'Get Report', '2'),
              const SizedBox(width: 8),
              _buildArrow(),
              const SizedBox(width: 8),
              _buildStep(Icons.medication, 'Get Cure', '3'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(IconData icon, String label, String step) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: context.lightGreenBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      step,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrow() {
    return Icon(Icons.arrow_forward, color: context.primaryColor, size: 20);
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: context.lightGreenBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.primaryColor.withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.lightGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 60,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Upload your crop photo',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a clear picture of the affected crop part for accurate disease identification',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: context.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: Text(
                'Take a Picture',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2BC24A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewSection() {
    return Container(
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
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.file(
              _selectedImage!,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: Icon(Icons.refresh, color: context.primaryColor),
                    label: Text(
                      'Change Photo',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.primaryColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isAnalyzing ? null : _analyzeImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: _isAnalyzing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Analyzing...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                'Analyze Image',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_result == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Disease identified card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _result!.isHealthy
                ? context.lightGreenBg
                : Colors.red.shade50,
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
                  Icon(
                    _result!.isHealthy ? Icons.check_circle : Icons.warning,
                    color: _result!.isHealthy
                        ? context.primaryColor
                        : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _result!.isHealthy
                          ? 'Crop is Healthy!'
                          : 'Disease Detected',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _result!.isHealthy
                            ? context.primaryColor
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disease Name',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _result!.diseaseName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Confidence',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _result!.confidence / 100,
                        minHeight: 8,
                        backgroundColor: context.borderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _result!.confidence >= 80
                              ? context.primaryColor
                              : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_result!.confidence.toStringAsFixed(1)}% confident',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Description section
        if (_result!.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
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
                    Icon(
                      Icons.info_outline,
                      color: context.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Description',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _result!.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: context.secondaryTextColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Treatment section
        if (_result!.treatment.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
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
                    Icon(Icons.healing, color: context.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Recommended Treatment',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._result!.treatment.map(
                  (treatment) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.primaryColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            treatment,
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
          ),
        ],
      ],
    );
  }

  Widget _buildNewScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _resetDetection,
        icon: Icon(Icons.refresh, color: context.primaryColor),
        label: Text(
          'Scan Another Crop',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.primaryColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviousScansSection() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Previous Scans',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.primaryColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to history page
                },
                child: Text(
                  'View all',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: context.secondaryTextColor.withOpacity(0.5),
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'No previous scans yet',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: context.secondaryTextColor,
                    ),
                  ),
                ),
              ],
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
