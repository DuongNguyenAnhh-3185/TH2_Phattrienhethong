import 'package:flutter/material.dart';
import '../../../models/cloud_document_model.dart';
import '../../../models/recommended_document_model.dart';
import '../../../services/borrow_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/file_helper.dart';
import '../../document/cloud_document_detail_screen.dart';

/// Widget hiển thị danh sách "Tài liệu gợi ý cho bạn" tại Trang chủ dưới dạng ListView nằm ngang
/// 1. Gọi Postgres RPC 'get_recommended_documents' với p_user_id
/// 2. Hiển thị Horizontal Card: Tiêu đề, Tags liên quan, và số tag trùng khớp
/// 3. Tự động fallback về các tài liệu mới nhất nếu user chưa có lịch sử mượn
class RecommendedDocumentsSection extends StatefulWidget {
  final String? userId;
  final BorrowService? borrowService;

  const RecommendedDocumentsSection({
    super.key,
    this.userId,
    this.borrowService,
  });

  @override
  State<RecommendedDocumentsSection> createState() =>
      _RecommendedDocumentsSectionState();
}

class _RecommendedDocumentsSectionState
    extends State<RecommendedDocumentsSection> {
  late final BorrowService _borrowService;
  late Future<List<RecommendedDocumentModel>> _recommendationsFuture;

  String? get _currentUserId => widget.userId ?? _borrowService.currentUserId;

  @override
  void initState() {
    super.initState();
    _borrowService = widget.borrowService ?? BorrowService();
    _loadRecommendations();
  }

  void _loadRecommendations() {
    setState(() {
      _recommendationsFuture =
          _borrowService.getRecommendedDocuments(_currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<RecommendedDocumentModel>>(
      future: _recommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSkeleton(isDark);
        }

        final documents = snapshot.data ?? [];
        if (documents.isEmpty) {
          // Nếu không có tài liệu nào trên hệ thống, ẩn khối gợi ý
          return const SizedBox.shrink();
        }

        final hasPersonalized = documents.any((d) => !d.isFallback && d.matchedTagCount > 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề khối gợi ý
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPersonalized
                              ? 'Tài liệu gợi ý cho bạn'
                              : 'Khám phá tài liệu mới nhất',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          hasPersonalized
                              ? 'Dựa trên sở thích các tài liệu bạn từng mượn'
                              : 'Gợi ý các tài liệu vừa được chia sẻ lên hệ thống',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Làm mới gợi ý',
                    onPressed: _loadRecommendations,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ListView nằm ngang hiển thị các Horizontal Card
            SizedBox(
              height: 180,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: documents.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  return _buildRecommendationCard(doc, isDark);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  /// Thẻ tài liệu nằm ngang (Horizontal Card)
  Widget _buildRecommendationCard(
      RecommendedDocumentModel doc, bool isDark) {
    final formatColor = FileHelper.getColorForFormat(doc.fileType);
    final formatIcon = FileHelper.getIconForFormat(doc.fileType);

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Mở màn hình Chi tiết tài liệu để xem vị trí bản đồ và gửi yêu cầu mượn
            final cloudDoc = CloudDocumentModel(
              id: doc.id,
              title: doc.title,
              fileUrl: doc.fileUrl,
              fileType: doc.fileType,
              fileSize: doc.fileSize,
              createdAt: DateTime.now(),
            );

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CloudDocumentDetailScreen(document: cloudDoc),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Hàng trên: Icon định dạng + Badge số tag trùng khớp
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: formatColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(formatIcon, color: formatColor, size: 20),
                    ),
                    const Spacer(),

                    // Huy hiệu số tag trùng khớp
                    if (!doc.isFallback && doc.matchedTagCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.purple.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                size: 13, color: Colors.purple),
                            const SizedBox(width: 3),
                            Text(
                              '${doc.matchedTagCount} tag khớp',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Mới nhất',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),

                // Tiêu đề tài liệu
                Text(
                  doc.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),

                // Danh sách Tags liên quan
                SizedBox(
                  height: 26,
                  child: doc.tags.isNotEmpty
                      ? ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: doc.tags.take(3).map((tag) {
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag.startsWith('#') ? tag : '#$tag',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : Text(
                          'Định dạng: ${doc.fileType.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Khung hiệu ứng đang tải (Skeleton)
  Widget _buildLoadingSkeleton(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 150,
                height: 16,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => Container(
              width: 250,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
