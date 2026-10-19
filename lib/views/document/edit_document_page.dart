import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../database/database.dart';
import '../../../models/document_type.dart';
import '../../../state/document_provider.dart';
import '../../../state/subject_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/file_helper.dart';
import '../../../widgets/custom_text_field.dart';

/// Màn hình Thêm mới / Chỉnh sửa tài liệu học tập
class EditDocumentPage extends StatefulWidget {
  final int? documentId;

  const EditDocumentPage({
    super.key,
    this.documentId,
  });

  bool get isEditing => documentId != null;

  @override
  State<EditDocumentPage> createState() => _EditDocumentPageState();
}

class _EditDocumentPageState extends State<EditDocumentPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  late TextEditingController _filePathController;

  DocumentType _selectedType = DocumentType.lecture;
  int? _selectedSubjectId;
  String _selectedFormat = 'pdf';
  int _fileSizeBytes = 2500000; // Mặc định giả lập ~2.5MB
  bool _isFavorite = false;
  bool _isLoading = false;

  final List<String> _suggestedTags = [
    '#flutter',
    '#lythuyet',
    '#thuchanh',
    '#onthi',
    '#cuoiky',
    '#giuaky',
    '#slide',
    '#baitaplon',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _tagsController = TextEditingController();
    _filePathController = TextEditingController(text: '/storage/documents/my_document.pdf');

    if (widget.isEditing) {
      _loadDocumentData();
    }
  }

  Future<void> _loadDocumentData() async {
    setState(() => _isLoading = true);
    final docItem = await context.read<DocumentProvider>().getDocumentById(widget.documentId!);
    if (docItem != null) {
      final doc = docItem.document;
      _titleController.text = doc.title;
      _descriptionController.text = doc.description ?? '';
      _tagsController.text = doc.tags;
      _filePathController.text = doc.filePath ?? '';
      _selectedType = doc.documentType;
      _selectedSubjectId = doc.subjectId;
      _selectedFormat = doc.fileFormat;
      _fileSizeBytes = doc.fileSize;
      _isFavorite = doc.isFavorite;
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  void _addSuggestedTag(String tag) {
    final current = _tagsController.text.trim();
    if (current.isEmpty) {
      _tagsController.text = tag;
    } else if (!current.contains(tag)) {
      _tagsController.text = '$current,$tag';
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn môn học cho tài liệu'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final docProvider = context.read<DocumentProvider>();

    try {
      if (widget.isEditing) {
        await docProvider.updateDocument(
          id: widget.documentId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          documentType: _selectedType,
          subjectId: _selectedSubjectId!,
          tags: _tagsController.text.trim(),
          filePath: _filePathController.text.trim(),
          fileFormat: _selectedFormat,
          fileSize: _fileSizeBytes,
          isFavorite: _isFavorite,
        );
      } else {
        await docProvider.addDocument(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          documentType: _selectedType,
          subjectId: _selectedSubjectId!,
          tags: _tagsController.text.trim(),
          filePath: _filePathController.text.trim(),
          fileFormat: _selectedFormat,
          fileSize: _fileSizeBytes,
          isFavorite: _isFavorite,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Đã cập nhật tài liệu thành công!'
                  : 'Đã thêm tài liệu mới vào cơ sở dữ liệu!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu dữ liệu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectProvider>().getAllSubjects();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Chỉnh sửa tài liệu' : 'Thêm tài liệu mới'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isFavorite ? const Color(0xFFFBBF24) : null,
              size: 26,
            ),
            tooltip: 'Đánh dấu yêu thích',
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Tiêu đề tài liệu
                  CustomTextField(
                    label: 'Tên tài liệu',
                    hint: 'Ví dụ: Bài giảng Chương 3: Cơ chế Bất đồng bộ Dart',
                    controller: _titleController,
                    prefixIcon: Icons.title_rounded,
                    isRequired: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập tên tài liệu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // 2. Chọn Môn học
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'Môn học',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          children: const [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      FutureBuilder<List<Subject>>(
                        future: subjects,
                        builder: (context, snapshot) {
                          final list = snapshot.data ?? [];
                          if (_selectedSubjectId == null && list.isNotEmpty) {
                            _selectedSubjectId = list.first.id;
                          }

                          return DropdownButtonFormField<int>(
                            value: _selectedSubjectId,
                            decoration: const InputDecoration(
                              hintText: 'Chọn môn học liên quan',
                              prefixIcon: Icon(Icons.school_rounded, size: 20),
                            ),
                            items: list.map((s) {
                              return DropdownMenuItem<int>(
                                value: s.id,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Color(s.colorValue),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${s.code} - ${s.name}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedSubjectId = val);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 3. Phân loại tài liệu (Lecture, Assignment, Reference, Exam)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Loại tài liệu',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: DocumentType.values.map((type) {
                          final isSelected = _selectedType == type;
                          return ChoiceChip(
                            avatar: Icon(
                              type.icon,
                              size: 16,
                              color: isSelected ? Colors.white : type.color,
                            ),
                            label: Text(type.displayName),
                            selected: isSelected,
                            selectedColor: type.color,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : null,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedType = type);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 4. Mô tả / Ghi chú nội dung
                  CustomTextField(
                    label: 'Mô tả tóm tắt / Ghi chú học tập',
                    hint: 'Nhập tóm tắt các điểm kiến thức cốt lõi, hạn chót bài tập...',
                    controller: _descriptionController,
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 18),

                  // 5. Thẻ tag (#tag) & gợi ý tag
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        label: 'Thẻ tag phân loại',
                        hint: 'Các thẻ cách nhau bằng dấu phẩy (#flutter, #tuan1...)',
                        controller: _tagsController,
                        prefixIcon: Icons.tag_rounded,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _suggestedTags.map((tag) {
                          return ActionChip(
                            label: Text(tag, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onPressed: () => _addSuggestedTag(tag),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 6. Định dạng file & Đường dẫn file
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chọn định dạng
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Định dạng',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedFormat,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: FileHelper.supportedFormats.map((fmt) {
                                return DropdownMenuItem<String>(
                                  value: fmt,
                                  child: Row(
                                    children: [
                                      Icon(
                                        FileHelper.getIconForFormat(fmt),
                                        size: 18,
                                        color: FileHelper.getColorForFormat(fmt),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(fmt.toUpperCase()),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedFormat = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Kích thước tệp giả lập
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kích thước: ${FileHelper.formatFileSize(_fileSizeBytes)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Slider(
                              value: _fileSizeBytes.toDouble(),
                              min: 100000,
                              max: 20000000,
                              divisions: 20,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() => _fileSizeBytes = val.toInt());
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Đường dẫn tệp tin
                  CustomTextField(
                    label: 'Đường dẫn tệp tin (File Path)',
                    hint: 'Đường dẫn tệp tin trong bộ nhớ máy',
                    controller: _filePathController,
                    prefixIcon: Icons.folder_open_rounded,
                  ),
                  const SizedBox(height: 32),

                  // Nút Lưu
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saveDocument,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        widget.isEditing ? 'Cập nhật tài liệu' : 'Lưu vào kho tài liệu',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
