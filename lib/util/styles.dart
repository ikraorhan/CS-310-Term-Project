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
}
