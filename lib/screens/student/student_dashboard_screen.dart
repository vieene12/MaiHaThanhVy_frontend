import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/dashboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/profile_screen.dart';
import 'qr_checkin_screen.dart';
import 'wifi_checkin_screen.dart';
import 'student_attendance_history_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final ApiService _apiService = ApiService();
  StudentDashboardData? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

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

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final studentId = auth.currentUser?.studentId;
    if (studentId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Tài khoản chưa được liên kết với hồ sơ sinh viên.';
      });
      return;
    }

    final res = await _apiService.getStudentDashboard(studentId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _dashboardData = res.data;
      } else {
        _errorMessage = res.message.isNotEmpty
            ? res.message
            : 'Không thể tải thống kê sinh viên';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final studentId = user?.studentId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm Danh Sinh Viên'),
        actions: [
          IconButton(
            tooltip: 'Hồ sơ',
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withOpacity(0.15),
              child: Text(
                user != null && user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : 'S',
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
            : _errorMessage != null || studentId == null
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
                      Text(
                        _errorMessage ??
                            'Tài khoản chưa được liên kết với hồ sơ sinh viên.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadDashboard,
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
                    // Student Greeting Banner
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
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.fullName ?? 'Sinh viên',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'MSSV: ${_dashboardData?.studentCode ?? user?.email ?? ""}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionBtn(
                            title: 'Điểm danh QR',
                            icon: Icons.qr_code_scanner_rounded,
                            color: AppTheme.primary,
                            onTap: () async {
                              final checked = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      QrCheckinScreen(studentId: studentId),
                                ),
                              );
                              if (checked == true) _loadDashboard();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionBtn(
                            title: 'Điểm danh WiFi',
                            icon: Icons.wifi_rounded,
                            color: const Color(0xFF06B6D4),
                            onTap: () async {
                              final checked = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      WifiCheckinScreen(studentId: studentId),
                                ),
                              );
                              if (checked == true) _loadDashboard();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionBtn(
                            title: 'Lịch sử',
                            icon: Icons.history_rounded,
                            color: const Color(0xFF8B5CF6),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StudentAttendanceHistoryScreen(
                                        studentId: studentId,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Overall Attendance Stats
                    const Text(
                      'Tổng quan điểm danh',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Circular Progress
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value:
                                        (_dashboardData?.attendanceRate ?? 0) /
                                        100,
                                    strokeWidth: 8,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppTheme.success,
                                        ),
                                  ),
                                  Center(
                                    child: Text(
                                      '${_dashboardData?.attendanceRate ?? 0}%',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),

                            // Detail counters
                            Expanded(
                              child: Column(
                                children: [
                                  _buildStatRow(
                                    'Có mặt',
                                    '${_dashboardData?.presentCount ?? 0} buổi',
                                    AppTheme.success,
                                  ),
                                  const SizedBox(height: 6),
                                  _buildStatRow(
                                    'Đi muộn',
                                    '${_dashboardData?.lateCount ?? 0} buổi',
                                    AppTheme.warning,
                                  ),
                                  const SizedBox(height: 6),
                                  _buildStatRow(
                                    'Có phép',
                                    '${_dashboardData?.excusedCount ?? 0} buổi',
                                    AppTheme.primary,
                                  ),
                                  const SizedBox(height: 6),
                                  _buildStatRow(
                                    'Vắng mặt',
                                    '${_dashboardData?.absentCount ?? 0} buổi',
                                    AppTheme.error,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Enrolled Classes
                    const Text(
                      'Các lớp học đã đăng ký',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_dashboardData?.enrolledClasses.isEmpty ?? true)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Bạn chưa ghi danh vào lớp học nào.',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                      )
                    else
                      ...(_dashboardData!.enrolledClasses.map(
                        (cl) => Card(
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
                                        cl.className,
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
                                        color: cl.attendanceRate >= 80
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${cl.attendanceRate}%',
                                        style: TextStyle(
                                          color: cl.attendanceRate >= 80
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFFB45309),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cl.subjectName,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: cl.attendanceRate / 100,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    cl.attendanceRate >= 80
                                        ? AppTheme.success
                                        : AppTheme.warning,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  minHeight: 6,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Đã tham gia ${cl.attendedSessions}/${cl.totalSessions} buổi học',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActionBtn({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
