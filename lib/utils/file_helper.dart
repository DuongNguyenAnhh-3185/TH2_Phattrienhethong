import 'package:flutter/material.dart';

/// Tiện ích hỗ trợ quản lý tệp tin tài liệu
class FileHelper {
  FileHelper._();

  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    }
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    return '$mb MB';
  }

  static IconData getIconForFormat(String format) {
    switch (format.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      case 'txt':
        return Icons.article_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  static Color getColorForFormat(String format) {
    switch (format.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFEF4444); // Red
      case 'doc':
      case 'docx':
        return const Color(0xFF2563EB); // Blue
      case 'ppt':
      case 'pptx':
        return const Color(0xFFEA580C); // Orange
      case 'xls':
      case 'xlsx':
        return const Color(0xFF10B981); // Green
      case 'zip':
      case 'rar':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  static const List<String> supportedFormats = [
    'pdf',
    'docx',
    'pptx',
    'xlsx',
    'zip',
    'txt',
  ];
}
