import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/borrow_request_model.dart';
import '../../models/cloud_document_model.dart';
import '../../models/document_location_model.dart';
import '../../services/borrow_service.dart';
import '../../services/document_storage_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/document_location_picker.dart';
import '../../widgets/document_location_viewer.dart';

/// Màn hình Chi tiết Tài liệu Đám mây (Supabase)
/// Tích hợp đầy đủ luồng Mượn tài liệu, Kiểm tra quyền truy cập và Vị trí vật lý
class CloudDocumentDetailScreen extends StatefulWidget {
  final CloudDocumentModel document;
  final DocumentStorageService? storageService;
  final BorrowService? borrowService;

  const CloudDocumentDetailScreen({
    super.key,
    required this.document,
    this.storageService,
    this.borrowService,
  });

  @override
  State<CloudDocumentDetailScreen> createState() =>
      _CloudDocumentDetailScreenState();
}

class _CloudDocumentDetailScreenState extends State<CloudDocumentDetailScreen> {
  late final BorrowService _borrowService;
  late final DocumentStorageService _storageService;

  bool _isLoadingAccess = true;
  bool _canAccess = false;
  BorrowRequestModel? _currentBorrowRequest;
  DocumentLocationModel? _documentLocation;

  bool _isSendingRequest = false;

  String? get _currentUserId => _borrowService.currentUserId;
  bool get _isOwner =>
      widget.document.ownerId.isNotEmpty &&
      widget.document.ownerId == _currentUserId;

  @override
  void initState() {
    super.initState();
    _borrowService = widget.borrowService ?? BorrowService();
    _storageService = widget.storageService ?? DocumentStorageService();
    _checkAccessAndLoadData();
  }

  /// Kiểm tra quyền truy cập và tải vị trí vật lý của tài liệu từ Supabase
  Future<void> _checkAccessAndLoadData() async {
    setState(() {
      _isLoadingAccess = true;
    });

    final doc = widget.document;
    final uid = _currentUserId;

    // 1. Tải vị trí vật lý (nếu có)
    final location = await _storageService.getDocumentLocation(doc.id);

    // 2. Kiểm tra quyền truy cập
    if (_isOwner || (uid != null && uid == doc.ownerId)) {
      if (mounted) {
        setState(() {
          _canAccess = true;
          _documentLocation = location;
          _isLoadingAccess = false;
        });
      }
      return;
    }

    if (uid != null) {
      final request = await _borrowService.checkUserBorrowRequest(
        documentId: doc.id,
        userId: uid,
      );

      final hasApprovedAccess = request?.isApproved == true;

      if (mounted) {
        setState(() {
          _canAccess = hasApprovedAccess;
          _currentBorrowRequest = request;
          _documentLocation = location;
          _isLoadingAccess = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _canAccess = false;
          _documentLocation = location;
          _isLoadingAccess = false;
        });
      }
    }
  }

