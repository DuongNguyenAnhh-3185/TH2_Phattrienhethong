import 'package:flutter_test/flutter_test.dart';
import 'package:document_manager/models/cloud_document_model.dart';

void main() {
  group('Kiểm thử CloudDocumentModel (Domain Model Tests)', () {
    test('1. Kiểm tra định dạng dung lượng tệp (formattedFileSize)', () {
      final docBytes = CloudDocumentModel(
        id: 'doc-1',
        title: 'sample.txt',
        storagePath: 'documents/u1/123_sample.txt',
        downloadUrl: 'https://storage.googleapis.com/test',
        fileSize: 512,
        mimeType: 'text/plain',
        userId: 'u1',
        createdAt: DateTime(2026, 10, 16),
      );
      expect(docBytes.formattedFileSize, '512 B');

      final docKB = CloudDocumentModel(
        id: 'doc-2',
        title: 'document.docx',
        storagePath: 'documents/u1/123_doc.docx',
        downloadUrl: 'https://storage.googleapis.com/test',
        fileSize: 1024 * 350, // 350 KB
        mimeType: 'application/msword',
        userId: 'u1',
        createdAt: DateTime(2026, 10, 16),
      );
      expect(docKB.formattedFileSize, '350.0 KB');

      final docMB = CloudDocumentModel(
        id: 'doc-3',
        title: 'presentation.pptx',
        storagePath: 'documents/u1/123_pres.pptx',
        downloadUrl: 'https://storage.googleapis.com/test',
        fileSize: (1024 * 1024 * 15.5).toInt(), // 15.5 MB
        mimeType: 'application/vnd.ms-powerpoint',
        userId: 'u1',
        createdAt: DateTime(2026, 10, 16),
      );
      expect(docMB.formattedFileSize, '15.50 MB');
    });

    test('2. Kiểm tra nhận diện phần mở rộng (fileExtension) và icon', () {
      final pdfDoc = CloudDocumentModel(
        id: 'pdf-1',
        title: 'Bao_Cao_Kien_Truc.pdf',
        storagePath: 'documents/u1/pdf.pdf',
        downloadUrl: 'https://storage.googleapis.com/test',
        fileSize: 2048,
        mimeType: 'application/pdf',
        userId: 'u1',
        createdAt: DateTime.now(),
      );
      expect(pdfDoc.fileExtension, 'PDF');

      final imgDoc = CloudDocumentModel(
        id: 'img-1',
        title: 'Architecture_Diagram.png',
        storagePath: 'documents/u1/img.png',
        downloadUrl: 'https://storage.googleapis.com/test',
        fileSize: 4096,
        mimeType: 'image/png',
        userId: 'u1',
        createdAt: DateTime.now(),
      );
      expect(imgDoc.fileExtension, 'PNG');
    });

    test('3. Kiểm tra chuyển đổi toFirestore Map', () {
      final date = DateTime(2026, 10, 16, 10, 30);
      final doc = CloudDocumentModel(
        id: 'doc-test',
        title: 'De_Cuong.pdf',
        storagePath: 'documents/user123/123_De_Cuong.pdf',
        downloadUrl: 'https://storage.googleapis.com/download/test',
        fileSize: 1048576,
        mimeType: 'application/pdf',
        userId: 'user123',
        createdAt: date,
      );

      final map = doc.toFirestore();
      expect(map['title'], 'De_Cuong.pdf');
      expect(map['fileSize'], 1048576);
      expect(map['userId'], 'user123');
      expect(map['mimeType'], 'application/pdf');
    });
  });
}
