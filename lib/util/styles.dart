// lib/util/styles.dart

import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static final mainTitle = TextStyle(
    fontFamily: 'LibreBaskerville',
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.mainColor,
  );

  // Original label style (if you use it elsewhere)
  static final label = TextStyle(
    fontFamily: 'LibreBaskerville',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.mainColor,
  );

  // New login label style with black text.
  static const loginLabel = TextStyle(
    fontFamily: 'LibreBaskerville',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.labelTextColor,
  );

  static final welcomeTitle = TextStyle(
    fontFamily: 'LibreBaskerville',
    fontSize: 60,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
    color: AppColors.mainColor,
  );

  // Header style for page titles
  static final header = TextStyle(
    fontFamily: 'LibreBaskerville',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.mainColor,
  );

  // Task styles
  static final taskTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static final taskDescription = TextStyle(fontSize: 14, color: Colors.black54);

  static final taskDate = TextStyle(
    fontSize: 12,
    color: Colors.grey.shade600,
    fontStyle: FontStyle.italic,
  );
}
