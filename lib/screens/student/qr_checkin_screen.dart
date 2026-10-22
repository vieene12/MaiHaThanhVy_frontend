import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class QrCheckinScreen extends StatefulWidget {
  final int studentId;

  const QrCheckinScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<QrCheckinScreen> createState() => _QrCheckinScreenState();
}

class _QrCheckinScreenState extends State<QrCheckinScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _sessionIdController = TextEditingController();
  final TextEditingController _qrCodeController = TextEditingController();
  final TextEditingController _latController =
      TextEditingController(text: '10.8018');
  final TextEditingController _lngController =
      TextEditingController(text: '106.7145');

  bool _isLoading = false;

  @override
  void dispose() {
    _sessionIdController.dispose();
    _qrCodeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckin() async {
    if (!_formKey.currentState!.validate()) return;

    final sessionId = int.tryParse(_sessionIdController.text.trim());
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập ID phiên điểm danh hợp lệ'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await _apiService.qrCheckIn(
      sessionId: sessionId,
      studentId: widget.studentId,
      qrCode: _qrCodeController.text.trim(),
      latitude: double.tryParse(_latController.text.trim()) ?? 10.8018,
      longitude: double.tryParse(_lngController.text.trim()) ?? 106.7145,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success && res.data != null) {
      final record = res.data!;
      _showResultDialog(
        isSuccess: true,
        title: 'Điểm danh thành công!',
        message:
            'Trạng thái: ${record.status == "PRESENT" ? "Có mặt đúng giờ" : record.status == "LATE" ? "Đi muộn" : record.status}\nThời gian: ${record.checkInTime.toLocal().toString().substring(11, 16)}',
      );
    } else {
      _showResultDialog(
        isSuccess: false,
        title: 'Điểm danh thất bại',
        message: res.message.isNotEmpty
            ? res.message
            : 'Mã QR không đúng, phiên đã đóng hoặc bạn nằm ngoài phạm vi GPS.',
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
          isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
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
        title: const Text('Điểm Danh Mã QR'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scanner Animation Illustration
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 72,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nhập Mã QR & Vị Trí GPS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dán hoặc nhập mã QR được chiếu trên màn hình lớp học:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _sessionIdController,
                label: 'Mã phiên điểm danh (Session ID)',
                hint: 'Ví dụ: 1',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.tag,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập Session ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _qrCodeController,
                label: 'Nội dung mã QR',
                hint: 'ATT-1-...',
                prefixIcon: Icons.qr_code,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập hoặc dán mã QR';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // GPS Coordinates Row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _latController,
                      label: 'Vĩ độ GPS (Lat)',
                      hint: '10.8018',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _lngController,
                      label: 'Kinh độ GPS (Lng)',
                      hint: '106.7145',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '*(Mặc định tọa độ cơ sở HUTECH: 10.8018, 106.7145 để thỏa mãn điều kiện bán kính lớp học)',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Xác Nhận Điểm Danh',
                icon: Icons.check_circle_outline,
                isLoading: _isLoading,
                onPressed: _handleCheckin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
