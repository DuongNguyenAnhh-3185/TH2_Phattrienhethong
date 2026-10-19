import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_location_model.dart';

/// Widget cho phép người dùng click lên bản đồ để chọn tọa độ (latitude, longitude)
/// và nhập địa chỉ ghi chú, sau đó lưu thông tin vào bảng `locations` trên Supabase.
class DocumentLocationPicker extends StatefulWidget {
  final String? documentId;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddressNote;
  final ValueChanged<DocumentLocationModel>? onLocationSaved;
  final bool autoSaveToSupabase;

  const DocumentLocationPicker({
    super.key,
    this.documentId,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddressNote,
    this.onLocationSaved,
    this.autoSaveToSupabase = true,
  });

  /// Phương thức tiện ích để mở nhanh màn hình chọn vị trí dưới dạng trang mới
  static Future<DocumentLocationModel?> show(
    BuildContext context, {
    String? documentId,
    double? initialLatitude,
    double? initialLongitude,
    String? initialAddressNote,
    bool autoSaveToSupabase = true,
  }) {
    return Navigator.of(context).push<DocumentLocationModel>(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: const Text('Chọn vị trí vật lý tài liệu'),
            elevation: 1,
          ),
          body: DocumentLocationPicker(
            documentId: documentId,
            initialLatitude: initialLatitude,
            initialLongitude: initialLongitude,
            initialAddressNote: initialAddressNote,
            autoSaveToSupabase: autoSaveToSupabase,
            onLocationSaved: (location) {
              Navigator.of(ctx).pop(location);
            },
          ),
        ),
      ),
    );
  }

  @override
  State<DocumentLocationPicker> createState() => _DocumentLocationPickerState();
}

class _DocumentLocationPickerState extends State<DocumentLocationPicker> {
  late final MapController _mapController;
  late final TextEditingController _addressController;

  // Mặc định khởi tạo tại Hà Nội nếu chưa có tọa độ truyền vào
  static const LatLng _defaultCenter = LatLng(21.028511, 105.854167);

  LatLng? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _addressController =
        TextEditingController(text: widget.initialAddressNote ?? '');

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
    } else {
      _selectedLocation = _defaultCenter;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  /// Xử lý khi người dùng chạm vào một điểm trên bản đồ
  void _onMapTapped(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  /// Di chuyển bản đồ đến điểm chọn
  void _animateToPosition(LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    _mapController.move(point, 15.0);
  }

  /// Lưu vị trí vào Supabase và/hoặc trả về callback
  Future<void> _handleSave() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chạm vào bản đồ để chọn một vị trí.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final note = _addressController.text.trim();
    final locationData = DocumentLocationModel(
      documentId: widget.documentId ?? '',
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      addressNote: note.isNotEmpty ? note : null,
      createdAt: DateTime.now(),
    );

    // Nếu có documentId và bật cờ tự lưu lên Supabase
    if (widget.autoSaveToSupabase &&
        widget.documentId != null &&
        widget.documentId!.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final client = Supabase.instance.client;
        final payload = {
          'document_id': widget.documentId,
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          'address_note': note.isNotEmpty ? note : null,
        };

        // Lưu vào bảng `locations` trên Supabase (Upsert theo document_id nếu có)
        await client.from('locations').upsert(
              payload,
              onConflict: 'document_id',
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã lưu vị trí tài liệu thành công lên hệ thống!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Lỗi khi lưu vị trí vào Supabase: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lưu vào Supabase thất bại: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    widget.onLocationSaved?.call(locationData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final initialPoint = _selectedLocation ?? _defaultCenter;

    return Column(
      children: [
        // Thanh gợi ý chọn nhanh khu vực
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          child: Row(
            children: [
              const Icon(Icons.touch_app_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Chạm vào bản đồ để chọn tọa độ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  _QuickCityChip(
                    label: 'Hà Nội',
                    onTap: () => _animateToPosition(
                      const LatLng(21.028511, 105.854167),
                    ),
                  ),
                  _QuickCityChip(
                    label: 'TP.HCM',
                    onTap: () => _animateToPosition(
                      const LatLng(10.776889, 106.700806),
                    ),
                  ),
                  _QuickCityChip(
                    label: 'Đà Nẵng',
                    onTap: () => _animateToPosition(
                      const LatLng(16.054407, 108.202167),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Khung hiển thị Bản đồ tương tác
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialPoint,
                  initialZoom: 15.0,
                  minZoom: 4.0,
                  maxZoom: 18.0,
                  onTap: _onMapTapped,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.cashew.cashew_study_docs',
                  ),
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          width: 50,
                          height: 50,
                          child: const _SelectedLocationMarker(),
                        ),
                      ],
                    ),
                ],
              ),

              // Các nút điều khiển phóng to / thu nhỏ
              Positioned(
                right: 12,
                bottom: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'picker_zoom_in',
                      backgroundColor:
                          isDark ? const Color(0xFF334155) : Colors.white,
                      foregroundColor: theme.primaryColor,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          currentZoom + 1,
                        );
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'picker_zoom_out',
                      backgroundColor:
                          isDark ? const Color(0xFF334155) : Colors.white,
                      foregroundColor: theme.primaryColor,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          currentZoom - 1,
                        );
                      },
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Khung nhập Địa chỉ / Ghi chú & Nút xác nhận lưu
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, -4),
                blurRadius: 10,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hiển thị tọa độ đã chọn
                if (_selectedLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Text(
                          'Tọa độ: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Ô nhập Địa chỉ / Ghi chú vị trí
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ / Ghi chú vị trí vật lý',
                    hintText: 'Ví dụ: Kệ 3, Tầng 2, Tủ sách Chuyên ngành...',
                    prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Nút Lưu vị trí
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSave,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isLoading
                          ? 'Đang lưu lên Supabase...'
                          : (widget.documentId != null &&
                                  widget.autoSaveToSupabase)
                              ? 'Lưu vị trí vào tài liệu'
                              : 'Xác nhận vị trí này',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Nút bấm nhanh tới các thành phố
class _QuickCityChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickCityChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}

/// Marker tùy biến vị trí được chọn với vòng tròn lan tỏa
class _SelectedLocationMarker extends StatelessWidget {
  const _SelectedLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent.withOpacity(0.25),
            ),
          ),
          const Icon(
            Icons.location_pin,
            size: 40,
            color: Colors.red,
            shadows: [
              Shadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
