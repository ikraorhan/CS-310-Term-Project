import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tick_task/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _auth.currentUser != null;
  String? get profileImageUrl => _getProfileImageUrl();

  UserProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser == null) {
        _user = null;
        notifyListeners();
      } else {
        _loadUserData(firebaseUser.uid);
      }
    });
  }

  Future<void> _loadUserData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userData = await _firestore.collection('users').doc(userId).get();

      if (userData.exists) {
        _user = UserModel.fromFirestore(userData);
        _errorMessage = null;
      } else {
        _errorMessage = "User data not found";
      }
    } catch (e) {
      _errorMessage = "Failed to load user data: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _getProfileImageUrl() {
    if (_user == null) return null;

    // Debug log
    print('Getting profile image URL for user: ${_user!.email}');
    print('Base64 image available: ${_user!.profilePictureBase64 != null}');
    if (_user!.profilePictureBase64 != null) {
      print('Base64 image length: ${_user!.profilePictureBase64!.length}');
    }

    // Prioritize base64 if available
    if (_user!.profilePictureBase64 != null &&
        _user!.profilePictureBase64!.isNotEmpty) {
      try {
        // Check if base64 already includes the data URL prefix
        if (_user!.profilePictureBase64!.startsWith('data:')) {
          print('Base64 image already has data URL prefix');
          return _user!.profilePictureBase64;
        }

        // Validate base64 string by decoding a small part
        final sampleLength = min(100, _user!.profilePictureBase64!.length);
        base64Decode(_user!.profilePictureBase64!.substring(0, sampleLength));

        print('Base64 validation successful, creating data URL');
        // If successful, create a data URL format
        return 'data:image/jpeg;base64,${_user!.profilePictureBase64}';
      } catch (e) {
        // If invalid base64, log error and fall back to URL
        print('Error with base64 image: $e');
      }
    }

    // Fall back to regular URL if base64 is not available or invalid
    if (_user!.profilePictureUrl != null &&
        _user!.profilePictureUrl!.isNotEmpty) {
      print('Using profile picture URL: ${_user!.profilePictureUrl}');
      return _user!.profilePictureUrl;
    }

    print('No profile picture available');
    return null;
  }

  // Sign in with username and password
  Future<bool> signIn(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("Attempting to sign in with username: $username");

      // First, we need to find the user's email from their username
      try {
        final usersSnapshot =
            await _firestore
                .collection('users')
                .where('username', isEqualTo: username)
                .limit(1)
                .get();

        print(
          "Query completed. Found ${usersSnapshot.docs.length} matching users",
        );

        if (usersSnapshot.docs.isEmpty) {
          _isLoading = false;
          _errorMessage = "No user found with this username.";
          print("No user found with username: $username");
          notifyListeners();
          return false;
        }

        // Get the email from the document
        final userDoc = usersSnapshot.docs.first;
        final email = userDoc.data()['email'] as String;

        print("Found email: $email for username: $username");

        // Now sign in with email and password
        try {
          await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          print("Authentication successful with Firebase");

          _isLoading = false;
          notifyListeners();
          return true;
        } catch (authError) {
          print("Firebase Auth Error: $authError");
          throw authError; // Re-throw to be caught by outer catch block
        }
      } catch (firestoreError) {
        print("Firestore Error during username lookup: $firestoreError");
        _isLoading = false;
        _errorMessage = "Error looking up user: $firestoreError";
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception: ${e.code} - ${e.message}");
      _isLoading = false;

      switch (e.code) {
        case 'user-not-found':
          _errorMessage = "Invalid username or password.";
          break;
        case 'wrong-password':
          _errorMessage = "Invalid username or password.";
          break;
        case 'invalid-email':
          _errorMessage = "Invalid email format associated with this username.";
          break;
        default:
          _errorMessage = "Sign in failed: ${e.message}";
      }

      notifyListeners();
      return false;
    } catch (e) {
      print("Unexpected error during sign in: $e");
      _isLoading = false;
      _errorMessage = "Sign in failed: $e";
      notifyListeners();
      return false;
    }
  }

  // Register with email and password
  Future<bool> register(String email, String password, String username) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("Starting user registration for email: $email");

      // First create the user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
        "User created in Firebase Auth with UID: ${userCredential.user!.uid}",
      );

      // Make sure we have the latest auth token before creating Firestore document
      await userCredential.user!.getIdToken(true);
      print("Firebase ID token refreshed");

      try {
        // Create user document in Firestore
        print("Attempting to create user document in Firestore");
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'username': username,
          'createdAt': Timestamp.now(),
        });
        print("User document created successfully in Firestore");
      } catch (firestoreError) {
        print("Firestore error: $firestoreError");
        _errorMessage =
            "Account created but profile setup failed: $firestoreError";
        notifyListeners();
        // Even with Firestore error, return true since Auth was successful
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception: ${e.code} - ${e.message}");
      _isLoading = false;

      switch (e.code) {
        case 'email-already-in-use':
          _errorMessage = "Email is already in use.";
          break;
        case 'weak-password':
          _errorMessage = "Password is too weak.";
          break;
        case 'invalid-email':
          _errorMessage = "Invalid email format.";
          break;
        default:
          _errorMessage = "Registration failed: ${e.message}";
      }

      notifyListeners();
      return false;
    } catch (e) {
      print("Unexpected error during registration: $e");
      _isLoading = false;
      _errorMessage = "Registration failed: $e";
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = "Sign out failed: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update profile picture
  Future<bool> updateProfilePicture(String base64Image) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = "No user logged in";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'profilePictureBase64': base64Image,
      });

      // If successful, update the local user model
      if (_user != null) {
        _user = _user!.copyWith(profilePictureBase64: base64Image);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Failed to update profile picture: $e";
      notifyListeners();
      return false;
    }
  }

  // Update username
  Future<bool> updateUsername(String newUsername) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = "No user logged in";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'username': newUsername,
      });

      // If successful, update the local user model
      if (_user != null) {
        _user = _user!.copyWith(username: newUsername);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Failed to update username: $e";
      notifyListeners();
      return false;
    }
  }

  // Get account creation date
  Future<DateTime> getAccountCreationDate() async {
    final user = _auth.currentUser;
    if (user == null) {
      return DateTime.now();
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data()?['createdAt'] != null) {
        return (userDoc.data()?['createdAt'] as Timestamp).toDate();
      } else {
        // Fallback to Firebase Auth creation time
        return user.metadata.creationTime ?? DateTime.now();
      }
    } catch (e) {
      _errorMessage = "Failed to get account creation date: $e";
      notifyListeners();
      return user.metadata.creationTime ?? DateTime.now();
    }
  }

  // Debug method to print user data
  void debugUserData() {
    if (_user == null) {
      print('DEBUG: User is null');
      return;
    }

    print('DEBUG: User ID: ${_user!.id}');
    print('DEBUG: Username: ${_user!.username}');
    print('DEBUG: Email: ${_user!.email}');
    print('DEBUG: ProfilePictureUrl: ${_user!.profilePictureUrl}');
    print(
      'DEBUG: Has ProfilePictureBase64: ${_user!.profilePictureBase64 != null}',
    );
    if (_user!.profilePictureBase64 != null) {
      print(
        'DEBUG: ProfilePictureBase64 length: ${_user!.profilePictureBase64!.length}',
      );
      print(
        'DEBUG: ProfilePictureBase64 starts with: ${_user!.profilePictureBase64!.substring(0, min(20, _user!.profilePictureBase64!.length))}...',
      );
    }

    // Also debug the raw Firestore document
    _firestore
        .collection('users')
        .doc(_user!.id)
        .get()
        .then((doc) {
          if (doc.exists) {
            final data = doc.data()!;
            print('DEBUG: Raw Firestore data for user:');
            data.forEach((key, value) {
              if (value is String && value.length > 100) {
                print(
                  'DEBUG: $key: ${value.substring(0, 20)}... (${value.length} chars)',
                );
              } else {
                print('DEBUG: $key: $value');
              }
            });
          } else {
            print('DEBUG: User document does not exist in Firestore');
          }
        })
        .catchError((error) {
          print('DEBUG: Error fetching user document: $error');
        });
  }

  // Reload user data manually
  Future<void> reloadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _errorMessage = "No user logged in";
      notifyListeners();
    }
  }
}
