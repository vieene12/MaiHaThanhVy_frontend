import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/stat_card.dart';
import '../auth/profile_screen.dart';
import 'manage_students_screen.dart';
import 'manage_teachers_screen.dart';
import 'manage_subjects_screen.dart';
import 'manage_classrooms_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  AdminDashboardData? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (mounted) {
      Provider.of<AuthProvider>(context, listen: false).fetchProfile();
    }

    final res = await _apiService.getAdminDashboard();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _dashboardData = res.data;
      } else {
        _errorMessage = res.message.isNotEmpty
            ? res.message
            : 'Không thể tải dữ liệu thống kê';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Hồ sơ cá nhân',
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withOpacity(0.15),
              child: Text(
                user != null && user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off_rounded,
                              size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadDashboard,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Xin chào Quản trị viên,',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.fullName ?? 'Admin',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Quản lý toàn diện sinh viên, giảng viên, môn học và các phiên điểm danh.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // KPI Grid
                        const Text(
                          'Tổng quan hệ thống',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.35,
                          children: [
                            StatCard(
                              title: 'Sinh viên',
                              value: '${_dashboardData?.totalStudents ?? 0}',
                              icon: Icons.people_alt_outlined,
                              color: const Color(0xFF3B82F6),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ManageStudentsScreen(),
                                  ),
                                );
                                if (mounted) _loadDashboard();
                              },
                            ),
                            StatCard(
                              title: 'Giảng viên',
                              value: '${_dashboardData?.totalTeachers ?? 0}',
                              icon: Icons.person_pin_outlined,
                              color: const Color(0xFF10B981),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ManageTeachersScreen(),
                                  ),
                                );
                                if (mounted) _loadDashboard();
                              },
                            ),
                            StatCard(
                              title: 'Môn học',
                              value: '${_dashboardData?.totalSubjects ?? 0}',
                              icon: Icons.menu_book_outlined,
                              color: const Color(0xFF8B5CF6),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ManageSubjectsScreen(),
                                  ),
                                );
                                if (mounted) _loadDashboard();
                              },
                            ),
                            StatCard(
                              title: 'Lớp học',
                              value: '${_dashboardData?.totalClasses ?? 0}',
                              icon: Icons.class_outlined,
                              color: const Color(0xFFF59E0B),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ManageClassroomsScreen(),
                                  ),
                                );
                                if (mounted) _loadDashboard();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Secondary Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Phiên hôm nay',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_dashboardData?.totalSessionsToday ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tỉ lệ có mặt',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_dashboardData?.averageAttendanceRate ?? 0}%',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Management Quick Links
                        const Text(
                          'Danh mục quản lý',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildNavTile(
                          icon: Icons.school_outlined,
                          title: 'Quản lý Sinh viên',
                          subtitle: 'Xem danh sách, thêm, sửa, xóa sinh viên',
                          color: const Color(0xFF3B82F6),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageStudentsScreen(),
                              ),
                            );
                            if (mounted) _loadDashboard();
                          },
                        ),
                        _buildNavTile(
                          icon: Icons.badge_outlined,
                          title: 'Quản lý Giảng viên',
                          subtitle: 'Danh sách giảng viên và khoa phụ trách',
                          color: const Color(0xFF10B981),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageTeachersScreen(),
                              ),
                            );
                            if (mounted) _loadDashboard();
                          },
                        ),
                        _buildNavTile(
                          icon: Icons.book_outlined,
                          title: 'Quản lý Môn học',
                          subtitle: 'Thiết lập mã môn, số tín chỉ môn học',
                          color: const Color(0xFF8B5CF6),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageSubjectsScreen(),
                              ),
                            );
                            if (mounted) _loadDashboard();
                          },
                        ),
                        _buildNavTile(
                          icon: Icons.meeting_room_outlined,
                          title: 'Quản lý Lớp học & Ghi danh',
                          subtitle: 'Phân công lớp, giảng viên và sinh viên',
                          color: const Color(0xFFF59E0B),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ManageClassroomsScreen(),
                              ),
                            );
                            if (mounted) _loadDashboard();
                          },
                        ),
                        const SizedBox(height: 24),

                        // Recent Activities
                        const Text(
                          'Hoạt động điểm danh gần đây',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_dashboardData?.recentActivities.isEmpty ?? true)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'Chưa có lượt điểm danh nào gần đây.',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ),
                          )
                        else
                          ...(_dashboardData!.recentActivities.map((act) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFDCFCE7),
                                    child: Icon(Icons.check,
                                        color: AppTheme.success, size: 20),
                                  ),
                                  title: Text(
                                    act.description,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    act.timestamp.toLocal().toString().substring(0, 16),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ))),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
