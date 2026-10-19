import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget hiển thị bản đồ thu nhỏ kèm Marker ghim vị trí vật lý của tài liệu
class DocumentLocationViewer extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? addressNote;
  final double height;
  final bool showOpenExternalButton;

  const DocumentLocationViewer({
    super.key,
    required this.latitude,
    required this.longitude,
    this.addressNote,
    this.height = 200.0,
    this.showOpenExternalButton = true,
  });

  @override
  State<DocumentLocationViewer> createState() => _DocumentLocationViewerState();
}

class _DocumentLocationViewerState extends State<DocumentLocationViewer> {
  late final MapController _mapController;

  LatLng get _location => LatLng(widget.latitude, widget.longitude);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant DocumentLocationViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _mapController.move(_location, 15.0);
    }
  }

  Future<void> _openExternalMap() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Không thể mở ứng dụng bản đồ: $e');
    }
  }

  void _recenterMap() {
    _mapController.move(_location, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phần hiển thị Bản đồ
          SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _location,
                    initialZoom: 15.0,
                    minZoom: 4.0,
                    maxZoom: 18.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    // Lớp bản đồ OpenStreetMap
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.cashew.cashew_study_docs',
                    ),
                    // Marker ghim vị trí
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _location,
                          width: 46,
                          height: 46,
                          child: const _LocationPinMarker(),
                        ),
                      ],
                    ),
                  ],
                ),

                // Nút Căn giữa (Recenter)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: isDark ? const Color(0xFF334155) : Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: IconButton(
                      icon: const Icon(Icons.my_location, size: 20),
                      color: theme.primaryColor,
                      tooltip: 'Đưa về tâm ghim',
                      onPressed: _recenterMap,
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Phần chi tiết địa chỉ & tọa độ bên dưới bản đồ
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.place_rounded,
                    color: theme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (widget.addressNote != null &&
                                widget.addressNote!.trim().isNotEmpty)
                            ? widget.addressNote!
                            : 'Vị trí vật lý của tài liệu',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tọa độ: ${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showOpenExternalButton) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openExternalMap,
                    icon: const Icon(Icons.directions_outlined, size: 16),
                    label: const Text('Chỉ đường'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Marker tùy biến với hiệu ứng đổ bóng và viền trắng nổi bật
class _LocationPinMarker extends StatelessWidget {
  const _LocationPinMarker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vòng tròn định vị mờ phía sau
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent.withOpacity(0.2),
            ),
          ),
          // Ghim đỏ chính
          const Icon(
            Icons.location_pin,
            size: 38,
            color: Color(0xFFEF4444),
            shadows: [
              Shadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
