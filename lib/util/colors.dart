import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static Color mainColor = const Color(0xFF6C63FF);
  static Color _backgroundColor = Colors.white; // default color

  static Color get backgroundColor => _backgroundColor;

  static Future<void> initializeBackgroundColor() async {
    final prefs = await SharedPreferences.getInstance();

    // Try to read as int first
    final colorValue = prefs.getInt('backgroundColor');

    if (colorValue != null) {
      _backgroundColor = Color(colorValue);
    } else {
      // If int is null, try to read as string and parse
      final colorString = prefs.getString('backgroundColor');
      if (colorString != null) {
        try {
          _backgroundColor = Color(int.parse(colorString));
        } catch (e) {
          print('Error parsing backgroundColor string: $e');
          // Keep default color on error
        }
      }
    }
  }

  static Future<void> setBackgroundColor(Color color) async {
    _backgroundColor = color;
    final prefs = await SharedPreferences.getInstance();

    // Always store as int to avoid type issues in the future
    await prefs.setInt('backgroundColor', color.toARGB32());
  }

  static const Color labelTextColor = Colors.black;
}
