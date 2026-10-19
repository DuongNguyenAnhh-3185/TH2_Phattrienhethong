import 'package:flutter/material.dart';
import '../models/document_type.dart';

/// Huy hiệu hiển thị Loại tài liệu với màu sắc và biểu tượng trực quan
class DocumentTypeBadge extends StatelessWidget {
  final DocumentType type;
  final bool isDense;

  const DocumentTypeBadge({
    super.key,
    required this.type,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = type.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDense ? 8 : 10,
        vertical: isDense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type.icon,
            size: isDense ? 12 : 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            type.displayName,
            style: TextStyle(
              fontSize: isDense ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
