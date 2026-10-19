import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../database/database.dart';
import '../../../../models/document_filter.dart';
import '../../../../models/document_type.dart';
import '../../../../state/document_provider.dart';
import '../../../../state/subject_provider.dart';
import '../../../../utils/app_colors.dart';

/// Modal Bottom Sheet phục vụ tìm kiếm nâng cao & lọc đa tiêu chí
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterBottomSheet(),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late DocumentType? _selectedType;
  late int? _selectedSubjectId;
  late bool _isFavoriteOnly;
  late SortOption _selectedSort;
  late TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    final filter = context.read<DocumentProvider>().filter;
    _selectedType = filter.documentType;
    _selectedSubjectId = filter.subjectId;
    _isFavoriteOnly = filter.isFavoriteOnly;
    _selectedSort = filter.sortBy;
    _tagController = TextEditingController(text: filter.tag ?? '');
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final provider = context.read<DocumentProvider>();
    provider.setDocumentTypeFilter(_selectedType);
    if (_selectedSubjectId != null) {
      provider.setSubjectFilter(_selectedSubjectId);
    } else {
      // Clear subject
      provider.setSubjectFilter(null);
    }
    if (provider.filter.isFavoriteOnly != _isFavoriteOnly) {
      provider.toggleFavoriteFilter();
    }
    provider.setTagFilter(_tagController.text.trim().isEmpty ? null : _tagController.text.trim());
    provider.setSortOption(_selectedSort);
    Navigator.of(context).pop();
  }

  void _resetFilter() {
    context.read<DocumentProvider>().resetFilter();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = context.watch<SubjectProvider>().getAllSubjects();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Bộ lọc & Tìm kiếm nâng cao',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _resetFilter,
                  child: const Text('Đặt lại', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
            const Divider(height: 24),

            // 1. Phân loại tài liệu
            const Text(
              'Loại tài liệu',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _selectedType == null,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = null);
                  },
                ),
                ...DocumentType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    avatar: Icon(type.icon, size: 16, color: isSelected ? Colors.white : type.color),
                    label: Text(type.displayName),
                    selected: isSelected,
                    selectedColor: type.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = selected ? type : null;
                      });
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Môn học
            const Text(
              'Môn học',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Subject>>(
              future: subjects,
              builder: (context, snapshot) {
                final list = snapshot.data ?? [];
                return DropdownButtonFormField<int?>(
                  value: _selectedSubjectId,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'Chọn môn học',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả các môn học'),
                    ),
                    ...list.map(
                      (s) => DropdownMenuItem<int?>(
                        value: s.id,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(s.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${s.code} - ${s.name}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedSubjectId = val);
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // 3. Lọc theo Tag
            const Text(
              'Thẻ tag (#tag)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tagController,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: flutter, onthi, chuong1...',
                prefixIcon: Icon(Icons.tag_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Trạng thái yêu thích
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Chỉ tài liệu Yêu thích ⭐',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Lọc ra những tài liệu bạn đã đánh dấu sao',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: _isFavoriteOnly,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _isFavoriteOnly = val),
            ),
            const SizedBox(height: 16),

            // 5. Sắp xếp kết quả
            const Text(
              'Sắp xếp theo',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SortOption.values.map((sort) {
                final isSelected = _selectedSort == sort;
                return ChoiceChip(
                  label: Text(sort.label),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedSort = sort);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Nút Áp dụng
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _applyFilter,
                child: const Text(
                  'Áp dụng bộ lọc',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
