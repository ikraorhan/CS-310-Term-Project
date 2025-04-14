// lib/routes/login.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button aligned to top left
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.mainColor,
                  size: 32,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 10),
            // Title centered below back button using our custom font style
            Center(
              child: Text(
                'Login To\nAccount',
                textAlign: TextAlign.center,
                style: AppTextStyles.mainTitle.copyWith(
                  fontFamily: 'LibreBaskerville',
                ),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Username Label using new black text style
                    Text('USERNAME', style: AppTextStyles.loginLabel),
                    const SizedBox(height: 8),
                    // Username Field
                    TextField(
                      textAlign: TextAlign.center,
                      style: AppTextStyles.loginLabel.copyWith(
                        fontFamily: 'LibreBaskerville',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Example_Name',
                        hintStyle: AppTextStyles.loginLabel.copyWith(
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Password Label using new black text style
                    Text('PASSWORD', style: AppTextStyles.loginLabel),
                    const SizedBox(height: 8),
                    // Password Field
                    TextField(
                      obscureText: true,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.loginLabel.copyWith(
                        fontFamily: 'LibreBaskerville',
                      ),
                      decoration: InputDecoration(
                        hintText: '*****',
                        hintStyle: AppTextStyles.loginLabel.copyWith(
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Login Button that navigates to the home page on click
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to the home page after login
                          Navigator.pushNamed(context, '/home');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Login',
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
          ],
        ),
      ),
    );
  }
}