  /// Xử lý gửi yêu cầu mượn tài liệu mới vào bảng `borrow_requests` (status = 'pending')
  Future<void> _handleSendBorrowRequest() async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để gửi yêu cầu mượn tài liệu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSendingRequest = true;
    });

    try {
      final newRequest = await _borrowService.sendBorrowRequest(
        documentId: widget.document.id,
        ownerId: widget.document.ownerId,
        requesterId: uid,
      );

      if (mounted) {
        setState(() {
          _currentBorrowRequest = newRequest;
          _canAccess = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đã gửi yêu cầu mượn thành công! Vui lòng đợi chủ sở hữu phê duyệt.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingRequest = false;
        });
      }
    }
  }

  /// Mở liên kết nội dung số `file_url`
  Future<void> _handleOpenFileUrl() async {
    final url = widget.document.fileUrl;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liên kết tệp tin không tồn tại.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Không thể khởi chạy trình mở tệp.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở tệp tin: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Cập nhật vị trí bản đồ cho tài liệu
  Future<void> _handlePickLocation() async {
    final picked = await DocumentLocationPicker.show(
      context,
      documentId: widget.document.id,
      initialLatitude: _documentLocation?.latitude,
      initialLongitude: _documentLocation?.longitude,
      initialAddressNote: _documentLocation?.addressNote,
      autoSaveToSupabase: true,
    );

    if (picked != null && mounted) {
      setState(() {
        _documentLocation = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final doc = widget.document;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tài liệu đám mây'),
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Làm mới trạng thái',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _checkAccessAndLoadData,
          ),
        ],
      ),
      body: _isLoadingAccess
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                // 1. Thẻ thông tin tài liệu chính
                _buildHeroCard(doc, isDark, theme),
                const SizedBox(height: 20),

                // 2. Khu vực Kiểm tra Quyền truy cập & Yêu cầu mượn
                _buildAccessControlSection(isDark, theme),
                const SizedBox(height: 24),

                // 3. Vị trí vật lý (Sử dụng DocumentLocationViewer)
                _buildLocationSection(isDark, theme),
                const SizedBox(height: 24),

                // 4. Thông tin tệp chi tiết
                _buildMetadataCard(doc, isDark, theme),
                const SizedBox(height: 32),

                // 5. Nút xem / tải nội dung số (Logic kiểm tra quyền truy cập)
                _buildAccessActionButton(theme),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildHeroCard(
      CloudDocumentModel doc, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: doc.typeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                doc.fileIcon,
                color: doc.typeColor,
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  doc.fileType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: doc.roleBadgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isOwner ? 'Chủ sở hữu' : 'Người xem',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: doc.roleBadgeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Khu vực hiển thị Trạng thái Quyền truy cập
  Widget _buildAccessControlSection(bool isDark, ThemeData theme) {
    if (_isOwner) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Colors.blue, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bạn là Chủ sở hữu của tài liệu này (Toàn quyền truy cập nội dung số và vị trí).',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    if (_canAccess) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Yêu cầu mượn của bạn đã được PHÊ DUYỆT! Bạn có thể xem và tải nội dung số bên dưới.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_currentBorrowRequest?.isPending == true) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_top_rounded,
                color: Colors.orange[800], size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Yêu cầu mượn của bạn đang CHỜ DUYỆT. Vui lòng đợi chủ sở hữu phản hồi.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[900],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_currentBorrowRequest?.isRejected == true) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yêu cầu mượn trước đó đã bị TỪ CHỐI.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: _isSendingRequest ? null : _handleSendBorrowRequest,
                    child: const Text(
                      'Bấm vào đây để gửi lại yêu cầu',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Chưa từng gửi yêu cầu
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_clock_rounded,
                  color: Color(0xFFD97706), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tài liệu này yêu cầu quyền mượn từ chủ sở hữu để truy cập nội dung số.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. NÚT GỬI YÊU CẦU MƯỢN (Requirement 1)
          ElevatedButton.icon(
            onPressed: _isSendingRequest ? null : _handleSendBorrowRequest,
            icon: _isSendingRequest
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              _isSendingRequest
                  ? 'Đang gửi yêu cầu...'
                  : 'Gửi yêu cầu mượn tài liệu',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Khu vực Vị trí vật lý của tài liệu
  Widget _buildLocationSection(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Vị trí vật lý',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_isOwner)
              TextButton.icon(
                onPressed: _handlePickLocation,
                icon: const Icon(Icons.edit_location_rounded, size: 16),
                label: Text(_documentLocation == null ? 'Ghim vị trí' : 'Sửa vị trí'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_documentLocation != null)
          DocumentLocationViewer(
            latitude: _documentLocation!.latitude,
            longitude: _documentLocation!.longitude,
            addressNote: _documentLocation!.addressNote,
            height: 190,
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_off_outlined,
                    color: Colors.grey, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chưa có thông tin vị trí vật lý cho tài liệu này.',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Thẻ thông tin kỹ thuật
  Widget _buildMetadataCard(
      CloudDocumentModel doc, bool isDark, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          _MetaRow(
            icon: Icons.data_usage_rounded,
            label: 'Dung lượng tệp',
            value: doc.formattedFileSize,
          ),
          const Divider(height: 1),
          _MetaRow(
            icon: Icons.calendar_today_rounded,
            label: 'Ngày tải lên',
            value: DateFormatter.formatDateTime(doc.createdAt),
          ),
          const Divider(height: 1),
          _MetaRow(
            icon: Icons.person_outline_rounded,
            label: 'Chủ sở hữu',
            value: doc.ownerDisplayName ?? doc.ownerEmail ?? doc.ownerId,
          ),
        ],
      ),
    );
  }

  /// Nút Xem / Tải nội dung số (Logic kiểm tra quyền truy cập - Requirement 3)
  Widget _buildAccessActionButton(ThemeData theme) {
    // 3. Logic kiểm tra quyền truy cập: Nếu user là owner HOẶC có một request đã 'approved'
    if (_canAccess) {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _handleOpenFileUrl,
          icon: const Icon(Icons.file_open_rounded, size: 22),
          label: const Text(
            'Mở / Tải nội dung số (file_url)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    // Nếu không có quyền truy cập, hiển thị nút bị khóa kèm thông báo
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_rounded, size: 20, color: Colors.grey),
          SizedBox(width: 10),
          Text(
            'Nội dung số đã bị khóa (Cần được duyệt mượn)',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
