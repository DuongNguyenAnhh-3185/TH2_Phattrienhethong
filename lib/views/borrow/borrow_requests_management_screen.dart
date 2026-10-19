import 'package:flutter/material.dart';
import '../../models/borrow_request_model.dart';
import '../../services/borrow_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state_view.dart';

/// Màn hình Quản lý Yêu cầu Mượn tài liệu (Dành cho Chủ sở hữu tài liệu)
/// Sử dụng Supabase Realtime Stream để cập nhật các yêu cầu mượn tự động
class BorrowRequestsManagementScreen extends StatefulWidget {
  final String? ownerId;
  final BorrowService? borrowService;

  const BorrowRequestsManagementScreen({
    super.key,
    this.ownerId,
    this.borrowService,
  });

  @override
  State<BorrowRequestsManagementScreen> createState() =>
      _BorrowRequestsManagementScreenState();
}

class _BorrowRequestsManagementScreenState
    extends State<BorrowRequestsManagementScreen>
    with SingleTickerProviderStateMixin {
  late final BorrowService _borrowService;
  late final TabController _tabController;

  String? get _currentOwnerId =>
      widget.ownerId ?? _borrowService.currentUserId;

  // Cache thông tin tiêu đề tài liệu để hiển thị đẹp mắt
  final Map<String, String> _docTitles = {};

  @override
  void initState() {
    super.initState();
    _borrowService = widget.borrowService ?? BorrowService();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Lấy tiêu đề tài liệu (nếu chưa có trong cache thì fetch từ Supabase)
  Future<String> _getOrFetchDocumentTitle(String docId) async {
    if (_docTitles.containsKey(docId)) {
      return _docTitles[docId]!;
    }
    final info = await _borrowService.getDocumentInfo(docId);
    final title = info?['title']?.toString() ?? 'Tài liệu #$docId';
    _docTitles[docId] = title;
    return title;
  }

  /// Xử lý duyệt hoặc từ chối yêu cầu mượn
  Future<void> _handleProcessRequest(
      BorrowRequestModel req, String newStatus) async {
    final isApprove = newStatus == 'approved';
    final actionText = isApprove ? 'chấp nhận' : 'từ chối';

    try {
      await _borrowService.updateRequestStatus(
        requestId: req.id,
        newStatus: newStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isApprove
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text('Đã $actionText yêu cầu mượn thành công!'),
              ],
            ),
            backgroundColor: isApprove ? Colors.green : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi $actionText: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ownerId = _currentOwnerId;

    if (ownerId == null || ownerId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý yêu cầu mượn')),
        body: const Center(
          child: Text('Vui lòng đăng nhập để xem danh sách yêu cầu mượn.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý yêu cầu mượn'),
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.pending_actions_rounded),
              text: 'Chờ duyệt',
            ),
            Tab(
              icon: Icon(Icons.history_rounded),
              text: 'Lịch sử đã xử lý',
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<BorrowRequestModel>>(
        // Lắng nghe Supabase Realtime Stream
        stream: _borrowService.streamReceivedRequests(ownerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      'Lỗi kết nối Realtime Supabase:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            );
          }

          final allRequests = snapshot.data ?? [];
          final pendingRequests =
              allRequests.where((r) => r.isPending).toList();
          final historyRequests =
              allRequests.where((r) => !r.isPending).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Đang chờ duyệt
              _buildRequestsList(
                requests: pendingRequests,
                isPendingTab: true,
                isDark: isDark,
              ),

              // Tab 2: Lịch sử đã xử lý
              _buildRequestsList(
                requests: historyRequests,
                isPendingTab: false,
                isDark: isDark,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestsList({
    required List<BorrowRequestModel> requests,
    required bool isPendingTab,
    required bool isDark,
  }) {
    if (requests.isEmpty) {
      return Center(
        child: EmptyStateView(
          icon: isPendingTab
              ? Icons.mark_email_read_outlined
              : Icons.history_toggle_off_rounded,
          title: isPendingTab
              ? 'Không có yêu cầu nào chờ duyệt'
              : 'Chưa có lịch sử yêu cầu',
          description: isPendingTab
              ? 'Khi có người dùng gửi yêu cầu mượn tài liệu của bạn, thông báo sẽ hiển thị tại đây thời gian thực.'
              : 'Các yêu cầu sau khi được chấp nhận hoặc từ chối sẽ lưu ở đây.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = requests[index];
        return _buildRequestCard(req, isPendingTab, isDark);
      },
    );
  }

  Widget _buildRequestCard(
      BorrowRequestModel req, bool isPendingTab, bool isDark) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon tài liệu + Tên tài liệu + Badge trạng thái
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _getOrFetchDocumentTitle(req.documentId),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Đang tải thông tin...',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mã tài liệu: ${req.documentId}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(req.status),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Thông tin người mượn và thời gian gửi
          Row(
            children: [
              const Icon(Icons.person_pin_circle_outlined,
                  size: 16, color: Colors.blueGrey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Người mượn: ${req.requesterEmail ?? req.requesterName ?? req.requesterId}',
                  style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 16, color: Colors.blueGrey),
              const SizedBox(width: 6),
              Text(
                'Thời gian: ${DateFormatter.formatRelative(req.createdAt)} (${DateFormatter.formatDateTime(req.createdAt)})',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ],
          ),

          // Hai nút hành động: "Chấp nhận" & "Từ chối" (Chỉ hiện khi trạng thái là pending)
          if (isPendingTab) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                // Nút Từ chối (UPDATE status = 'rejected')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleProcessRequest(req, 'rejected'),
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Colors.redAccent),
                    label: const Text(
                      'Từ chối',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Nút Chấp nhận (UPDATE status = 'approved')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleProcessRequest(req, 'approved'),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'Chấp nhận',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case 'approved':
        bg = Colors.green.withOpacity(0.12);
        text = Colors.green;
        label = 'Đã duyệt';
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        bg = Colors.red.withOpacity(0.12);
        text = Colors.redAccent;
        label = 'Từ chối';
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = Colors.amber.withOpacity(0.14);
        text = Colors.orange[800]!;
        label = 'Chờ duyệt';
        icon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
