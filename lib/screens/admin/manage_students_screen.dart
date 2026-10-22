import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/student_model.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_text_field.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Student> _students = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final keyword = _searchController.text.trim();
    final res = await _apiService.getStudents(
      keyword: keyword.isEmpty ? null : keyword,
      page: 1,
      pageSize: 50,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _students = res.data!.items;
      } else {
        _errorMessage = res.message.isNotEmpty
            ? res.message
            : 'Không thể tải danh sách sinh viên';
      }
    });
  }

  void _showAddEditStudentDialog([Student? student]) {
    final isEditing = student != null;
    final codeController =
        TextEditingController(text: student?.studentCode ?? '');
    final nameController =
        TextEditingController(text: student?.fullName ?? '');
    final emailController =
        TextEditingController(text: student?.email ?? '');
    final phoneController =
        TextEditingController(text: student?.phoneNumber ?? '');
    final majorController =
        TextEditingController(text: student?.major ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Sửa thông tin sinh viên' : 'Thêm sinh viên mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: codeController,
                label: 'Mã số sinh viên (MSSV)',
                hint: 'SV00001',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: nameController,
                label: 'Họ và tên',
                hint: 'Nguyễn Văn A',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: emailController,
                label: 'Email',
                hint: 'student@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: phoneController,
                label: 'Số điện thoại',
                hint: '0912345678',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: majorController,
                label: 'Chuyên ngành',
                hint: 'Công nghệ thông tin',
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
                    content: Text('Vui lòng điền đủ MSSV, Họ tên và Email'),
                    backgroundColor: AppTheme.warning,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);

              final newStudent = Student(
                id: student?.id ?? 0,
                studentCode: codeController.text.trim(),
                fullName: nameController.text.trim(),
                email: emailController.text.trim(),
                phoneNumber: phoneController.text.trim(),
                major: majorController.text.trim(),
              );

              final res = isEditing
                  ? await _apiService.updateStudent(student.id, newStudent)
                  : await _apiService.createStudent(newStudent);

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
                  _loadStudents();
                }
              }
            },
            child: Text(isEditing ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc chắn muốn xóa sinh viên ${student.fullName} (${student.studentCode})?'),
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
      final res = await _apiService.deleteStudent(student.id);
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
          _loadStudents();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Sinh Viên'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm sinh viên'),
        onPressed: () => _showAddEditStudentDialog(),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, MSSV, email, chuyên ngành...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadStudents();
                  },
                ),
              ),
              onSubmitted: (_) => _loadStudents(),
            ),
          ),

          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadStudents,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Text(_errorMessage!,
                              style: const TextStyle(color: AppTheme.error)),
                        )
                      : _students.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy sinh viên nào.',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final s = _students[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          AppTheme.primary.withOpacity(0.12),
                                      child: Text(
                                        s.fullName.isNotEmpty
                                            ? s.fullName[0].toUpperCase()
                                            : 'S',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      s.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text('MSSV: ${s.studentCode} • ${s.email}'),
                                        if (s.major != null &&
                                            s.major!.isNotEmpty)
                                          Text('Ngành: ${s.major}'),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 20, color: AppTheme.primary),
                                          onPressed: () =>
                                              _showAddEditStudentDialog(s),
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
