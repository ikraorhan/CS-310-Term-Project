// lib/routes/settings.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:convert';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _imagePicker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  bool _isLoading = true;
  String? _profilePictureUrl;
  bool _isUploadingImage = false;
  String? _base64Image; // Add this to track the current base64 image

  // Selected background color
  Color _selectedBackgroundColor = AppColors.backgroundColor;

  // List of available background colors
  final List<Color> _availableColors = [
    Colors.white,
    Colors.grey.shade200,
    Colors.blue.shade50,
    Colors.green.shade50,
    Colors.orange.shade50,
    Colors.red.shade50,
    Colors.purple.shade50,
    Colors.yellow.shade50,
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists && mounted) {
          final data = userData.data()!;
          setState(() {
            _nameController.text = data['username'] ?? '';
            _countryController.text = data['country'] ?? '';

            // Load profile picture data
            _profilePictureUrl = data['profilePicture'];

            // Also load the base64 data if available
            if (data['profilePictureBase64'] != null &&
                (data['profilePictureBase64'] as String).isNotEmpty) {
              _base64Image = data['profilePictureBase64'];
              _profilePictureUrl =
                  'data:image/jpeg;base64,${data['profilePictureBase64']}';
              print(
                'Loaded base64 profile image with length: ${_base64Image?.length}',
              );
            }

            // Load background color - handle both string and int formats
            if (data['backgroundColor'] != null) {
              try {
                if (data['backgroundColor'] is int) {
                  _selectedBackgroundColor = Color(data['backgroundColor']);
                } else if (data['backgroundColor'] is String) {
                  _selectedBackgroundColor = Color(
                    int.parse(data['backgroundColor']),
                  );
                }
                // Update app-wide background color
                AppColors.setBackgroundColor(_selectedBackgroundColor);
              } catch (e) {
                print('Error parsing background color: $e');
                // Keep default color on error
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user data')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Create update data map
        Map<String, dynamic> updateData = {
          'username': _nameController.text.trim(),
          'country': _countryController.text.trim(),
          'backgroundColor': _selectedBackgroundColor.toARGB32(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // If the base64 image was updated, include it in the update
        if (_base64Image != null) {
          updateData['profilePictureBase64'] = _base64Image;
        }

        // Save to Firestore
        await _firestore.collection('users').doc(user.uid).update(updateData);

        // Update app-wide background color
        await AppColors.setBackgroundColor(_selectedBackgroundColor);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          );
        }
      }
    } catch (e) {
      print('Error saving user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save settings')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    try {
      print('Starting image picker...');
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedImage == null || !mounted) {
        print('No image selected or widget unmounted');
        return;
      }
      print('Image selected: ${pickedImage.path}');

      setState(() => _isUploadingImage = true);

      // Verify current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      print('User authenticated as: ${user.uid}');

      // Read file bytes
      final bytes = await pickedImage.readAsBytes();
      print('Successfully read ${bytes.length} bytes from picked image');

      // Create a base64 representation of the image for direct Firestore storage
      final base64Image = base64Encode(bytes);
      print('Converted image to base64 (${base64Image.length} characters)');

      // Store the base64 image locally
      _base64Image = base64Image;

      try {
        // Store the image directly in Firestore document
        await _firestore.collection('users').doc(user.uid).update({
          'profilePictureBase64': base64Image,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print(
          'Image stored directly in Firestore - document updated successfully',
        );

        // Verify the update worked by reading it back
        final updatedDoc =
            await _firestore.collection('users').doc(user.uid).get();

        final base64Data = updatedDoc.data()?['profilePictureBase64'];
        if (base64Data != null) {
          print(
            'Verification: profilePictureBase64 field exists in document with length: ${(base64Data as String).length}',
          );
        } else {
          print('Warning: profilePictureBase64 field is null after update');
        }
      } catch (firestoreError) {
        print('Error saving to Firestore: $firestoreError');
        rethrow; // Use rethrow instead of throw firestoreError
      }

      if (!mounted) return;

      // Update the UI with base64 image
      setState(() {
        // Create a data URL from the base64 string
        _profilePictureUrl = 'data:image/jpeg;base64,$base64Image';
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      print('Error uploading profile picture:');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;
      setState(() => _isUploadingImage = false);

      // Error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile picture: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _updateBackgroundColor(Color color) async {
    setState(() {
      _selectedBackgroundColor = color;
    });

    // Update app-wide background color immediately for better UX
    await AppColors.setBackgroundColor(color);
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // Navigate to welcome page
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      print('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to sign out')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _selectedBackgroundColor,
      appBar: AppBar(
        backgroundColor: _selectedBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(
              'TickTask',
              style: AppTextStyles.welcomeTitle.copyWith(
                fontSize: 30,
                fontFamily: 'LibreBaskerville',
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: AppColors.mainColor, height: 2.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.mainColor,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: AppTextStyles.welcomeTitle.copyWith(
                      fontSize: 26,
                      fontFamily: 'LibreBaskerville',
                      color: AppColors.mainColor,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.logout,
                      color: AppColors.mainColor,
                      size: 30,
                    ),
                    onPressed: _logout,
                    tooltip: 'Logout',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Updated Profile Picture Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              _profilePictureUrl != null
                                  ? _profilePictureUrl!.startsWith('data:')
                                      // Use MemoryImage for base64 data
                                      ? MemoryImage(
                                        base64Decode(
                                          _profilePictureUrl!.split(',')[1],
                                        ),
                                      )
                                      // Use NetworkImage for regular URLs
                                      : NetworkImage(_profilePictureUrl!)
                                  : null,
                          child:
                              _profilePictureUrl == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                        ),
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed:
                          _isUploadingImage ? null : _uploadProfilePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        _isUploadingImage
                            ? 'Uploading...'
                            : 'Change Profile Picture',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Name Setting
              Text(
                'Name:',
                style: AppTextStyles.label.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: AppTextStyles.loginLabel.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontSize: 16,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: AppTextStyles.loginLabel.copyWith(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Country Setting
              Text(
                'Country:',
                style: AppTextStyles.label.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _countryController,
                style: AppTextStyles.loginLabel.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontSize: 16,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your country',
                  hintStyle: AppTextStyles.loginLabel.copyWith(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Background Color Setting
              Text(
                'Background Color:',
                style: AppTextStyles.label.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      _availableColors.map((color) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => _updateBackgroundColor(color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border:
                                    _selectedBackgroundColor == color
                                        ? Border.all(
                                          width: 3,
                                          color: AppColors.mainColor,
                                        )
                                        : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 30),
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Settings',
                    style: AppTextStyles.loginLabel.copyWith(
                      fontFamily: 'LibreBaskerville',
                      fontSize: 18,
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    super.dispose();
  }
}
