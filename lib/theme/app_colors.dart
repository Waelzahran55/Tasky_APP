import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const violet = Color(0xFF7C4DFF);
  static const indigo = Color(0xFF4F6BED);
  static const pink = Color(0xFFFF5C8A);
  static const orange = Color(0xFFFF9A44);
  static const teal = Color(0xFF14B8A6);
  static const background = Color(0xFFF5F2FF);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, indigo],
  );

  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, orange],
  );
}
