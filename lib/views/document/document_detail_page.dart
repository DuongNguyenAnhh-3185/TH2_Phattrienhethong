import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/document_with_subject.dart';
import '../../../state/document_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/file_helper.dart';
import '../../../widgets/confirm_delete_dialog.dart';
import '../../../widgets/document_type_badge.dart';
import 'edit_document_page.dart';

/// Màn hình Chi tiết tài liệu học tập
class DocumentDetailPage extends StatelessWidget {
  final int documentId;

  const DocumentDetailPage({
    super.key,
    required this.documentId,
  });

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<DocumentWithSubject?>(
      future: docProvider.getDocumentById(documentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final item = snapshot.data;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết tài liệu')),
            body: const Center(child: Text('Tài liệu không tồn tại hoặc đã bị xóa.')),
          );
        }

        final doc = item.document;
        final subject = item.subject;
        final formatColor = FileHelper.getColorForFormat(doc.fileFormat);
        final subjectColor = Color(subject.colorValue);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Thông tin tài liệu'),
            actions: [
              IconButton(
                icon: Icon(
                  doc.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: doc.isFavorite ? const Color(0xFFFBBF24) : null,
                  size: 26,
                ),
                tooltip: 'Yêu thích',
                onPressed: () {
                  docProvider.toggleFavorite(doc.id, doc.isFavorite);
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Chỉnh sửa',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditDocumentPage(documentId: doc.id),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                tooltip: 'Xóa tài liệu',
                onPressed: () async {
                  final confirm = await ConfirmDeleteDialog.show(
                    context: context,
                    title: 'Xóa tài liệu',
                    message: 'Bạn có chắc muốn xóa tài liệu "${doc.title}" khỏi hệ thống?',
                  );
                  if (confirm && context.mounted) {
                    await docProvider.deleteDocument(doc.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã xóa tài liệu thành công'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Hero File Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: formatColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          FileHelper.getIconForFormat(doc.fileFormat),
                          color: formatColor,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      doc.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DocumentTypeBadge(type: doc.documentType),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: subjectColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: subjectColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${subject.code} - ${subject.name}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: subjectColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Description section
              if (doc.description != null && doc.description!.trim().isNotEmpty) ...[
                const _SectionTitle(title: 'Mô tả & Ghi chú học tập'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    ),
                  ),
                  child: Text(
                    doc.description!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Tags section
              if (item.tagList.isNotEmpty) ...[
                const _SectionTitle(title: 'Thẻ tag phân loại'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.tagList.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        tag.startsWith('#') ? tag : '#$tag',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Technical Metadata
              const _SectionTitle(title: 'Thông tin kỹ thuật'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  ),
                ),
                child: Column(
                  children: [
                    _MetaRow(
                      icon: Icons.extension_rounded,
                      label: 'Định dạng tệp',
                      value: doc.fileFormat.toUpperCase(),
                    ),
                    const Divider(height: 1),
                    _MetaRow(
                      icon: Icons.data_usage_rounded,
                      label: 'Kích thước',
                      value: FileHelper.formatFileSize(doc.fileSize),
                    ),
                    const Divider(height: 1),
                    _MetaRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Ngày thêm vào kho',
                      value: DateFormatter.formatDateTime(doc.createdAt),
                    ),
                    const Divider(height: 1),
                    _MetaRow(
                      icon: Icons.update_rounded,
                      label: 'Lần cập nhật cuối',
                      value: DateFormatter.formatDateTime(doc.updatedAt),
                    ),
                    if (doc.filePath != null && doc.filePath!.isNotEmpty) ...[
                      const Divider(height: 1),
                      _MetaRow(
                        icon: Icons.folder_rounded,
                        label: 'Đường dẫn',
                        value: doc.filePath!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action button to simulate opening file
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Đang mở tệp: ${doc.title} (${doc.fileFormat.toUpperCase()})'),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.file_open_rounded),
                  label: const Text(
                    'Mở xem tài liệu',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
