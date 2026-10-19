import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Dịch vụ lưu trữ tệp và dữ liệu đám mây (Cloud Document Service)
/// Triển khai Bước 6.6: Tích hợp Lưu trữ tệp (Firebase Storage) và Dữ liệu (Cloud Firestore)
class CloudDocumentService {
  static final CloudDocumentService instance = CloudDocumentService._internal();

  CloudDocumentService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createDocumentMetadata({
    required String title,
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    required String fileName,
    required int fileSizeBytes,
  }) async {
    final document = _firestore.collection('documents').doc();
    await document.set({
      'title': title,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'uploaderEmail': ownerEmail,
      'uploadedBy': ownerId,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'uploadStatus': 'uploading',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  Future<void> uploadDocumentBytes({
    required Uint8List bytes,
    required String ownerId,
    required String documentId,
    required String fileName,
    String? contentType,
  }) async {
    final storagePath = 'documents/$ownerId/$documentId/$fileName';
    final metadata = contentType == null
        ? null
        : SettableMetadata(contentType: contentType);
    await _storage.ref(storagePath).putData(bytes, metadata);
    await _firestore.collection('documents').doc(documentId).update({
      'storagePath': storagePath,
      'uploadStatus': 'ready',
    });
  }

  Future<void> deleteDocumentMetadata(String documentId) async {
    await _firestore.collection('documents').doc(documentId).delete();
  }

  Future<Uint8List> downloadDocumentBytes(String storagePath) async {
    final bytes = await _storage.ref(storagePath).getData(50 * 1024 * 1024);
    if (bytes == null) {
      throw StateError('Không thể tải dữ liệu tài liệu.');
    }
    return bytes;
  }

  Future<void> requestBorrow({
    required String documentId,
    required String requesterId,
    required String requesterName,
    required String requesterEmail,
  }) async {
    final request = _firestore
        .collection('documents')
        .doc(documentId)
        .collection('borrowRequests')
        .doc(requesterId);
    final existing = await request.get();

    if (existing.exists) {
      final status = existing.data()?['status'];
      if (status != 'rejected') {
        throw StateError('Yêu cầu mượn hiện tại chưa thể gửi lại.');
      }
      await request.update({
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.delete(),
      });
      return;
    }

    await request.set({
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterEmail': requesterEmail,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reviewBorrowRequest({
    required String documentId,
    required String requesterId,
    required bool approve,
  }) async {
    await _firestore
        .collection('documents')
        .doc(documentId)
        .collection('borrowRequests')
        .doc(requesterId)
        .update({
          'status': approve ? 'approved' : 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Lấy danh sách tài liệu thời gian thực từ Cloud Firestore
  Stream<QuerySnapshot<Map<String, dynamic>>> getDocumentsStream() {
    return _firestore
        .collection('documents')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getBorrowRequestsStream(
    String documentId,
  ) {
    return _firestore
        .collection('documents')
        .doc(documentId)
        .collection('borrowRequests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getBorrowRequestStream(
    String documentId,
    String requesterId,
  ) {
    return _firestore
        .collection('documents')
        .doc(documentId)
        .collection('borrowRequests')
        .doc(requesterId)
        .snapshots();
  }
}
