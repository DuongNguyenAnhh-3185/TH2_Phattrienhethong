import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../database/database.dart';
import '../../../../state/document_provider.dart';
import '../../../../utils/app_colors.dart';
import '../../subject/manage_subjects_page.dart';

/// Danh sách chọn nhanh môn học cuộn ngang (Horizontal Chips)
class SubjectHorizontalList extends StatelessWidget {
  final List<Subject> subjects;

  const SubjectHorizontalList({
    super.key,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();
    final selectedSubjectId = docProvider.filter.subjectId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: subjects.length + 2, // 1 for "All", subjects, 1 for "Manage"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedSubjectId == null;
            return FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: const Text('Tất cả môn'),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              selectedColor: AppColors.primary,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              onSelected: (_) => docProvider.setSubjectFilter(null),
            );
          }

          if (index == subjects.length + 1) {
            return ActionChip(
              avatar: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('Quản lý môn'),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageSubjectsPage()),
                );
              },
            );
          }

          final subject = subjects[index - 1];
          final isSelected = selectedSubjectId == subject.id;
          final subjectColor = Color(subject.colorValue);

          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : subjectColor,
                shape: BoxShape.circle,
              ),
            ),
            label: Text('${subject.code} - ${subject.name}'),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            selectedColor: subjectColor,
            side: BorderSide(
              color: isSelected
                  ? subjectColor
                  : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onSelected: (_) => docProvider.setSubjectFilter(subject.id),
          );
        },
      ),
    );
  }
}
