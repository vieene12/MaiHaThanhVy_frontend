import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Default host addresses depending on platform
  static const String defaultEmulatorHost = 'http://localhost:5215';
  static const String defaultLanHost = 'http://192.168.1.25:5215';
  static const String defaultLocalhost = 'http://localhost:5215';
  static const String defaultHttpsLocalhost = 'https://localhost:7190';

  static String getDefaultBaseUrl() {
    if (kIsWeb) {
      return defaultLocalhost;
    }
    try {
      if (Platform.isAndroid) {
        // Standard Android emulator translates 10.0.2.2 to host's 127.0.0.1
        return defaultEmulatorHost;
      }
    } catch (_) {}
    return defaultLocalhost;
  }

  // Endpoints
  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String authVerifyOtp = '/api/auth/verify-otp';
  static const String authResendOtp = '/api/auth/resend-otp';
  static const String authGoogleLogin = '/api/auth/google-login';
  static const String authProfile = '/api/auth/profile';

  static const String dashboardAdmin = '/api/dashboard/admin';
  static const String dashboardTeacher = '/api/dashboard/teacher';
  static const String dashboardStudent = '/api/dashboard/student';

  static const String students = '/api/students';
  static const String teachers = '/api/teachers';
  static const String subjects = '/api/subjects';
  static const String classrooms = '/api/classrooms';

  static const String attendanceSessions = '/api/attendance/sessions';
  static const String attendanceStudent = '/api/attendance/student';
  static const String attendanceReport = '/api/attendance/report';
  static const String attendanceRecords = '/api/attendance/records';
}
