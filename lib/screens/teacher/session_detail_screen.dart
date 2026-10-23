import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../models/student_model.dart';
import '../../services/api_service.dart';

class SessionDetailScreen extends StatefulWidget {
  final int sessionId;

  const SessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final ApiService _apiService = ApiService();
  AttendanceSession? _session;
  List<Student> _enrolledStudents = [];
  final Map<int, String> _studentStatuses = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessionDetails();
  }

  Future<void> _loadSessionDetails() async {
    if (_session == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final sessionRes = await _apiService.getSessionById(widget.sessionId);

    if (!mounted) return;

    if (sessionRes.success && sessionRes.data != null) {
      _session = sessionRes.data;
      final studentsRes =
          await _apiService.getStudentsByClass(_session!.classRoomId);
      if (mounted && studentsRes.success && studentsRes.data != null) {
        _enrolledStudents = studentsRes.data!;
        // Fetch current session status for each enrolled student
        for (final student in _enrolledStudents) {
          final histRes =
              await _apiService.getStudentAttendanceHistory(student.id);
          if (histRes.success && histRes.data != null) {
            final match = histRes.data!
                .where((r) => r.sessionId == widget.sessionId)
                .toList();
            if (match.isNotEmpty) {
              _studentStatuses[student.id] = match.first.status.toUpperCase();
            }
          }
        }
      }
    } else {
      _errorMessage = sessionRes.message.isNotEmpty
          ? sessionRes.message
          : 'Không thể tải chi tiết phiên điểm danh';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return 'Có mặt';
      case 'LATE':
        return 'Đi muộn';
      case 'EXCUSED':
        return 'Có phép';
      case 'ABSENT':
        return 'Vắng mặt';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return AppTheme.success;
      case 'LATE':
        return AppTheme.warning;
      case 'EXCUSED':
        return AppTheme.info;
      case 'ABSENT':
        return AppTheme.error;
      default:
        return const Color(0xFF64748B);
    }
  }

  void _showManualCheckInDialog(Student student) {
    String selectedStatus = _studentStatuses[student.id] ?? 'PRESENT';
    final noteController = TextEditingController();
    final parentContext = context;
    final messenger = ScaffoldMessenger.of(parentContext);

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Điểm danh cho ${student.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MSSV: ${student.studentCode}'),
              const SizedBox(height: 16),
              const Text(
                'Chọn trạng thái:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Có mặt'),
                    selected: selectedStatus == 'PRESENT',
                    onSelected: (val) {
                      if (val) setDialogState(() => selectedStatus = 'PRESENT');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Đi muộn'),
                    selected: selectedStatus == 'LATE',
                    onSelected: (val) {
                      if (val) setDialogState(() => selectedStatus = 'LATE');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Có phép'),
                    selected: selectedStatus == 'EXCUSED',
                    onSelected: (val) {
                      if (val) setDialogState(() => selectedStatus = 'EXCUSED');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Vắng mặt'),
                    selected: selectedStatus == 'ABSENT',
                    onSelected: (val) {
                      if (val) setDialogState(() => selectedStatus = 'ABSENT');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final noteText = noteController.text.trim();
                Navigator.pop(ctx);

                final res = await _apiService.manualCheckIn(
                  sessionId: widget.sessionId,
                  studentId: student.id,
                  status: selectedStatus,
                  note: noteText.isEmpty ? null : noteText,
                );

                if (!mounted) return;

                if (res.success) {
                  setState(() {
                    _studentStatuses[student.id] = selectedStatus;
                  });
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Điểm danh thành công: ${student.fullName} (${_statusLabel(selectedStatus)})',
                      ),
                      backgroundColor: AppTheme.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  await _loadSessionDetails();
                } else {
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        res.message.isNotEmpty
                            ? res.message
                            : 'Điểm danh thất bại',
                      ),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Phiên Điểm Danh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessionDetails,
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
              : _session == null
                  ? const Center(child: Text('Không tìm thấy dữ liệu phiên'))
                  : RefreshIndicator(
                      onRefresh: _loadSessionDetails,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // QR Code Card
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Text(
                                      _session!.className,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _session!.subjectName,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // QR Code Image
                                    if (_session!.qrCode != null &&
                                        _session!.qrCode!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                            width: 2,
                                          ),
                                        ),
                                        child: QrImageView(
                                          data: _session!.qrCode!,
                                          version: QrVersions.auto,
                                          size: 200.0,
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                    const SizedBox(height: 12),

                                    // QR text with copy (4-6 char code badge)
                                    InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        if (_session!.qrCode != null) {
                                          Clipboard.setData(ClipboardData(
                                              text: _session!.qrCode!));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Đã sao chép mã điểm danh vào bộ nhớ tạm'),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color:
                                              AppTheme.primary.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppTheme.primary
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Mã nhập tay: ${_session!.qrCode ?? "N/A"}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                letterSpacing: 1.5,
                                                color: AppTheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.copy_rounded,
                                                size: 18,
                                                color: AppTheme.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Mã phiên: #${_session!.id} • Giờ học: ${_session!.startTime} - ${_session!.endTime} • ${DateFormat("dd/MM/yyyy").format(_session!.sessionDate)}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF334155)),
                                    ),
                                    if (_session!.wifiSSID != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'WiFi yêu cầu: ${_session!.wifiSSID}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Attendance Summary Row
                            Row(
                              children: [
                                _buildCounter(
                                    'Có mặt',
                                    _session!.presentCount.toString(),
                                    AppTheme.success),
                                const SizedBox(width: 8),
                                _buildCounter(
                                    'Đi muộn',
                                    _session!.lateCount.toString(),
                                    AppTheme.warning),
                                const SizedBox(width: 8),
                                _buildCounter(
                                    'Vắng',
                                    _session!.absentCount.toString(),
                                    AppTheme.error),
                                const SizedBox(width: 8),
                                _buildCounter(
                                    'Tổng SV',
                                    _session!.totalStudents.toString(),
                                    AppTheme.primary),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Students List Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Danh sách sinh viên lớp',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_enrolledStudents.length} sinh viên',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (_enrolledStudents.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Lớp chưa có sinh viên ghi danh.',
                                  style: TextStyle(color: Color(0xFF94A3B8)),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _enrolledStudents.length,
                                itemBuilder: (context, index) {
                                  final s = _enrolledStudents[index];
                                  final currentStatus = _studentStatuses[s.id];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: currentStatus != null
                                            ? _statusColor(currentStatus)
                                                .withOpacity(0.15)
                                            : AppTheme.primary
                                                .withOpacity(0.12),
                                        child: Text(
                                          s.fullName.isNotEmpty
                                              ? s.fullName[0].toUpperCase()
                                              : 'S',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: currentStatus != null
                                                ? _statusColor(currentStatus)
                                                : AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        s.fullName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('MSSV: ${s.studentCode}'),
                                          if (currentStatus != null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(
                                                          currentStatus)
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  _statusLabel(currentStatus),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: _statusColor(
                                                        currentStatus),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: currentStatus != null
                                              ? _statusColor(currentStatus)
                                              : AppTheme.primary,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          textStyle: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        icon: Icon(
                                            currentStatus != null
                                                ? Icons.edit_rounded
                                                : Icons.check,
                                            size: 14),
                                        label: Text(currentStatus != null
                                            ? _statusLabel(currentStatus)
                                            : 'Điểm danh'),
                                        onPressed: () =>
                                            _showManualCheckInDialog(s),
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

  Widget _buildCounter(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
