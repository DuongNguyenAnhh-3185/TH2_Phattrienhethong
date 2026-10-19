import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../database/database.dart';
import '../../../models/document_with_subject.dart';
import '../../../state/document_provider.dart';
import '../../../state/subject_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/search_bar_widget.dart';
import '../document/edit_document_page.dart';
import '../subject/manage_subjects_page.dart';
import 'widgets/document_list_tile.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/recommended_documents_section.dart';
import 'widgets/statistics_card.dart';
import 'widgets/subject_horizontal_list.dart';

/// Màn hình chính (Dashboard & Danh sách tài liệu)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();
    final subjectProvider = context.watch<SubjectProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cashew Docs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Quản lý tài liệu học tập',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Quản lý môn học',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageSubjectsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Subject>>(
        stream: subjectProvider.subjectsStream,
        builder: (context, subjectSnapshot) {
          if (subjectSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Lỗi kết nối cơ sở dữ liệu: ${subjectSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final subjects = subjectSnapshot.data ?? [];

          return StreamBuilder<List<DocumentWithSubject>>(
            stream: docProvider.documentsStream,
            builder: (context, docSnapshot) {
              if (docSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Lỗi tải tài liệu: ${docSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final documents = docSnapshot.data ?? [];
              final isLoading = docSnapshot.connectionState == ConnectionState.waiting && !docSnapshot.hasData;

              return RefreshIndicator(
                onRefresh: () async {
                  // Drift phản ứng tự động theo stream, hàm này để làm mới trải nghiệm người dùng
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // Search bar & Statistics Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thanh tìm kiếm
                            SearchBarWidget(
                              controller: _searchController,
                              hasActiveFilter: docProvider.filter.hasActiveFilter,
                              onChanged: (val) {
                                docProvider.setSearchQuery(val);
                              },
                              onClear: () {
                                _searchController.clear();
                                docProvider.setSearchQuery(null);
                              },
                              onFilterPressed: () {
                                FilterBottomSheet.show(context);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Thẻ Thống kê tổng quan (Statistics Card)
                            StreamBuilder<int>(
                              stream: docProvider.totalCountStream,
                              builder: (context, totalSnap) {
                                return StreamBuilder<int>(
                                  stream: docProvider.favoriteCountStream,
                                  builder: (context, favSnap) {
                                    return StatisticsCard(
                                      totalCount: totalSnap.data ?? documents.length,
                                      favoriteCount: favSnap.data ?? 0,
                                      subjectCount: subjects.length,
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Danh sách môn học cuộn ngang
                            SubjectHorizontalList(subjects: subjects),
                            const SizedBox(height: 16),

                            // Danh sách Tài liệu gợi ý cho bạn (hoặc Fallback tài liệu mới nhất)
                            const RecommendedDocumentsSection(),

                            // Header danh sách tài liệu & Badge trạng thái lọc
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Danh sách tài liệu',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${documents.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (docProvider.filter.hasActiveFilter)
                                  TextButton.icon(
                                    onPressed: () {
                                      _searchController.clear();
                                      docProvider.resetFilter();
                                    },
                                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                                    label: const Text('Xóa bộ lọc', style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor: AppColors.error,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Loading State
                    if (isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    // Empty State
                    else if (documents.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: docProvider.filter.hasActiveFilter
                            ? EmptyStateView(
                                icon: Icons.filter_alt_off_rounded,
                                title: 'Không tìm thấy kết quả',
                                description:
                                    'Không có tài liệu nào khớp với tiêu chí tìm kiếm hiện tại.\nHãy thử đổi từ khóa hoặc xóa bớt tiêu chí lọc.',
                                actionLabel: 'Xóa bộ lọc',
                                onActionPressed: () {
                                  _searchController.clear();
                                  docProvider.resetFilter();
                                },
                              )
                            : EmptyStateView(
                                icon: Icons.note_add_rounded,
                                title: 'Chưa có tài liệu nào',
                                description:
                                    'Hãy bắt đầu tổ chức góc học tập bằng cách thêm tài liệu bài giảng, bài tập hoặc sách tham khảo đầu tiên!',
                                actionLabel: 'Thêm tài liệu mới',
                                onActionPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const EditDocumentPage(),
                                    ),
                                  );
                                },
                              ),
                      )
                    // List of Documents
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final docItem = documents[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: DocumentListTile(item: docItem),
                              );
                            },
                            childCount: documents.length,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EditDocumentPage()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Thêm tài liệu',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
