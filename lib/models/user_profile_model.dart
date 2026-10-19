/// Model đại diện cho một người dùng trong bảng `profiles` trên Supabase
class UserProfileModel {
  final String id; // Khớp với Firebase UID (user.uid)
  final String email;
  final String displayName;
  final String avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfileModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val);
      }
      return null;
    }

    return UserProfileModel(
      id: (map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      displayName: (map['display_name'] ?? map['displayName'] ?? '').toString(),
      avatarUrl: (map['avatar_url'] ?? map['avatarUrl'] ?? '').toString(),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
