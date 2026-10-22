import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/classroom_model.dart';
import '../../models/attendance_model.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateSessionScreen extends StatefulWidget {
  final int teacherId;
  final List<ClassRoom> classes;

  const CreateSessionScreen({
    super.key,
    required this.teacherId,
    required this.classes,
  });

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  int? _selectedClassId;
  DateTime _sessionDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 30);
  final TextEditingController _wifiController =
      TextEditingController(text: 'HUTECH_CAMPUS_WIFI');
  final TextEditingController _noteController =
      TextEditingController(text: 'Buổi học lý thuyết');
  final TextEditingController _latController =
      TextEditingController(text: '10.8018');
  final TextEditingController _lngController =
      TextEditingController(text: '106.7145');

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.classes.isNotEmpty) {
      _selectedClassId = widget.classes.first.id;
    }
  }

  @override
  void dispose() {
    _wifiController.dispose();
    _noteController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() => _sessionDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _handleCreate() async {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn lớp học'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final session = AttendanceSession(
      id: 0,
      classRoomId: _selectedClassId!,
      teacherId: widget.teacherId,
      sessionDate: _sessionDate,
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(_endTime),
      wifiSSID: _wifiController.text.trim().isEmpty
          ? null
          : _wifiController.text.trim(),
      note: _noteController.text.trim(),
      latitude: double.tryParse(_latController.text.trim()) ?? 10.8018,
      longitude: double.tryParse(_lngController.text.trim()) ?? 106.7145,
    );

    final res = await _apiService.createSession(session);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success && res.data != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo phiên điểm danh thành công!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, res.data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty
              ? res.message
              : 'Tạo phiên điểm danh thất bại'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Phiên Điểm Danh'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn lớp học',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _selectedClassId,
                isExpanded: true,
                items: widget.classes
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.className} (${c.subjectName})'),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedClassId = val),
              ),
              const SizedBox(height: 16),

              // Date Picker
              const Text(
                'Ngày điểm danh',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 20, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_sessionDate),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      const Text(
                        'Thay đổi',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Start & End Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Giờ bắt đầu',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickStartTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text(_formatTimeOfDay(_startTime)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Giờ kết thúc',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickEndTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_filled,
                                    size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text(_formatTimeOfDay(_endTime)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _wifiController,
                label: 'Tên WiFi yêu cầu (WiFi SSID)',
                hint: 'HUTECH_CAMPUS_WIFI',
                prefixIcon: Icons.wifi,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _latController,
                      label: 'Tọa độ Vĩ độ (Latitude)',
                      hint: '10.8018',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _lngController,
                      label: 'Tọa độ Kinh độ (Longitude)',
                      hint: '106.7145',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _noteController,
                label: 'Ghi chú buổi học',
                hint: 'Buổi 1: Giới thiệu môn học...',
                maxLines: 2,
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Tạo Phiên Điểm Danh & Mã QR',
                icon: Icons.qr_code_rounded,
                isLoading: _isLoading,
                onPressed: _handleCreate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
