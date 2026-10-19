import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Model đại diện cho một tài liệu được lưu trữ trên Supabase Storage & Database
class CloudDocumentModel {
  final String id;
  final String ownerId;
  final String title;
  final String fileUrl;
  final String fileType;
  final int fileSize; // Dung lượng tính bằng Bytes
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? storagePath;
  final String userRole; // 'owner', 'editor', hoặc 'viewer'
  final String? ownerEmail;
  final String? ownerDisplayName;

  CloudDocumentModel({
    required this.id,
    String? ownerId,
    String? userId,
    required this.title,
    String? fileUrl,
    String? downloadUrl,
    String? fileType,
    String? mimeType,
    required this.fileSize,
    required this.createdAt,
    DateTime? updatedAt,
    this.storagePath,
    this.userRole = 'owner',
    this.ownerEmail,
    this.ownerDisplayName,
  })  : ownerId = ownerId ?? userId ?? '',
        fileUrl = fileUrl ?? downloadUrl ?? '',
        fileType = fileType ?? mimeType ?? 'bin',
        updatedAt = updatedAt ?? createdAt;

  /// Các getter tương thích ngược
  String get downloadUrl => fileUrl;
  String get userId => ownerId;
  String get mimeType => fileType;
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'storagePath': storagePath ?? '',
        'downloadUrl': fileUrl,
        'fileSize': fileSize,
        'mimeType': fileType,
        'userId': ownerId,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Factory chuyển đổi từ dữ liệu Record của Supabase Table `documents`
  factory CloudDocumentModel.fromMap(
    Map<String, dynamic> map, {
    String? userRole,
    String? currentUserId,
  }) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final ownerId = (map['owner_id'] ?? map['userId'] ?? '').toString();

    // Xác định vai trò: nếu có userRole truyền vào thì dùng, hoặc tự kiểm tra theo currentUserId
    String effectiveRole = userRole ?? 'owner';
    if (userRole == null && currentUserId != null) {
      effectiveRole = (ownerId == currentUserId) ? 'owner' : 'viewer';
    }

    return CloudDocumentModel(
      id: (map['id'] ?? '').toString(),
      ownerId: ownerId,
      title: (map['title'] ?? 'Tài liệu chưa đặt tên').toString(),
      fileUrl: (map['file_url'] ?? map['downloadUrl'] ?? '').toString(),
      fileType: (map['file_type'] ?? map['mimeType'] ?? '').toString(),
      fileSize: (map['file_size'] ?? map['fileSize'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
      updatedAt: parseDate(map['updated_at'] ?? map['updatedAt'] ?? map['created_at']),
      storagePath: map['storage_path']?.toString() ?? map['storagePath']?.toString(),
      userRole: effectiveRole.toLowerCase(),
      ownerEmail: map['owner_email']?.toString(),
      ownerDisplayName: map['owner_display_name']?.toString(),
    );
  }

  /// Chuyển đổi thành Map để ghi / cập nhật vào Supabase
  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'owner_id': ownerId,
      'title': title,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (storagePath != null) 'storage_path': storagePath,
    };
  }

  /// Bản sao có chỉnh sửa thuộc tính (Immutability pattern)
  CloudDocumentModel copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? fileUrl,
    String? fileType,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? storagePath,
    String? userRole,
    String? ownerEmail,
    String? ownerDisplayName,
  }) {
    return CloudDocumentModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      storagePath: storagePath ?? this.storagePath,
      userRole: userRole ?? this.userRole,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerDisplayName: ownerDisplayName ?? this.ownerDisplayName,
    );
  }

  // ==================== CÁC HÀM TIỆN ÍCH HIỂN THỊ ====================

  /// Định dạng dung lượng tệp đọc được: B, KB, MB, GB
  String get formattedFileSize {
    if (fileSize <= 0) return '0 B';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Định dạng ngày giờ tải lên (dd/MM/yyyy HH:mm)
  String get formattedCreatedAt {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  /// Định dạng ngày giờ cập nhật lần cuối
  String get formattedUpdatedAt {
    return DateFormat('dd/MM/yyyy HH:mm').format(updatedAt);
  }

  /// Lấy phần mở rộng định dạng của tệp (Ví dụ: PDF, DOCX, XLSX, PNG)
  String get fileExtension {
    if (fileType.isNotEmpty && !fileType.contains('/') && fileType.length <= 5) {
      return fileType.toUpperCase();
    }
    final parts = title.split('.');
    if (parts.length > 1) {
      return parts.last.toUpperCase();
    }
    return 'FILE';
  }

  /// Màu sắc đại diện theo định dạng tệp tin
  Color get typeColor {
    final ext = fileExtension.toLowerCase();
    switch (ext) {
      case 'pdf':
        return const Color(0xFFEF4444); // Đỏ PDF
      case 'doc':
      case 'docx':
        return const Color(0xFF2563EB); // Xanh dương Word
      case 'xls':
      case 'xlsx':
      case 'csv':
        return const Color(0xFF10B981); // Xanh lá Excel
      case 'ppt':
      case 'pptx':
        return const Color(0xFFF97316); // Cam PowerPoint
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
      case 'svg':
        return const Color(0xFF8B5CF6); // Tím Ảnh
      case 'txt':
      case 'md':
        return const Color(0xFF64748B); // Xám văn bản
      case 'zip':
      case 'rar':
      case '7z':
        return const Color(0xFFEAB308); // Vàng nén
      default:
        return const Color(0xFF475569);
    }
  }

  /// Icon đại diện trực quan theo loại tệp
  IconData get fileIcon {
    final ext = fileExtension.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
      case 'svg':
        return Icons.image_rounded;
      case 'txt':
      case 'md':
        return Icons.text_snippet_rounded;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  // ==================== KIỂM TRA PHÂN QUYỀN (PERMISSIONS) ====================

  /// Kiểm tra có phải là Chủ sở hữu (Owner)
  bool get isOwner => userRole.toLowerCase() == 'owner';

  /// Kiểm tra có phải Người chỉnh sửa (Editor)
  bool get isEditor => userRole.toLowerCase() == 'editor';

  /// Kiểm tra có phải Người xem (Viewer)
  bool get isViewer => userRole.toLowerCase() == 'viewer';

  /// Quyền đổi tên tài liệu: Chỉ Owner hoặc Editor
  bool get canEdit => isOwner || isEditor;

  /// Quyền chia sẻ tài liệu: Chỉ Owner
  bool get canShare => isOwner;

  /// Quyền xóa tài liệu: Chỉ Owner
  bool get canDelete => isOwner;

  /// Nhãn hiển thị vai trò người dùng
  String get roleDisplayName {
    switch (userRole.toLowerCase()) {
      case 'owner':
        return 'Owner';
      case 'editor':
        return 'Editor';
      case 'viewer':
        return 'Viewer';
      default:
        return 'Viewer';
    }
  }

  /// Màu sắc của nhãn vai trò (Role Badge)
  Color get roleBadgeColor {
    switch (userRole.toLowerCase()) {
      case 'owner':
        return const Color(0xFF2563EB); // Xanh dương
      case 'editor':
        return const Color(0xFFD97706); // Cam đất
      case 'viewer':
        return const Color(0xFF059669); // Xanh ngọc
      default:
        return const Color(0xFF64748B);
    }
  }
}
