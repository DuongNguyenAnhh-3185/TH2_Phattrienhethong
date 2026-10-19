import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cloud_document_model.dart';
import '../../services/auth_service.dart';
import '../../services/document_storage_service.dart';
import '../../state/cloud_document_provider.dart';
import '../../widgets/rename_document_dialog.dart';
import '../../widgets/share_document_dialog.dart';
import '../borrow/borrow_requests_management_screen.dart';
import '../document/cloud_document_detail_screen.dart';

/// Màn hình Dashboard Quản lý Tài liệu Đám mây (Supabase Storage & Database)
class DocumentDashboardScreen extends StatefulWidget {
  final AuthService? authService;
  final DocumentStorageService? storageService;

  const DocumentDashboardScreen({
    super.key,
    this.authService,
    this.storageService,
  });

  @override
  State<DocumentDashboardScreen> createState() => _DocumentDashboardScreenState();
}

class _DocumentDashboardScreenState extends State<DocumentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  AuthService get _authService =>
      widget.authService ?? context.read<AuthService>();
  DocumentStorageService get _storageService =>
      widget.storageService ?? context.read<DocumentStorageService>();

  User? get _currentUser => _authService.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Tự động tải danh sách tài liệu từ Supabase khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CloudDocumentProvider>().loadDocuments();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ==================== CÁC HÀM XỬ LÝ NGHIỆP VỤ ====================

  /// Xử lý tải tệp mới lên Supabase Storage
  Future<void> _handleUploadDocument() async {
    final provider = context.read<CloudDocumentProvider>();
    try {
      final doc = await provider.pickAndUpload();
      if (doc != null && mounted) {
        _showSnackBar(
          'Tải lên thành công: "${doc.title}"',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  void _navigateToDocumentDetail(CloudDocumentModel doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CloudDocumentDetailScreen(
          document: doc,
          storageService: _storageService,
        ),
      ),
    );
  }

  /// Mở hoặc tải tệp tài liệu
  Future<void> _handleOpenDocument(CloudDocumentModel doc) async {
    final provider = context.read<CloudDocumentProvider>();
    try {
      await provider.openDocument(doc);
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  /// Đổi tên tài liệu (Chỉ áp dụng cho Owner hoặc Editor)
  Future<void> _handleRenameDocument(CloudDocumentModel doc) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => RenameDocumentDialog(
        document: doc,
        storageService: _storageService,
      ),
    );

    if (result == true && mounted) {
      _showSnackBar('Đã đổi tên tài liệu thành công!', isError: false);
      // Làm mới danh sách
      context.read<CloudDocumentProvider>().loadDocuments(silent: true);
    }
  }

  /// Chia sẻ tài liệu (Chỉ Owner mới có quyền)
  Future<void> _handleShareDocument(CloudDocumentModel doc) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ShareDocumentDialog(
        document: doc,
        storageService: _storageService,
      ),
    );

    if (result == true && mounted) {
      _showSnackBar(
        'Đã phân quyền chia sẻ tài liệu thành công!',
        isError: false,
      );
    }
  }

  /// Xóa tài liệu khỏi Supabase Storage và Database
  Future<void> _handleDeleteDocument(CloudDocumentModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa vĩnh viễn tài liệu "${doc.title}" khỏi hệ thống?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<CloudDocumentProvider>().deleteDocument(doc);
        if (mounted) {
          _showSnackBar('Đã xóa tài liệu: ${doc.title}', isError: false);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar(
            e.toString().replaceAll('Exception: ', ''),
            isError: true,
          );
        }
      }
    }
  }

  /// Đăng xuất khỏi tài khoản
  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản Google?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ở lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==================== GIAO DIỆN CHÍNH (BUILD) ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<CloudDocumentProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.folder_shared_rounded,
                color: Color(0xFF2563EB),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cloud DMS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentUser?.displayName ?? _currentUser?.email ?? 'Quản lý tài liệu',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Yêu cầu mượn tài liệu',
            icon: const Icon(Icons.pending_actions_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BorrowRequestsManagementScreen(
                    ownerId: _currentUser?.uid,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.loadDocuments(),
          ),
          IconButton(
            tooltip: 'Đăng xuất tài khoản',
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _handleSignOut,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // 1. Thanh tìm kiếm trên AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: _buildSearchBar(provider, isDark),
              ),

              // 2. TabBar phân tách 2 danh sách rõ ràng:
              // Tab 1: "Tài liệu của tôi"
              // Tab 2: "Được chia sẻ với tôi"
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF2563EB),
                indicatorWeight: 3,
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_rounded, size: 18),
                        const SizedBox(width: 8),
                        const Text('Tài liệu của tôi'),
                        const SizedBox(width: 6),
                        _buildCountBadge(provider.myDocumentsCount, const Color(0xFF2563EB)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.group_rounded, size: 18),
                        const SizedBox(width: 8),
                        const Text('Được chia sẻ với tôi'),
                        const SizedBox(width: 6),
                        _buildCountBadge(provider.sharedDocumentsCount, const Color(0xFF10B981)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Banner tiến trình khi đang Upload tệp lên Supabase Storage
          if (provider.isUploading) _buildUploadBanner(provider, isDark),

          // Nội dung 2 tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Tài liệu của tôi
                _buildDocumentList(
                  documents: provider.myDocuments,
                  isLoading: provider.isLoading,
                  isMyDocsTab: true,
                  provider: provider,
                  isDark: isDark,
                ),

                // Tab 2: Được chia sẻ với tôi
                _buildDocumentList(
                  documents: provider.sharedDocuments,
                  isLoading: provider.isLoading,
                  isMyDocsTab: false,
                  provider: provider,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isUploading ? null : _handleUploadDocument,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.cloud_upload_rounded),
        label: const Text(
          'Tải tệp lên',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ==================== CÁC WIDGET THÀNH PHẦN ====================

  /// Thanh tìm kiếm tài liệu thời gian thực
  Widget _buildSearchBar(CloudDocumentProvider provider, bool isDark) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => provider.setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tài liệu theo tiêu đề...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[500],
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    provider.clearSearchQuery();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  /// Huy hiệu số lượng tài liệu trên Tab
  Widget _buildCountBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Banner hiển thị tiến trình tải tệp lên Supabase Storage
  Widget _buildUploadBanner(CloudDocumentProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF2563EB).withOpacity(0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  provider.uploadStatus,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              Text(
                '${(provider.uploadProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.uploadProgress > 0 ? provider.uploadProgress : null,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  /// Danh sách tài liệu kèm tính năng Pull-to-refresh
  Widget _buildDocumentList({
    required List<CloudDocumentModel> documents,
    required bool isLoading,
    required bool isMyDocsTab,
    required CloudDocumentProvider provider,
    required bool isDark,
  }) {
    if (isLoading && documents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang nạp dữ liệu từ Supabase...'),
          ],
        ),
      );
    }

    if (documents.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.loadDocuments(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: _buildEmptyState(isMyDocsTab, provider.searchQuery, isDark),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadDocuments(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: documents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final doc = documents[index];
          return _buildDocumentCard(doc, isDark);
        },
      ),
    );
  }

  /// Thẻ hiển thị một tệp tài liệu (Document Card)
  Widget _buildDocumentCard(CloudDocumentModel doc, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDocumentDetail(doc),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon loại tài liệu với màu đặc trưng
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: doc.typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      doc.fileIcon,
                      color: doc.typeColor,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Thông tin tệp: Tiêu đề, Dung lượng, Thời gian, Nhãn vai trò
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề tệp
                      Text(
                        doc.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Dung lượng và Ngày tạo
                      Row(
                        children: [
                          Text(
                            doc.formattedFileSize,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                            ),
                          ),
                          Text(
                            doc.formattedCreatedAt,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Nhãn vai trò (Role Badge: Owner, Editor, hoặc Viewer)
                      _buildRoleBadge(doc),
                    ],
                  ),
                ),

                // Menu thao tác trên từng tệp
                _buildActionMenu(doc),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Nhãn vai trò (Role Badge)
  Widget _buildRoleBadge(CloudDocumentModel doc) {
    IconData roleIcon;
    if (doc.isOwner) {
      roleIcon = Icons.shield_rounded;
    } else if (doc.isEditor) {
      roleIcon = Icons.edit_note_rounded;
    } else {
      roleIcon = Icons.visibility_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: doc.roleBadgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(roleIcon, size: 12, color: doc.roleBadgeColor),
          const SizedBox(width: 4),
          Text(
            doc.roleDisplayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: doc.roleBadgeColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Menu thao tác:
  /// - Mở/Tải tệp: Có thể dùng với mọi người
  /// - Đổi tên: Chỉ hiển thị/cho phép nếu là Owner hoặc Editor
  /// - Chia sẻ: Chỉ hiển thị nếu là Owner
  /// - Xóa: Chỉ hiển thị nếu là Owner
  Widget _buildActionMenu(CloudDocumentModel doc) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        switch (value) {
          case 'detail':
            _navigateToDocumentDetail(doc);
            break;
          case 'open':
            _handleOpenDocument(doc);
            break;
          case 'rename':
            _handleRenameDocument(doc);
            break;
          case 'share':
            _handleShareDocument(doc);
            break;
          case 'delete':
            _handleDeleteDocument(doc);
            break;
        }
      },
      itemBuilder: (context) => [
        // 0. Chi tiết & Mượn tài liệu
        const PopupMenuItem<String>(
          value: 'detail',
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: Color(0xFF6366F1)),
              SizedBox(width: 10),
              Text('Chi tiết & Mượn'),
            ],
          ),
        ),

        // 1. Mở / Tải tệp theo URL
        const PopupMenuItem<String>(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.open_in_new_rounded, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text('Mở / Tải tệp'),
            ],
          ),
        ),

        // 2. Đổi tên (nếu là Owner hoặc Editor)
        if (doc.canEdit)
          const PopupMenuItem<String>(
            value: 'rename',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 18, color: Color(0xFFD97706)),
                SizedBox(width: 10),
                Text('Đổi tên'),
              ],
            ),
          ),

        // 3. Nút Chia sẻ (chỉ hiển thị nếu là Owner)
        if (doc.canShare)
          const PopupMenuItem<String>(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share_rounded, size: 18, color: Color(0xFF10B981)),
                SizedBox(width: 10),
                Text('Chia sẻ'),
              ],
            ),
          ),

        // 4. Xóa tài liệu (chỉ hiển thị nếu là Owner)
        if (doc.canDelete)
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                SizedBox(width: 10),
                Text('Xóa tài liệu', style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
      ],
    );
  }

  /// Trạng thái rỗng (Empty State)
  Widget _buildEmptyState(bool isMyDocs, String searchQuery, bool isDark) {
    if (searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy tài liệu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Không có tệp nào khớp với từ khóa "$searchQuery"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMyDocs
                    ? Icons.cloud_upload_outlined
                    : Icons.folder_shared_outlined,
                size: 56,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isMyDocs
                  ? 'Chưa có tài liệu cá nhân'
                  : 'Chưa có tài liệu được chia sẻ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isMyDocs
                  ? 'Bấm vào nút "Tải tệp lên" ở góc dưới để lưu trữ tài liệu đầu tiên lên Supabase Storage.'
                  : 'Khi thành viên khác chia sẻ tài liệu với vai trò Viewer hoặc Editor, tài liệu sẽ hiển thị ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
