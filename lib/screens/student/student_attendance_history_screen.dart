import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../services/api_service.dart';
import '../../widgets/status_badge.dart';

class StudentAttendanceHistoryScreen extends StatefulWidget {
  final int studentId;

  const StudentAttendanceHistoryScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentAttendanceHistoryScreen> createState() =>
      _StudentAttendanceHistoryScreenState();
}

class _StudentAttendanceHistoryScreenState
    extends State<StudentAttendanceHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<StudentAttendanceHistoryItem> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res =
        await _apiService.getStudentAttendanceHistory(widget.studentId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _history = res.data!;
      } else {
        _errorMessage = res.message.isNotEmpty
            ? res.message
            : 'Không thể tải lịch sử điểm danh';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Điểm Danh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: AppTheme.error)),
                  )
                : _history.isEmpty
                    ? const Center(
                        child: Text(
                          'Bạn chưa có lượt điểm danh nào được ghi nhận.',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          return Card(
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
                                          item.className,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      StatusBadge(status: item.status),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.subjectName,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Divider(height: 18),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.calendar_today_outlined,
                                              size: 14,
                                              color: Color(0xFF64748B)),
                                          const SizedBox(width: 6),
                                          Text(
                                            DateFormat('dd/MM/yyyy')
                                                .format(item.sessionDate),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF334155)),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 14,
                                              color: Color(0xFF64748B)),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Vào lớp: ${item.checkInTime.toLocal().toString().substring(11, 16)}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF334155)),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.method,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.note != null &&
                                      item.note!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ghi chú: ${item.note}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
