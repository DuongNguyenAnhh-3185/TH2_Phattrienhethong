import 'package:flutter/material.dart';

/// Enum phân loại tài liệu học tập theo mô hình phân loại của Cashew
enum DocumentType {
  lecture,    // Bài giảng / Slide bài học
  assignment, // Bài tập / Đồ án / Bài tập lớn
  reference,  // Tài liệu tham khảo / Sách / Giáo trình
  exam,       // Đề thi / Đề cương ôn tập
}

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.lecture:
        return 'Bài giảng';
      case DocumentType.assignment:
        return 'Bài tập';
      case DocumentType.reference:
        return 'Tham khảo';
      case DocumentType.exam:
        return 'Đề thi';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentType.lecture:
        return Icons.menu_book_rounded;
      case DocumentType.assignment:
        return Icons.assignment_rounded;
      case DocumentType.reference:
        return Icons.auto_stories_rounded;
      case DocumentType.exam:
        return Icons.quiz_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DocumentType.lecture:
        return const Color(0xFF2563EB); // Royal Blue
      case DocumentType.assignment:
        return const Color(0xFFD97706); // Amber
      case DocumentType.reference:
        return const Color(0xFF059669); // Emerald Green
      case DocumentType.exam:
        return const Color(0xFFDC2626); // Crimson Red
    }
  }
}

