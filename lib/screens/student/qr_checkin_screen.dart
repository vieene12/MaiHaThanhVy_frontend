import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

  Future<void> _openCameraScanner() async {
    final scannedValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const _QrCameraScannerPage(),
      ),
    );

    if (scannedValue != null && scannedValue.trim().isNotEmpty && mounted) {
      final raw = scannedValue.trim();
      // Support both "sessionId|qrCode" and plain "ATT-..." QR codes
      if (raw.contains('|')) {
        final parts = raw.split('|');
        if (parts.length >= 2 && int.tryParse(parts[0].trim()) != null) {
          _sessionIdController.text = parts[0].trim();
          _qrCodeController.text = parts.sublist(1).join('|').trim();
        } else {
          _qrCodeController.text = raw;
        }
      } else {
        _qrCodeController.text = raw;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã quét mã QR: ${_qrCodeController.text}'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );

      // Automatically submit check-in after scanning
      await _handleCheckin();
    }
  }

  Future<void> _handleCheckin() async {
    if (!_formKey.currentState!.validate()) return;

    // Allow sessionId = 0 when user scans QR code directly without typing Session ID
    final sessionIdText = _sessionIdController.text.trim();
    final sessionId = sessionIdText.isEmpty ? 0 : int.tryParse(sessionIdText);
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã phiên (Session ID) phải là số hợp lệ'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded),
            tooltip: 'Mở Camera quét QR',
            onPressed: _openCameraScanner,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Interactive Scanner Card (Tap to open Camera)
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _openCameraScanner,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.35),
                        width: 2,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 64,
                          color: AppTheme.primary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Chạm để mở Camera',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _openCameraScanner,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text(
                  'Mở Camera Quét Mã QR',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Hoặc Nhập Mã Code Thủ Công (4 - 6 ký tự)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nếu không quét được Camera, hãy nhập mã 4 - 6 ký tự hiển thị dưới mã QR của giảng viên:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _qrCodeController,
                label: 'Mã Code điểm danh (4 - 6 ký tự)',
                hint: 'Ví dụ: QR1001',
                prefixIcon: Icons.pin_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng quét QR hoặc nhập mã Code (4 - 6 ký tự)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _sessionIdController,
                label: 'Mã phiên (Session ID - Không bắt buộc)',
                hint: 'Để trống hệ thống tự nhận diện theo mã Code',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.tag,
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
              const SizedBox(height: 24),

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

class _QrCameraScannerPage extends StatefulWidget {
  const _QrCameraScannerPage();

  @override
  State<_QrCameraScannerPage> createState() => _QrCameraScannerPageState();
}

class _QrCameraScannerPageState extends State<_QrCameraScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _hasScanned = true;
        Navigator.pop(context, rawValue.trim());
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quét Mã QR Điểm Danh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: 'Bật/Tắt đèn Flash',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            tooltip: 'Đổi Camera trước/sau',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Framing overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Hướng camera vào mã QR của giảng viên để tự động điểm danh',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
