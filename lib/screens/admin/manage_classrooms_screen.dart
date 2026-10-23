import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/classroom_model.dart';
import '../../models/subject_model.dart';
import '../../models/teacher_model.dart';
import '../../models/student_model.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_text_field.dart';

class ManageClassroomsScreen extends StatefulWidget {
  const ManageClassroomsScreen({super.key});

  @override
  State<ManageClassroomsScreen> createState() => _ManageClassroomsScreenState();
}

class _ManageClassroomsScreenState extends State<ManageClassroomsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<ClassRoom> _classrooms = [];
  List<Subject> _subjects = [];
  List<Teacher> _teachers = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final keyword = _searchController.text.trim();
    final resClasses = await _apiService.getClassRooms(
      keyword: keyword.isEmpty ? null : keyword,
      page: 1,
      pageSize: 50,
    );

    final resSubjects = await _apiService.getSubjects(page: 1, pageSize: 100);
    final resTeachers = await _apiService.getTeachers(page: 1, pageSize: 100);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (resClasses.success && resClasses.data != null) {
        _classrooms = resClasses.data!.items;
      } else {
        _errorMessage = resClasses.message.isNotEmpty
            ? resClasses.message
            : 'Không thể tải danh sách lớp học';
      }

      if (resSubjects.success && resSubjects.data != null) {
        _subjects = resSubjects.data!.items;
      }
      if (resTeachers.success && resTeachers.data != null) {
        _teachers = resTeachers.data!.items;
      }
    });
  }

  void _showAddEditClassroomDialog([ClassRoom? classroom]) {
    final isEditing = classroom != null;
    final nameController =
        TextEditingController(text: classroom?.className ?? '');
    final roomController =
        TextEditingController(text: classroom?.room ?? '');
    final semesterController =
        TextEditingController(text: classroom?.semester ?? 'HK1-2025-2026');
    final scheduleController =
        TextEditingController(text: classroom?.schedule ?? 'Thứ 2 (Tiết 1-4)');
    final maxStudentsController =
        TextEditingController(text: (classroom?.maxStudents ?? 50).toString());

    int? selectedSubjectId = classroom?.subjectId ??
        (_subjects.isNotEmpty ? _subjects.first.id : null);
    int? selectedTeacherId = classroom?.teacherId ??
        (_teachers.isNotEmpty ? _teachers.first.id : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Sửa thông tin lớp học' : 'Tạo lớp học mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Tên lớp học',
                  hint: '21DTH01 - LT Di Động',
                ),
                const SizedBox(height: 12),

                // Subject Dropdown
                const Text(
                  'Môn học',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: selectedSubjectId,
                  isExpanded: true,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.all(12)),
                  items: _subjects
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.subjectCode} - ${s.subjectName}'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedSubjectId = val);
                  },
                ),
                const SizedBox(height: 12),

                // Teacher Dropdown
                const Text(
                  'Giảng viên phụ trách',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: selectedTeacherId,
                  isExpanded: true,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.all(12)),
                  items: _teachers
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text('${t.teacherCode} - ${t.fullName}'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedTeacherId = val);
                  },
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: roomController,
                  label: 'Phòng học',
                  hint: 'A-08.12',
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: semesterController,
                  label: 'Học kỳ',
                  hint: 'HK1 2025-2026',
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: scheduleController,
                  label: 'Lịch học',
                  hint: 'Thứ 4, Tiết 1-4 (07:30 - 11:00)',
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: maxStudentsController,
                  label: 'Sĩ số tối đa',
                  hint: '50',
                  keyboardType: TextInputType.number,
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
                if (nameController.text.trim().isEmpty ||
                    selectedSubjectId == null ||
                    selectedTeacherId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng điền đủ Tên lớp, Môn học và Giảng viên'),
                      backgroundColor: AppTheme.warning,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);

                final newClass = ClassRoom(
                  id: classroom?.id ?? 0,
                  className: nameController.text.trim(),
                  subjectId: selectedSubjectId!,
                  teacherId: selectedTeacherId!,
                  room: roomController.text.trim(),
                  semester: semesterController.text.trim(),
                  schedule: scheduleController.text.trim(),
                  maxStudents:
                      int.tryParse(maxStudentsController.text.trim()) ?? 50,
                );

                final res = isEditing
                    ? await _apiService.updateClassRoom(classroom.id, newClass)
                    : await _apiService.createClassRoom(newClass);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.message.isNotEmpty
                          ? res.message
                          : (isEditing ? 'Cập nhật thành công' : 'Tạo lớp thành công')),
                      backgroundColor:
                          res.success ? AppTheme.success : AppTheme.error,
                    ),
                  );
                  if (res.success) {
                    _loadData();
                  }
                }
              },
              child: Text(isEditing ? 'Lưu' : 'Tạo lớp'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClassDetails(ClassRoom classroom) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ClassEnrollmentSheet(
        classRoom: classroom,
        onRefreshNeeded: _loadData,
      ),
    );
  }

  void _confirmDelete(ClassRoom classroom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa lớp học'),
        content: Text('Bạn có chắc muốn xóa lớp ${classroom.className}?'),
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
      final res = await _apiService.deleteClassRoom(classroom.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty
                ? res.message
                : (res.success ? 'Đã xóa lớp thành công' : 'Xóa thất bại')),
            backgroundColor: res.success ? AppTheme.success : AppTheme.error,
          ),
        );
        if (res.success) {
          _loadData();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Lớp Học'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tạo lớp học'),
        onPressed: () => _showAddEditClassroomDialog(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên lớp, phòng, môn học...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadData();
                  },
                ),
              ),
              onSubmitted: (_) => _loadData(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Text(_errorMessage!,
                              style: const TextStyle(color: AppTheme.error)),
                        )
                      : _classrooms.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy lớp học nào.',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _classrooms.length,
                              itemBuilder: (context, index) {
                                final c = _classrooms[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _showClassDetails(c),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  c.className,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEFF6FF),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${c.enrolledStudentsCount}/${c.maxStudents} SV',
                                                  style: const TextStyle(
                                                    color: AppTheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.menu_book,
                                                  size: 16,
                                                  color: Color(0xFF64748B)),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${c.subjectCode} - ${c.subjectName}',
                                                style: const TextStyle(
                                                    color: Color(0xFF334155),
                                                    fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.person_pin,
                                                  size: 16,
                                                  color: Color(0xFF64748B)),
                                              const SizedBox(width: 6),
                                              Text(
                                                'GV: ${c.teacherName}',
                                                style: const TextStyle(
                                                    color: Color(0xFF334155),
                                                    fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          if (c.room != null &&
                                              c.room!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons.meeting_room_outlined,
                                                    size: 16,
                                                    color: Color(0xFF64748B)),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Phòng: ${c.room} • ${c.schedule ?? ""}',
                                                  style: const TextStyle(
                                                      color: Color(0xFF64748B),
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                          const Divider(height: 20),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                icon: const Icon(
                                                    Icons.group_outlined,
                                                    size: 18),
                                                label:
                                                    const Text('Danh sách SV'),
                                                onPressed: () =>
                                                    _showClassDetails(c),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 18,
                                                    color: AppTheme.primary),
                                                onPressed: () =>
                                                    _showAddEditClassroomDialog(
                                                        c),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18,
                                                    color: AppTheme.error),
                                                onPressed: () =>
                                                    _confirmDelete(c),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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

class _ClassEnrollmentSheet extends StatefulWidget {
  final ClassRoom classRoom;
  final VoidCallback onRefreshNeeded;

  const _ClassEnrollmentSheet({
    required this.classRoom,
    required this.onRefreshNeeded,
  });

  @override
  State<_ClassEnrollmentSheet> createState() => _ClassEnrollmentSheetState();
}

class _ClassEnrollmentSheetState extends State<_ClassEnrollmentSheet> {
  final ApiService _apiService = ApiService();
  List<Student> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClassStudents();
  }

  Future<void> _loadClassStudents() async {
    setState(() => _isLoading = true);
    final res = await _apiService.getStudentsByClass(widget.classRoom.id);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _students = res.data!;
      }
    });
  }

  void _showEnrollDialog() async {
    final allStudentsRes = await _apiService.getStudents(page: 1, pageSize: 100);
    if (!mounted) return;

    if (!allStudentsRes.success || allStudentsRes.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải danh sách sinh viên'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final enrolledIds = _students.map((s) => s.id).toSet();
    final availableStudents = allStudentsRes.data!.items
        .where((s) => !enrolledIds.contains(s.id))
        .toList();

    if (availableStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tất cả sinh viên đã có trong lớp học này'),
          backgroundColor: AppTheme.info,
        ),
      );
      return;
    }

    int? selectedStudentId = availableStudents.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Ghi danh sinh viên vào lớp'),
          content: DropdownButtonFormField<int>(
            value: selectedStudentId,
            isExpanded: true,
            items: availableStudents
                .map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.studentCode} - ${s.fullName}'),
                    ))
                .toList(),
            onChanged: (val) {
              setDialogState(() => selectedStudentId = val);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedStudentId == null) return;
                Navigator.pop(ctx);
                final res = await _apiService.enrollStudent(
                    widget.classRoom.id, selectedStudentId!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.message.isNotEmpty
                          ? res.message
                          : (res.success
                              ? 'Ghi danh thành công'
                              : 'Ghi danh thất bại')),
                      backgroundColor:
                          res.success ? AppTheme.success : AppTheme.error,
                    ),
                  );
                  if (res.success) {
                    _loadClassStudents();
                    widget.onRefreshNeeded();
                  }
                }
              },
              child: const Text('Ghi danh'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeStudent(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận rút sinh viên'),
        content: Text(
            'Bạn có chắc muốn rút sinh viên ${student.fullName} khỏi lớp này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rút khỏi lớp'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await _apiService.removeStudent(widget.classRoom.id, student.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty
                ? res.message
                : (res.success ? 'Đã rút sinh viên khỏi lớp' : 'Thao tác thất bại')),
            backgroundColor: res.success ? AppTheme.success : AppTheme.error,
          ),
        );
        if (res.success) {
          _loadClassStudents();
          widget.onRefreshNeeded();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.classRoom.className,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Danh sách sinh viên ghi danh (${_students.length} SV)',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Ghi danh SV'),
                onPressed: _showEnrollDialog,
              ),
            ],
          ),
          const Divider(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const Center(
                        child: Text(
                          'Lớp này chưa có sinh viên nào được ghi danh.',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final s = _students[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primary.withOpacity(0.12),
                              child: Text(
                                s.fullName.isNotEmpty
                                    ? s.fullName[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary),
                              ),
                            ),
                            title: Text(s.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text('MSSV: ${s.studentCode} • ${s.email}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: AppTheme.error),
                              onPressed: () => _removeStudent(s),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
