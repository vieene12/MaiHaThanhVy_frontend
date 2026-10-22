import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/subject_model.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_text_field.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Subject> _subjects = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final keyword = _searchController.text.trim();
    final res = await _apiService.getSubjects(
      keyword: keyword.isEmpty ? null : keyword,
      page: 1,
      pageSize: 50,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _subjects = res.data!.items;
      } else {
        _errorMessage = res.message.isNotEmpty
            ? res.message
            : 'Không thể tải danh sách môn học';
      }
    });
  }

  void _showAddEditSubjectDialog([Subject? subject]) {
    final isEditing = subject != null;
    final codeController =
        TextEditingController(text: subject?.subjectCode ?? '');
    final nameController =
        TextEditingController(text: subject?.subjectName ?? '');
    final creditsController =
        TextEditingController(text: (subject?.credits ?? 3).toString());
    final descController =
        TextEditingController(text: subject?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Sửa môn học' : 'Thêm môn học mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: codeController,
                label: 'Mã môn học',
                hint: 'CS101',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: nameController,
                label: 'Tên môn học',
                hint: 'Lập trình di động',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: creditsController,
                label: 'Số tín chỉ',
                hint: '3',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: descController,
                label: 'Mô tả',
                hint: 'Môn học lý thuyết và thực hành...',
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final credits = int.tryParse(creditsController.text.trim()) ?? 3;
              if (codeController.text.trim().isEmpty ||
                  nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng điền đủ Mã môn học và Tên môn học'),
                    backgroundColor: AppTheme.warning,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);

              final newSubject = Subject(
                id: subject?.id ?? 0,
                subjectCode: codeController.text.trim(),
                subjectName: nameController.text.trim(),
                credits: credits,
                description: descController.text.trim(),
              );

              final res = isEditing
                  ? await _apiService.updateSubject(subject.id, newSubject)
                  : await _apiService.createSubject(newSubject);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.message.isNotEmpty
                        ? res.message
                        : (isEditing ? 'Cập nhật thành công' : 'Thêm thành công')),
                    backgroundColor:
                        res.success ? AppTheme.success : AppTheme.error,
                  ),
                );
                if (res.success) {
                  _loadSubjects();
                }
              }
            },
            child: Text(isEditing ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc chắn muốn xóa môn học ${subject.subjectName} (${subject.subjectCode})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await _apiService.deleteSubject(subject.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty
                ? res.message
                : (res.success ? 'Đã xóa thành công' : 'Xóa thất bại')),
            backgroundColor: res.success ? AppTheme.success : AppTheme.error,
          ),
        );
        if (res.success) {
          _loadSubjects();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Môn Học'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm môn học'),
        onPressed: () => _showAddEditSubjectDialog(),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc mã môn học...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadSubjects();
                  },
                ),
              ),
              onSubmitted: (_) => _loadSubjects(),
            ),
          ),

          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSubjects,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Text(_errorMessage!,
                              style: const TextStyle(color: AppTheme.error)),
                        )
                      : _subjects.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy môn học nào.',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _subjects.length,
                              itemBuilder: (context, index) {
                                final s = _subjects[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          const Color(0xFF8B5CF6).withOpacity(0.12),
                                      child: Text(
                                        '${s.credits}TC',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF8B5CF6),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      s.subjectName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text('Mã môn: ${s.subjectCode} • ${s.credits} tín chỉ'),
                                        if (s.description != null &&
                                            s.description!.isNotEmpty)
                                          Text(
                                            s.description!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        Text('Số lớp mở: ${s.totalClassesCount}'),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 20, color: AppTheme.primary),
                                          onPressed: () =>
                                              _showAddEditSubjectDialog(s),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: AppTheme.error),
                                          onPressed: () => _confirmDelete(s),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
