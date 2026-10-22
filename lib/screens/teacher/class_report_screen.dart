import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../services/api_service.dart';

class ClassReportScreen extends StatefulWidget {
  final int classRoomId;
  final String className;

  const ClassReportScreen({
    super.key,
    required this.classRoomId,
    required this.className,
  });

  @override
  State<ClassReportScreen> createState() => _ClassReportScreenState();
}

class _ClassReportScreenState extends State<ClassReportScreen> {
  final ApiService _apiService = ApiService();
  ClassAttendanceReport? _report;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _apiService.getClassAttendanceReport(widget.classRoomId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _report = res.data;
      } else {
        _errorMessage = res.message.isNotEmpty
            ? res.message
            : 'Không thể tải báo cáo điểm danh';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Báo Cáo - ${widget.className}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: AppTheme.error)),
                )
              : _report == null
                  ? const Center(child: Text('Không có dữ liệu báo cáo'))
                  : RefreshIndicator(
                      onRefresh: _loadReport,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _report!.className,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _report!.subjectName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Tổng số buổi học',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            Text(
                                              '${_report!.totalSessions}',
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Sĩ số sinh viên',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            Text(
                                              '${_report!.totalStudents}',
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
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

                            const Text(
                              'Chi tiết điểm danh từng sinh viên',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (_report!.studentsSummary.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'Chưa có dữ liệu sinh viên trong lớp.',
                                    style: TextStyle(color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _report!.studentsSummary.length,
                                itemBuilder: (context, index) {
                                  final s = _report!.studentsSummary[index];
                                  final rateColor = s.attendanceRate >= 80
                                      ? AppTheme.success
                                      : s.attendanceRate >= 50
                                          ? AppTheme.warning
                                          : AppTheme.error;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
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
                                                  s.studentName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: rateColor.withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${s.attendanceRate}%',
                                                  style: TextStyle(
                                                    color: rateColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'MSSV: ${s.studentCode}',
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          LinearProgressIndicator(
                                            value: s.attendanceRate / 100,
                                            backgroundColor:
                                                const Color(0xFFE2E8F0),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    rateColor),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            minHeight: 6,
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Có mặt: ${s.presentSessions}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.success,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                'Đi muộn: ${s.lateSessions}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.warning,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                'Có phép: ${s.excusedSessions}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                'Vắng: ${s.absentSessions}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.error,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
