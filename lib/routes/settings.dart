// lib/routes/settings.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Controller for the name field.
  final TextEditingController _nameController = TextEditingController(
    text: "Ramazan",
  );
  // Controller for the country field.
  final TextEditingController _countryController = TextEditingController(
    text: "Türkiye",
  );

  // Selected background color.
  Color _selectedBackgroundColor = AppColors.backgroundColor;

  // List of available background colors.
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedBackgroundColor,
      // TickTask AppBar at the top.
      appBar: AppBar(
        backgroundColor: _selectedBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, // No default back arrow.
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
      // Settings content.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: back icon and "Settings" title.
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.mainColor,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/home');
                    },
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
                ],
              ),
              const SizedBox(height: 20),
              // Name Setting.
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
              // Profile Picture Setting.
              Text(
                'Profile Picture:',
                style: AppTextStyles.label.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // TODO: Integrate Flutter image upload functionality here.
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Upload Profile Picture',
                  style: AppTextStyles.loginLabel.copyWith(
                    fontFamily: 'LibreBaskerville',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Country Setting as a text form.
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
              // Background Color Setting.
              Text(
                'Background Color:',
                style: AppTextStyles.label.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              // Display a row of color choices.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      _availableColors.map((color) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedBackgroundColor = color;
                              });
                            },
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
              // Additional spacing or "Save Settings" button can be added here.
            ],
          ),
        ),
      ),
    );
  }
}
