import 'package:flutter/material.dart';

/// Bảng màu hiện đại theo phong cách Cashew (Vibrant, Sleek & Accessible)
class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);

  // Secondary & Accents
  static const Color secondary = Color(0xFF7C3AED); // Deep Purple
  static const Color accent = Color(0xFF06B6D4); // Cyan Accent

  // Background & Surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color favorite = Color(0xFFEC4899);

  // Neutral Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color dividerLight = Color(0xFFE2E8F0);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color dividerDark = Color(0xFF334155);

  // Preset Colors for Subjects (tương tự bảng chọn màu danh mục của Cashew)
  static const List<Color> subjectPresets = [
    Color(0xFF2563EB), // Blue
    Color(0xFF7C3AED), // Purple
    Color(0xFF059669), // Green
    Color(0xFFD97706), // Amber
    Color(0xFFDC2626), // Red
    Color(0xFF0891B2), // Cyan
    Color(0xFFDB2777), // Pink
    Color(0xFF4F46E5), // Indigo
    Color(0xFF65A30D), // Lime
    Color(0xFFEA580C), // Orange
  ];
}
