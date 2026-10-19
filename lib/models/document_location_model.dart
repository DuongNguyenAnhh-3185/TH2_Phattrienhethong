/// Model đại diện cho vị trí vật lý của tài liệu lưu trữ trên Supabase (Bảng `locations`)
class DocumentLocationModel {
  final String? id;
  final String documentId;
  final double latitude;
  final double longitude;
  final String? addressNote;
  final DateTime? createdAt;

  const DocumentLocationModel({
    this.id,
    required this.documentId,
    required this.latitude,
    required this.longitude,
    this.addressNote,
    this.createdAt,
  });

  factory DocumentLocationModel.fromMap(Map<String, dynamic> map) {
    return DocumentLocationModel(
      id: map['id']?.toString(),
      documentId: (map['document_id'] ?? '').toString(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      addressNote: map['address_note']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'document_id': documentId,
      'latitude': latitude,
      'longitude': longitude,
      if (addressNote != null) 'address_note': addressNote,
    };
  }

  DocumentLocationModel copyWith({
    String? id,
    String? documentId,
    double? latitude,
    double? longitude,
    String? addressNote,
    DateTime? createdAt,
  }) {
    return DocumentLocationModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressNote: addressNote ?? this.addressNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
