/// Model đại diện cho một yêu cầu mượn tài liệu trong bảng `borrow_requests` trên Supabase
class BorrowRequestModel {
  final String id;
  final String documentId;
  final String requesterId;
  final String ownerId;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final String? documentTitle;
  final String? requesterEmail;
  final String? requesterName;

  const BorrowRequestModel({
    required this.id,
    required this.documentId,
    required this.requesterId,
    required this.ownerId,
    this.status = 'pending',
    required this.createdAt,
    this.documentTitle,
    this.requesterEmail,
    this.requesterName,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory BorrowRequestModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return BorrowRequestModel(
      id: (map['id'] ?? '').toString(),
      documentId: (map['document_id'] ?? '').toString(),
      requesterId: (map['requester_id'] ?? '').toString(),
      ownerId: (map['owner_id'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString().toLowerCase(),
      createdAt: parseDate(map['created_at']),
      documentTitle: map['document_title']?.toString() ??
          (map['documents'] is Map ? map['documents']['title']?.toString() : null),
      requesterEmail: map['requester_email']?.toString() ??
          (map['profiles'] is Map ? map['profiles']['email']?.toString() : null),
      requesterName: map['requester_name']?.toString() ??
          (map['profiles'] is Map ? map['profiles']['display_name']?.toString() : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'document_id': documentId,
      'requester_id': requesterId,
      'owner_id': ownerId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BorrowRequestModel copyWith({
    String? id,
    String? documentId,
    String? requesterId,
    String? ownerId,
    String? status,
    DateTime? createdAt,
    String? documentTitle,
    String? requesterEmail,
    String? requesterName,
  }) {
    return BorrowRequestModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      requesterId: requesterId ?? this.requesterId,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      documentTitle: documentTitle ?? this.documentTitle,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      requesterName: requesterName ?? this.requesterName,
    );
  }
}
