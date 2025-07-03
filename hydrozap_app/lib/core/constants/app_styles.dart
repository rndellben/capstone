import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body Text
  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle secondaryText = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  // Button Text
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Error Text
  static const TextStyle errorText = TextStyle(
    fontSize: 14,
    color: AppColors.error,
    fontWeight: FontWeight.bold,
  );

  // Input Field Style
  static InputDecoration inputFieldStyle(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
