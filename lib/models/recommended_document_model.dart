/// Model đại diện cho một tài liệu được gợi ý từ Postgres RPC hoặc tài liệu mới nhất
class RecommendedDocumentModel {
  final String id;
  final String title;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final List<String> tags;
  final int matchedTagCount;
  final bool isFallback; // True nếu là tài liệu mới nhất do user chưa có lịch sử mượn

  const RecommendedDocumentModel({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.tags,
    required this.matchedTagCount,
    this.isFallback = false,
  });

  factory RecommendedDocumentModel.fromMap(
    Map<String, dynamic> map, {
    bool isFallback = false,
  }) {
    List<String> parseTags(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      } else if (val is String && val.trim().isNotEmpty) {
        return val
            .split(',')
            .map((e) => e.trim().replaceAll(RegExp(r'^[#\s]+'), ''))
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    return RecommendedDocumentModel(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? 'Tài liệu chưa đặt tên').toString(),
      fileUrl: (map['file_url'] ?? '').toString(),
      fileType: (map['file_type'] ?? 'bin').toString().toLowerCase(),
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      tags: parseTags(map['tags']),
      matchedTagCount: (map['matched_tag_count'] as num?)?.toInt() ?? 0,
      isFallback: isFallback,
    );
  }
}
