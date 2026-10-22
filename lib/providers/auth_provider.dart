import 'package:flutter/material.dart';

import '../core/utils/storage_service.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserInfoDto? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserInfoDto? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _currentUser != null;

  String get role => _currentUser?.role ?? 'STUDENT';
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isTeacher => _currentUser?.isTeacher ?? false;
  bool get isStudent => _currentUser?.isStudent ?? false;

  AuthProvider() {
    _loadUserFromStorage();
  }

  void _loadUserFromStorage() {
    _token = StorageService.getToken();
    _currentUser = StorageService.getUser();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.login(email: email, password: password);
    _isLoading = false;

    if (!response.success || response.data == null) {
      _errorMessage = response.message.isNotEmpty
          ? response.message
          : 'Đăng nhập không thành công';
      notifyListeners();
      return false;
    }

    final loginData = response.data!;

    // If OTP is required, save temporary user state for verify-otp screen
    if (loginData.requiresOtp) {
      if (loginData.user != null) {
        _currentUser = loginData.user;
      }
      notifyListeners();
      return true; // Indicates credentials were valid, navigate to OTP
    }

    // A successful response without OTP must include both credentials.
    if (loginData.token == null ||
        loginData.token!.isEmpty ||
        loginData.user == null) {
      _errorMessage = 'Phản hồi đăng nhập thiếu thông tin xác thực';
      notifyListeners();
      return false;
    }

    _token = loginData.token;
    _currentUser = loginData.user;
    await StorageService.saveToken(_token!);
    await StorageService.saveUser(_currentUser!);
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.register(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      phoneNumber: phoneNumber,
    );

    _isLoading = false;

    if (!response.success || response.data == null) {
      _errorMessage = response.message.isNotEmpty
          ? response.message
          : 'Đăng ký không thành công';
      notifyListeners();
      return false;
    }

    if (response.data?.user != null) {
      _currentUser = response.data!.user;
    }

    notifyListeners();
    return true;
  }

  Future<bool> verifyOtp({
    required String email,
    required String code,
    required String type,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.verifyOtp(
      email: email,
      code: code,
      type: type,
    );

    _isLoading = false;

    if (!response.success || response.data == null) {
      _errorMessage = response.message.isNotEmpty
          ? response.message
          : 'Xác thực OTP thất bại';
      notifyListeners();
      return false;
    }

    final loginData = response.data!;
    if (loginData.token == null ||
        loginData.token!.isEmpty ||
        loginData.user == null) {
      _errorMessage = 'Phản hồi xác thực OTP thiếu thông tin đăng nhập';
      notifyListeners();
      return false;
    }

    _token = loginData.token;
    _currentUser = loginData.user;
    await StorageService.saveToken(_token!);
    await StorageService.saveUser(_currentUser!);
    notifyListeners();
    return true;
  }

  Future<String?> resendOtp({
    required String email,
    required String type,
  }) async {
    final response = await _apiService.resendOtp(email: email, type: type);
    return response.success ? null : response.message;
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;
    final response = await _apiService.getProfile();
    if (response.success && response.data != null) {
      _currentUser = response.data;
      await StorageService.saveUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? avatar,
    String? currentPassword,
    String? newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      avatar: avatar,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    _isLoading = false;

    if (!response.success || response.data == null) {
      _errorMessage = response.message.isNotEmpty
          ? response.message
          : 'Cập nhật thất bại';
      notifyListeners();
      return false;
    }

    _currentUser = response.data;
    await StorageService.saveUser(_currentUser!);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _errorMessage = null;
    await StorageService.clearAuth();
    notifyListeners();
  }
}
