import 'document_type.dart';

enum SortOption {
  newest,
  oldest,
  titleAsc,
  titleDesc,
}

extension SortOptionExtension on SortOption {
  String get label {
    switch (this) {
      case SortOption.newest:
        return 'Mới nhất';
      case SortOption.oldest:
        return 'Cũ nhất';
      case SortOption.titleAsc:
        return 'Tên (A-Z)';
      case SortOption.titleDesc:
        return 'Tên (Z-A)';
    }
  }
}

/// Model đóng gói bộ lọc đa tiêu chí cho tài liệu học tập
class DocumentFilter {
  final String? searchQuery;
  final int? subjectId;
  final DocumentType? documentType;
  final bool isFavoriteOnly;
  final String? tag;
  final SortOption sortBy;

  const DocumentFilter({
    this.searchQuery,
    this.subjectId,
    this.documentType,
    this.isFavoriteOnly = false,
    this.tag,
    this.sortBy = SortOption.newest,
  });

  DocumentFilter copyWith({
    String? searchQuery,
    int? subjectId,
    DocumentType? documentType,
    bool? isFavoriteOnly,
    String? tag,
    SortOption? sortBy,
    bool clearSubject = false,
    bool clearType = false,
    bool clearTag = false,
  }) {
    return DocumentFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
      documentType: clearType ? null : (documentType ?? this.documentType),
      isFavoriteOnly: isFavoriteOnly ?? this.isFavoriteOnly,
      tag: clearTag ? null : (tag ?? this.tag),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilter {
    return (searchQuery != null && searchQuery!.trim().isNotEmpty) ||
        subjectId != null ||
        documentType != null ||
        isFavoriteOnly ||
        (tag != null && tag!.trim().isNotEmpty);
  }

  DocumentFilter reset() {
    return const DocumentFilter(sortBy: SortOption.newest);
  }
}
