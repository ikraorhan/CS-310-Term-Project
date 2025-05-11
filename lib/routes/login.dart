// lib/routes/login.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sign in with Firebase Auth
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Get user document from Firestore
      final userDoc =
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

      if (!userDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User data not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final userData = userDoc.data()!;

      // Verify stored password
      if (userData['password'] != _passwordController.text.trim()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid password'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Update last login time and ensure userId exists
      await _firestore.collection('users').doc(userCredential.user!.uid).update(
        {
          'lastLogin': FieldValue.serverTimestamp(),
          'failedLoginAttempts': 0,
          'lastFailedLogin': null,
          'userId': userCredential.user!.uid, // Ensure userId exists
        },
      );

      // Navigate to home page
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred during login';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided';

        // Update failed login attempts if user exists
        try {
          final userQuery =
              await _firestore
                  .collection('users')
                  .where('email', isEqualTo: _emailController.text.trim())
                  .get();

          if (userQuery.docs.isNotEmpty) {
            final userDoc = userQuery.docs.first;
            await _firestore.collection('users').doc(userDoc.id).update({
              'failedLoginAttempts': FieldValue.increment(1),
              'lastFailedLogin': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          // Ignore error updating failed attempts
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Username Label using new black text style
                      Text('EMAIL', style: AppTextStyles.loginLabel),
                      const SizedBox(height: 8),
                      // Username Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.loginLabel.copyWith(
                          fontFamily: 'LibreBaskerville',
                        ),
                        decoration: InputDecoration(
                          hintText: 'example@mail.com',
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
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 30),
                      // Password Label using new black text style
                      Text('PASSWORD', style: AppTextStyles.loginLabel),
                      const SizedBox(height: 8),
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
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
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 50),
                      // Login Button that navigates to the home page on click
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
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
            ),
          ],
        ),
      ),
    );
  }
}
