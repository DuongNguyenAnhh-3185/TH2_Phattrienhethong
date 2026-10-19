/// Model đại diện cho phân quyền trong bảng `document_permissions` trên Supabase
class DocumentPermissionModel {
  final String? id;
  final String documentId;
  final String userId;
  final String role; // 'viewer' hoặc 'editor'
  final DateTime? createdAt;
  final String? userEmail;
  final String? userDisplayName;

  const DocumentPermissionModel({
    this.id,
    required this.documentId,
    required this.userId,
    required this.role,
    this.createdAt,
    this.userEmail,
    this.userDisplayName,
  });

  factory DocumentPermissionModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val);
      }
      return null;
    }

    // Nếu có join với bảng profiles
    final profile = map['profiles'] as Map<String, dynamic>?;

    return DocumentPermissionModel(
      id: map['id']?.toString(),
      documentId: (map['document_id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      role: (map['role'] ?? 'viewer').toString().toLowerCase(),
      createdAt: parseDate(map['created_at']),
      userEmail: profile != null ? profile['email']?.toString() : map['user_email']?.toString(),
      userDisplayName: profile != null
          ? profile['display_name']?.toString()
          : map['user_display_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'document_id': documentId,
      'user_id': userId,
      'role': role.toLowerCase(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
