import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle title = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
  );

  static const TextStyle button = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle mono = TextStyle(
    color: Color(0xFF00FF88),
    fontFamily: 'monospace',
    fontSize: 13,
  );
}
