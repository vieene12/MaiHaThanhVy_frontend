import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class WifiCheckinScreen extends StatefulWidget {
  final int studentId;

  const WifiCheckinScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<WifiCheckinScreen> createState() => _WifiCheckinScreenState();
}

class _WifiCheckinScreenState extends State<WifiCheckinScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _sessionIdController = TextEditingController();
  final TextEditingController _wifiSsidController =
      TextEditingController(text: 'HUTECH_CAMPUS_WIFI');
  final TextEditingController _latController =
      TextEditingController(text: '10.8018');
  final TextEditingController _lngController =
      TextEditingController(text: '106.7145');

  bool _isLoading = false;

  @override
  void dispose() {
    _sessionIdController.dispose();
    _wifiSsidController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _handleWifiCheckin() async {
    if (!_formKey.currentState!.validate()) return;

    final sessionIdText = _sessionIdController.text.trim();
    final sessionId = sessionIdText.isEmpty ? 1 : int.tryParse(sessionIdText);
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập Session ID hợp lệ'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await _apiService.wifiCheckIn(
      sessionId: sessionId,
      studentId: widget.studentId,
      wifiSSID: _wifiSsidController.text.trim(),
      latitude: double.tryParse(_latController.text.trim()) ?? 10.8018,
      longitude: double.tryParse(_lngController.text.trim()) ?? 106.7145,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success && res.data != null) {
      final record = res.data!;
      _showResultDialog(
        isSuccess: true,
        title: 'Điểm danh WiFi thành công!',
        message:
            'Trạng thái: ${record.status == "PRESENT" ? "Có mặt đúng giờ" : record.status == "LATE" ? "Đi muộn" : record.status}\nMạng WiFi: ${_wifiSsidController.text}',
      );
    } else {
      _showResultDialog(
        isSuccess: false,
        title: 'Điểm danh WiFi thất bại',
        message: res.message.isNotEmpty
            ? res.message
            : 'Tên WiFi không khớp hoặc phiên điểm danh không tồn tại.',
      );
    }
  }

  void _showResultDialog({
    required bool isSuccess,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          isSuccess ? Icons.wifi_protected_setup : Icons.wifi_off_rounded,
          color: isSuccess ? AppTheme.success : AppTheme.error,
          size: 48,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? AppTheme.success : AppTheme.primary,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (isSuccess) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm Danh Qua WiFi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.wifi_rounded,
                      size: 64,
                      color: Color(0xFF06B6D4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Điểm Danh Mạng WiFi Trường',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kết nối vào mạng WiFi của giảng viên hoặc trường học để xác thực có mặt tại phòng học:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _sessionIdController,
                label: 'Mã phiên điểm danh (Session ID - Mặc định: 1)',
                hint: 'Để trống sẽ mặc định phiên #1',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.tag,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _wifiSsidController,
                label: 'Tên mạng WiFi (SSID)',
                hint: 'HUTECH_CAMPUS_WIFI',
                prefixIcon: Icons.wifi,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên mạng WiFi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _latController,
                      label: 'Vĩ độ GPS',
                      hint: '10.8018',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _lngController,
                      label: 'Kinh độ GPS',
                      hint: '106.7145',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Xác Nhận Điểm Danh WiFi',
                icon: Icons.wifi_tethering_rounded,
                backgroundColor: const Color(0xFF06B6D4),
                isLoading: _isLoading,
                onPressed: _handleWifiCheckin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
