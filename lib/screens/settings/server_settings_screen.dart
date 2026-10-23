import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/storage_service.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool? _isSuccess;

  @override
  void initState() {
    super.initState();
    final currentUrl = StorageService.getBaseUrl() ?? ApiConstants.getDefaultBaseUrl();
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
      _isSuccess = null;
    });

    final success = await ApiService().testConnection(url);

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _isSuccess = success;
      _testResult = success
          ? 'Kết nối máy chủ thành công! Backend đang hoạt động.'
          : 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra xem backend đã chạy chưa (dotnet run) và cổng có đúng không.';
    });
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    await StorageService.saveBaseUrl(url);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cấu hình địa chỉ máy chủ thành công!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _applyPreset(String preset) {
    setState(() {
      _urlController.text = preset;
      _testResult = null;
      _isSuccess = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình Máy chủ API'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa chỉ API Backend (.NET)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chọn một địa chỉ có sẵn hoặc nhập URL IP máy tính chạy backend:',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),

            // Presets
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.usb, size: 16),
                  label: const Text('Điện thoại USB / Local (localhost:5215)'),
                  onPressed: () => _applyPreset('http://localhost:5215'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.wifi, size: 16),
                  label: const Text('Mạng Wi-Fi LAN (192.168.1.25:5215)'),
                  onPressed: () => _applyPreset('http://192.168.1.25:5215'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.phone_android, size: 16),
                  label: const Text('Android Emulator (10.0.2.2:5215)'),
                  onPressed: () => _applyPreset('http://10.0.2.2:5215'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://10.0.2.2:5215 hoặc http://192.168.1.x:5215',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _urlController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Connection Button
            CustomButton(
              text: 'Kiểm tra kết nối Máy chủ',
              icon: Icons.network_check_rounded,
              isOutlined: true,
              isLoading: _isTesting,
              onPressed: _testConnection,
            ),
            const SizedBox(height: 16),

            if (_testResult != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isSuccess == true
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSuccess == true
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess == true
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: _isSuccess == true
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _isSuccess == true
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),
            CustomButton(
              text: 'Lưu cấu hình',
              icon: Icons.save_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
