import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../database/database.dart';
import '../../../state/subject_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/confirm_delete_dialog.dart';
import '../../../widgets/custom_text_field.dart';

/// Màn hình Quản lý danh mục Môn học (tương tự Manage Categories trong Cashew)
class ManageSubjectsPage extends StatelessWidget {
  const ManageSubjectsPage({super.key});

  void _showSubjectDialog(BuildContext context, {Subject? subject}) {
    showDialog(
      context: context,
      builder: (_) => _SubjectFormDialog(subject: subject),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = context.watch<SubjectProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Môn học'),
      ),
      body: StreamBuilder<List<Subject>>(
        stream: subjectProvider.subjectsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjects = snapshot.data ?? [];
          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Chưa có môn học nào', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showSubjectDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm môn học'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final subjectColor = Color(subject.colorValue);

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: subjectColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: subjectColor.withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: subjectColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    subject.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    'Mã môn: ${subject.code}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showSubjectDialog(context, subject: subject),
                        splashRadius: 20,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                        onPressed: () async {
                          final confirm = await ConfirmDeleteDialog.show(
                            context: context,
                            title: 'Xóa môn học',
                            message:
                                'Bạn có chắc muốn xóa môn "${subject.name}"? Các tài liệu thuộc môn học này cũng sẽ bị xóa.',
                          );
                          if (confirm && context.mounted) {
                            await subjectProvider.deleteSubject(subject.id);
                          }
                        },
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm môn học'),
      ),
    );
  }
}

class _SubjectFormDialog extends StatefulWidget {
  final Subject? subject;

  const _SubjectFormDialog({this.subject});

  @override
  State<_SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<_SubjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _codeController = TextEditingController(text: widget.subject?.code ?? '');
    _selectedColor = widget.subject?.colorValue ?? AppColors.subjectPresets.first.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SubjectProvider>();
    if (widget.subject != null) {
      await provider.updateSubject(
        id: widget.subject!.id,
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        colorValue: _selectedColor,
      );
    } else {
      await provider.addSubject(
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        colorValue: _selectedColor,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.subject != null ? 'Chỉnh sửa Môn học' : 'Thêm Môn học mới',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Tên môn học',
                hint: 'Ví dụ: Trí tuệ nhân tạo',
                controller: _nameController,
                isRequired: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập tên môn học';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Mã môn học',
                hint: 'Ví dụ: AI302',
                controller: _codeController,
                isRequired: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập mã môn học';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Màu đại diện',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppColors.subjectPresets.map((color) {
                  final isSelected = _selectedColor == color.value;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = color.value),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.subject != null ? 'Cập nhật' : 'Thêm mới'),
        ),
      ],
    );
  }
}
