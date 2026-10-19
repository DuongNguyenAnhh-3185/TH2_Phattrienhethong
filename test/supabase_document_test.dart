import 'package:flutter_test/flutter_test.dart';
import 'package:document_manager/models/cloud_document_model.dart';
import 'package:document_manager/models/user_profile_model.dart';
import 'package:document_manager/models/document_permission_model.dart';

void main() {
  group('Kiểm thử Mô hình Phân quyền & Supabase Models', () {
    test('1. Kiểm tra quyền hạn theo vai trò (Owner, Editor, Viewer)', () {
      final ownerDoc = CloudDocumentModel(
        id: 'doc-1',
        ownerId: 'user-owner',
        title: 'BaoCao.pdf',
        fileUrl: 'https://supabase.co/storage/v1/object/public/documents/u1/1.pdf',
        fileType: 'pdf',
        fileSize: 1024 * 500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userRole: 'owner',
      );

      expect(ownerDoc.isOwner, true);
      expect(ownerDoc.isEditor, false);
      expect(ownerDoc.isViewer, false);
      expect(ownerDoc.canEdit, true);
      expect(ownerDoc.canShare, true);
      expect(ownerDoc.canDelete, true);
      expect(ownerDoc.roleDisplayName, 'Owner');

      final editorDoc = ownerDoc.copyWith(userRole: 'editor');
      expect(editorDoc.isOwner, false);
      expect(editorDoc.isEditor, true);
      expect(editorDoc.isViewer, false);
      expect(editorDoc.canEdit, true); // Editor được phép đổi tên
      expect(editorDoc.canShare, false); // Editor không được chia sẻ
      expect(editorDoc.canDelete, false); // Editor không được xóa
      expect(editorDoc.roleDisplayName, 'Editor');

      final viewerDoc = ownerDoc.copyWith(userRole: 'viewer');
      expect(viewerDoc.isOwner, false);
      expect(viewerDoc.isEditor, false);
      expect(viewerDoc.isViewer, true);
      expect(viewerDoc.canEdit, false);
      expect(viewerDoc.canShare, false);
      expect(viewerDoc.canDelete, false);
      expect(viewerDoc.roleDisplayName, 'Viewer');
    });

    test('2. Kiểm tra chuyển đổi dữ liệu từ Supabase Database Record (fromMap / toMap)', () {
      final record = {
        'id': 'supabase-doc-uuid-123',
        'owner_id': 'firebase-uid-abc',
        'title': 'Giao_Trinh_Kien_Truc.docx',
        'file_url': 'https://storage.supabase.co/documents/firebase-uid-abc/123_Giao_Trinh.docx',
        'file_type': 'docx',
        'file_size': 2048576,
        'created_at': '2026-10-17T08:30:00.000Z',
        'updated_at': '2026-10-17T09:00:00.000Z',
      };

      final doc = CloudDocumentModel.fromMap(
        record,
        userRole: 'owner',
        currentUserId: 'firebase-uid-abc',
      );

      expect(doc.id, 'supabase-doc-uuid-123');
      expect(doc.ownerId, 'firebase-uid-abc');
      expect(doc.title, 'Giao_Trinh_Kien_Truc.docx');
      expect(doc.fileExtension, 'DOCX');
      expect(doc.fileSize, 2048576);
      expect(doc.isOwner, true);

      final map = doc.toMap();
      expect(map['title'], 'Giao_Trinh_Kien_Truc.docx');
      expect(map['owner_id'], 'firebase-uid-abc');
      expect(map['file_type'], 'docx');
    });

    test('3. Kiểm tra UserProfileModel (Bảng profiles)', () {
      final profileMap = {
        'id': 'firebase-uid-123',
        'email': 'developer@cloud.edu.vn',
        'display_name': 'Nguyen Van A',
        'avatar_url': 'https://google.com/avatar.jpg',
      };

      final profile = UserProfileModel.fromMap(profileMap);
      expect(profile.id, 'firebase-uid-123');
      expect(profile.email, 'developer@cloud.edu.vn');
      expect(profile.displayName, 'Nguyen Van A');

      final serialized = profile.toMap();
      expect(serialized['id'], 'firebase-uid-123');
      expect(serialized['email'], 'developer@cloud.edu.vn');
    });

    test('4. Kiểm tra DocumentPermissionModel (Bảng document_permissions)', () {
      final permMap = {
        'id': 'perm-1',
        'document_id': 'doc-123',
        'user_id': 'user-recipient-456',
        'role': 'editor',
        'created_at': '2026-10-17T10:00:00.000Z',
      };

      final perm = DocumentPermissionModel.fromMap(permMap);
      expect(perm.documentId, 'doc-123');
      expect(perm.userId, 'user-recipient-456');
      expect(perm.role, 'editor');
    });
  });
}
