import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/document_with_subject.dart';
import '../../../../state/document_provider.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/date_formatter.dart';
import '../../../../utils/file_helper.dart';
import '../../../../widgets/confirm_delete_dialog.dart';
import '../../../../widgets/document_type_badge.dart';
import '../../document/document_detail_page.dart';
import '../../document/edit_document_page.dart';

/// Thẻ hiển thị một tài liệu học tập trong danh sách (theo phong cách transaction tile của Cashew)
class DocumentListTile extends StatelessWidget {
  final DocumentWithSubject item;

  const DocumentListTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final doc = item.document;
    final subject = item.subject;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatColor = FileHelper.getColorForFormat(doc.fileFormat);
    final subjectColor = Color(subject.colorValue);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DocumentDetailPage(documentId: doc.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Subject badge, Type badge, Favorite Star, Menu
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: subjectColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: subjectColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: subjectColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          subject.code,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: subjectColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  DocumentTypeBadge(type: doc.documentType, isDense: true),
                  const Spacer(),
                  // Star Favorite Button
                  IconButton(
                    icon: Icon(
                      doc.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: doc.isFavorite ? const Color(0xFFFBBF24) : Colors.grey,
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                    onPressed: () {
                      context
                          .read<DocumentProvider>()
                          .toggleFavorite(doc.id, doc.isFavorite);
                    },
                  ),
                  // More Popup Menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditDocumentPage(documentId: doc.id),
                          ),
                        );
                      } else if (value == 'delete') {
                        final confirm = await ConfirmDeleteDialog.show(
                          context: context,
                          title: 'Xóa tài liệu',
                          message: 'Bạn có chắc chắn muốn xóa "${doc.title}" khỏi hệ thống?',
                        );
                        if (confirm && context.mounted) {
                          await context.read<DocumentProvider>().deleteDocument(doc.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã xóa tài liệu thành công'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            SizedBox(width: 10),
                            Text('Xóa tài liệu', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Document Title & Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: formatColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        FileHelper.getIconForFormat(doc.fileFormat),
                        color: formatColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (doc.description != null && doc.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            doc.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Tags Row
              if (item.tagList.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: item.tagList.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag.startsWith('#') ? tag : '#$tag',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Bottom row: file size, format, updated date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        doc.fileFormat.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: formatColor,
                        ),
                      ),
                      const Text(' • ', style: TextStyle(color: Colors.grey)),
                      Text(
                        FileHelper.formatFileSize(doc.fileSize),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.formatRelative(doc.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
