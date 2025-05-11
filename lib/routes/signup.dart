// lib/routes/signup.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Global key to uniquely identify the Form widget and access its state
  final _formKey = GlobalKey<FormState>();

  // Controllers for the input fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validator for the username field
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    return null;
  }

  // Validator for the email field using a basic regex for email validation
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ); // basic email regex
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Validator for the password field: must be more than 6 letters
  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters long';
    }
    // Additional password validation can be added here if needed
    return null;
  }

  // Function to handle form submission
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Form Invalid"),
              content: const Text(
                "Please fix the errors in red before submitting.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user with email and password
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'userId': userCredential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
        'passwordResetRequired': false,
        'failedLoginAttempts': 0,
        'lastFailedLogin': null,
      });

      // Show success message and navigate to login page
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully. Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred during registration';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email';
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

            // Title: "Create New Account"
            Center(
              child: Text(
                'Create New\nAccount',
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
                      // Username Section (kept as requested)
                      Text('USERNAME', style: AppTextStyles.loginLabel),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _usernameController,
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
                        validator: _validateUsername,
                      ),

                      const SizedBox(height: 30),

                      // Email Section with validation
                      Text('EMAIL', style: AppTextStyles.loginLabel),
                      const SizedBox(height: 8),
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

                      // Password Section with length validation
                      Text('PASSWORD', style: AppTextStyles.loginLabel),
                      const SizedBox(height: 8),
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

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
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
                                    'Register',
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
