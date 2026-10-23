import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/classroom_model.dart';
import '../../models/dashboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/stat_card.dart';
import '../auth/profile_screen.dart';
import 'create_session_screen.dart';
import 'session_detail_screen.dart';
import 'class_report_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final ApiService _apiService = ApiService();

  TeacherDashboardData? _dashboardData;
  List<ClassRoom> _classes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final teacherId = auth.currentUser?.teacherId;
    if (teacherId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Tài khoản chưa được liên kết với hồ sơ giảng viên.';
      });
      return;
    }

    final dashRes = await _apiService.getTeacherDashboard(teacherId);
    final classesRes = await _apiService.getClassRooms(
      teacherId: teacherId,
      pageSize: 50,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (dashRes.success && dashRes.data != null) {
        _dashboardData = dashRes.data;
      } else {
        _errorMessage = dashRes.message.isNotEmpty
            ? dashRes.message
            : 'Không thể tải thống kê giảng viên';
      }

      if (classesRes.success && classesRes.data != null) {
        _classes = classesRes.data!.items;
      }
    });
  }

  void _openCreateSession() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final teacherId = auth.currentUser?.teacherId;
    if (teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tài khoản chưa được liên kết với hồ sơ giảng viên.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final createdSession = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateSessionScreen(teacherId: teacherId, classes: _classes),
      ),
    );

    if (createdSession != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionDetailScreen(sessionId: createdSession.id),
        ),
      );
      if (mounted) _loadTeacherData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Điều Khiển Giảng Viên'),
        actions: [
          IconButton(
            tooltip: 'Hồ sơ',
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withOpacity(0.15),
              child: Text(
                user != null && user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : 'G',
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_2),
        label: const Text('Tạo buổi điểm danh'),
        onPressed: _openCreateSession,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTeacherData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadTeacherData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tải lại'),
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
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giảng viên',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.fullName ?? 'Giảng viên',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Quản lý điểm danh các lớp giảng dạy và tạo mã QR cho sinh viên.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats
                    const Text(
                      'Thống kê giảng dạy',
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
                          title: 'Lớp phụ trách',
                          value: '${_dashboardData?.totalClasses ?? 0}',
                          icon: Icons.class_outlined,
                          color: const Color(0xFF0D9488),
                        ),
                        StatCard(
                          title: 'Tổng số SV',
                          value: '${_dashboardData?.totalStudents ?? 0}',
                          icon: Icons.people_outline,
                          color: const Color(0xFF3B82F6),
                        ),
                        StatCard(
                          title: 'Số buổi điểm danh',
                          value: '${_dashboardData?.totalSessions ?? 0}',
                          icon: Icons.qr_code_scanner,
                          color: const Color(0xFF8B5CF6),
                        ),
                        StatCard(
                          title: 'Tỉ lệ chuyên cần',
                          value:
                              '${_dashboardData?.overallAttendanceRate ?? 0}%',
                          icon: Icons.analytics_outlined,
                          color: AppTheme.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Teaching Classes
                    const Text(
                      'Danh sách lớp học của bạn',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_classes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Bạn chưa được phân công lớp học nào.',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                      )
                    else
                      ..._classes.map(
                        (c) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${c.enrolledStudentsCount} SV',
                                        style: const TextStyle(
                                          color: Color(0xFF15803D),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${c.subjectCode} - ${c.subjectName}',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                                if (c.room != null && c.room!.isNotEmpty)
                                  Text(
                                    'Phòng: ${c.room} • ${c.schedule ?? ""}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.assessment_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('Báo cáo'),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ClassReportScreen(
                                              classRoomId: c.id,
                                              className: c.className,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.qr_code_2,
                                        size: 16,
                                      ),
                                      label: const Text('Mở điểm danh'),
                                      onPressed: () async {
                                        final createdSession =
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CreateSessionScreen(
                                                      teacherId: c.teacherId,
                                                      classes: [c],
                                                    ),
                                              ),
                                            );
                                        if (createdSession != null && mounted) {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  SessionDetailScreen(
                                                    sessionId:
                                                        createdSession.id,
                                                  ),
                                            ),
                                          );
                                          if (mounted) _loadTeacherData();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Recent Sessions
                    const Text(
                      'Các buổi học gần đây',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_dashboardData?.recentSessions.isEmpty ?? true)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Chưa có phiên điểm danh nào được tạo.',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                      )
                    else
                      ...(_dashboardData!.recentSessions.map(
                        (s) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFEFF6FF),
                              child: Icon(
                                Icons.qr_code,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              s.className,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy').format(s.sessionDate),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${s.presentCount}/${s.totalStudents} có mặt',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.success,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SessionDetailScreen(
                                    sessionId: s.sessionId,
                                  ),
                                ),
                              );
                              if (mounted) _loadTeacherData();
                            },
                          ),
                        ),
                      )),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
      ),
    );
  }
}
