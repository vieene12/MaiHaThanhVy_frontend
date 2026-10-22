import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/teacher_model.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_text_field.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Teacher> _teachers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final keyword = _searchController.text.trim();
    final res = await _apiService.getTeachers(
      keyword: keyword.isEmpty ? null : keyword,
      page: 1,
      pageSize: 50,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _teachers = res.data!.items;
      } else {
        _errorMessage = res.message.isNotEmpty
            ? res.message
            : 'Không thể tải danh sách giảng viên';
      }
    });
  }

  void _showAddEditTeacherDialog([Teacher? teacher]) {
    final isEditing = teacher != null;
    final codeController =
        TextEditingController(text: teacher?.teacherCode ?? '');
    final nameController =
        TextEditingController(text: teacher?.fullName ?? '');
    final emailController =
        TextEditingController(text: teacher?.email ?? '');
    final deptController =
        TextEditingController(text: teacher?.department ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Sửa thông tin giảng viên' : 'Thêm giảng viên mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: codeController,
                label: 'Mã giảng viên (MSGV)',
                hint: 'GV001',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: nameController,
                label: 'Họ và tên',
                hint: 'ThS. Nguyễn Văn B',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: emailController,
                label: 'Email',
                hint: 'teacher@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: deptController,
                label: 'Khoa / Bộ môn',
                hint: 'Khoa Công nghệ thông tin',
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
              if (codeController.text.trim().isEmpty ||
                  nameController.text.trim().isEmpty ||
                  emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng điền đủ MSGV, Họ tên và Email'),
                    backgroundColor: AppTheme.warning,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);

              final newTeacher = Teacher(
                id: teacher?.id ?? 0,
                teacherCode: codeController.text.trim(),
                fullName: nameController.text.trim(),
                email: emailController.text.trim(),
                department: deptController.text.trim(),
              );

              final res = isEditing
                  ? await _apiService.updateTeacher(teacher.id, newTeacher)
                  : await _apiService.createTeacher(newTeacher);

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
                  _loadTeachers();
                }
              }
            },
            child: Text(isEditing ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Teacher teacher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc chắn muốn xóa giảng viên ${teacher.fullName} (${teacher.teacherCode})?'),
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
      final res = await _apiService.deleteTeacher(teacher.id);
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
          _loadTeachers();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Giảng Viên'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm giảng viên'),
        onPressed: () => _showAddEditTeacherDialog(),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, MSGV, email, khoa...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadTeachers();
                  },
                ),
              ),
              onSubmitted: (_) => _loadTeachers(),
            ),
          ),

          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTeachers,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Text(_errorMessage!,
                              style: const TextStyle(color: AppTheme.error)),
                        )
                      : _teachers.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy giảng viên nào.',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _teachers.length,
                              itemBuilder: (context, index) {
                                final t = _teachers[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          const Color(0xFF10B981).withOpacity(0.12),
                                      child: Text(
                                        t.fullName.isNotEmpty
                                            ? t.fullName[0].toUpperCase()
                                            : 'G',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      t.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text('MSGV: ${t.teacherCode} • ${t.email}'),
                                        if (t.department != null &&
                                            t.department!.isNotEmpty)
                                          Text('Khoa: ${t.department}'),
                                        Text('Số lớp phụ trách: ${t.assignedClassesCount}'),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 20, color: AppTheme.primary),
                                          onPressed: () =>
                                              _showAddEditTeacherDialog(t),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: AppTheme.error),
                                          onPressed: () => _confirmDelete(t),
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
