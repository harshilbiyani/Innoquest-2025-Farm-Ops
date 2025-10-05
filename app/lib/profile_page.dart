import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'services/user_preferences.dart';
import 'services/theme_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/localization_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _landSizeController = TextEditingController();

  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await UserPreferences.getProfileData();
    setState(() {
      _nameController.text = data['name'] ?? '';
      _locationController.text = data['location'] ?? '';
      _landSizeController.text = data['landSize'] ?? '';
      _imagePath = data['imagePath'];
    });
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _imagePath = picked.path;
      });
      await UserPreferences.saveProfileData(imagePath: picked.path);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    await UserPreferences.saveProfileData(
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      landSize: _landSizeController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.localizations.success, style: GoogleFonts.poppins())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final loc = context.localizations;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.profile,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textColor),
      ),
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            backgroundImage: _imagePath != null
                                ? FileImage(File(_imagePath!)) as ImageProvider
                                : null,
                            child: _imagePath == null
                                ? Icon(
                                    Icons.camera_alt,
                                    size: 36,
                                    color: Theme.of(context).primaryColor,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.edit),
                          label: Text(
                            'Change photo',
                            style: GoogleFonts.poppins(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Card(
                          color: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: context.localizations.name,
                                    labelStyle: GoogleFonts.poppins(),
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Please enter name'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _locationController,
                                  decoration: InputDecoration(
                                    labelText: context.localizations.location,
                                    labelStyle: GoogleFonts.poppins(),
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Please enter location'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _landSizeController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Land size (e.g., acres)',
                                    labelStyle: GoogleFonts.poppins(),
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Please enter land size'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              loc.save,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom navigation bar placed like other pages (below scroll area)
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return const BottomNavBar(currentPage: 'profile');
  }
}
