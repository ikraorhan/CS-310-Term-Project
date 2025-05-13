import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String? profilePictureUrl;
  final String? profilePictureBase64;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.profilePictureUrl,
    this.profilePictureBase64,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      username: data['username'] ?? 'User',
      email: data['email'] ?? '',
      profilePictureUrl: data['profilePicture'],
      profilePictureBase64: data['profilePictureBase64'],
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  // Create an empty user
  factory UserModel.empty() {
    return UserModel(
      id: '',
      username: '',
      email: '',
      createdAt: DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? profilePictureUrl,
    String? profilePictureBase64,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      profilePictureBase64: profilePictureBase64 ?? this.profilePictureBase64,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
