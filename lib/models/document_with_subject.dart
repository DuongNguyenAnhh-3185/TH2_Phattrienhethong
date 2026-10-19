import '../database/database.dart';

/// DTO (Data Transfer Object) ghép cặp Tài liệu cùng Môn học tương ứng
/// Tương tự cách Cashew map TransactionWithCategory
class DocumentWithSubject {
  final Document document;
  final Subject subject;

  const DocumentWithSubject({
    required this.document,
    required this.subject,
  });

  /// Danh sách các nhãn tag được chuẩn hóa từ chuỗi lưu trong database
  List<String> get tagList {
    if (document.tags.trim().isEmpty) return const [];
    return document.tags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }
}
