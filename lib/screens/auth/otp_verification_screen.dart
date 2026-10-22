import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../admin/admin_dashboard_screen.dart';
import '../teacher/teacher_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String type; // 'LOGIN' or 'REGISTER'

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.type,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  int _secondsLeft = 60;
  Timer? _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 chữ số mã OTP'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.verifyOtp(
      email: widget.email,
      code: code,
      type: widget.type,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác thực OTP thành công! Đăng nhập thành công.'),
          backgroundColor: AppTheme.success,
        ),
      );

      Widget nextScreen;
      if (auth.isAdmin) {
        nextScreen = const AdminDashboardScreen();
      } else if (auth.isTeacher) {
        nextScreen = const TeacherDashboardScreen();
      } else {
        nextScreen = const StudentDashboardScreen();
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Mã OTP không hợp lệ'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    if (_secondsLeft > 0 || _isResending) return;

    setState(() => _isResending = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final err = await auth.resendOtp(email: widget.email, type: widget.type);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi lại mã OTP vào email của bạn!'),
          backgroundColor: AppTheme.success,
        ),
      );
      _startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Xác Thực OTP')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 54,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nhập Mã Xác Thực',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã OTP 6 chữ số đã được gửi đến email:\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // OTP Input
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    letterSpacing: 16,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Xác Nhận & Tiếp Tục',
                isLoading: auth.isLoading,
                icon: Icons.check_circle_outline,
                onPressed: _handleVerify,
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa nhận được mã? ',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _secondsLeft == 0 ? _handleResend : null,
                    child: Text(
                      _secondsLeft > 0
                          ? 'Gửi lại (${_secondsLeft}s)'
                          : 'Gửi lại mã',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _secondsLeft == 0
                            ? AppTheme.primary
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
