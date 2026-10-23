import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/storage_service.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/subject_model.dart';
import '../models/classroom_model.dart';
import '../models/attendance_model.dart';
import '../models/dashboard_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl {
    final customUrl = StorageService.getBaseUrl();
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return customUrl.trim();
    }
    return ApiConstants.getDefaultBaseUrl();
  }

  Map<String, String> _getHeaders({bool requiresAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final token = StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> _sendHttp(
    String hostUrl,
    String method,
    String endpoint, {
    required Map<String, String> headers,
    String? encodedBody,
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    var uri = Uri.parse('$hostUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final client = http.Client();
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await client.get(uri, headers: headers).timeout(timeout);
        case 'POST':
          return await client
              .post(uri, headers: headers, body: encodedBody)
              .timeout(timeout);
        case 'PUT':
          return await client
              .put(uri, headers: headers, body: encodedBody)
              .timeout(timeout);
        case 'DELETE':
          return await client
              .delete(uri, headers: headers, body: encodedBody)
              .timeout(timeout);
        default:
          throw UnsupportedError('HTTP method $method is not supported.');
      }
    } finally {
      client.close();
    }
  }

  // Generic Request Helper
  Future<ApiResponse<T>> _request<T>(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    T Function(dynamic)? fromJsonT,
  }) async {
    final headers = _getHeaders(requiresAuth: requiresAuth);
    final encodedBody = body != null ? jsonEncode(body) : null;
    final candidates = <String>{
      baseUrl,
      ApiConstants.defaultLocalhost,
      ApiConstants.defaultLanHost,
      'http://10.0.2.2:5215',
    }.toList();

    http.Response? response;
    Object? lastError;

    for (final host in candidates) {
      try {
        response = await _sendHttp(
          host,
          method,
          endpoint,
          headers: headers,
          encodedBody: encodedBody,
          queryParams: queryParams,
        );
        if (host != baseUrl) {
          await StorageService.saveBaseUrl(host);
        }
        break;
      } catch (e) {
        lastError = e;
      }
    }

    try {
      if (response == null) {
        if (lastError != null) throw lastError;
        throw const SocketException('Unable to connect');
      }

      if (response.bodyBytes.isEmpty) {
        return ApiResponse<T>(
          success: response.statusCode >= 200 && response.statusCode < 300,
          message: 'Trạng thái phản hồi: ${response.statusCode}',
        );
      }

      final String responseText = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> json = jsonDecode(responseText);
      return ApiResponse.fromJson(json, fromJsonT);
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        message:
            'Không thể kết nối đến máy chủ ($baseUrl). Vui lòng kiểm tra kết nối mạng hoặc đổi địa chỉ IP trong Cài đặt Máy chủ.',
      );
    } on http.ClientException catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Lỗi kết nối HTTP: ${e.message}',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Lỗi: ${e.toString()}',
      );
    }
  }

  // Test Server Connection
  Future<bool> testConnection(String url) async {
    try {
      final uri = Uri.parse('$url/swagger/v1/swagger.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      try {
        final uri = Uri.parse(url);
        final response = await http.get(uri).timeout(const Duration(seconds: 5));
        return response.statusCode < 500;
      } catch (_) {
        return false;
      }
    }
  }

  // ================= AUTH =================
  Future<ApiResponse<LoginResponse>> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phoneNumber,
  }) async {
    return _request<LoginResponse>(
      'POST',
      ApiConstants.authRegister,
      requiresAuth: false,
      body: {
        'email': email.trim(),
        'password': password,
        'fullName': fullName.trim(),
        'role': role,
        'phoneNumber': phoneNumber?.trim(),
      },
      fromJsonT: (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    return _request<LoginResponse>(
      'POST',
      ApiConstants.authLogin,
      requiresAuth: false,
      body: {
        'email': email.trim(),
        'password': password,
      },
      fromJsonT: (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<LoginResponse>> verifyOtp({
    required String email,
    required String code,
    required String type,
  }) async {
    return _request<LoginResponse>(
      'POST',
      ApiConstants.authVerifyOtp,
      requiresAuth: false,
      body: {
        'email': email.trim(),
        'code': code.trim(),
        'type': type,
      },
      fromJsonT: (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<String>> resendOtp({
    required String email,
    required String type,
  }) async {
    return _request<String>(
      'POST',
      ApiConstants.authResendOtp,
      requiresAuth: false,
      body: {
        'email': email.trim(),
        'type': type,
      },
      fromJsonT: (data) => data.toString(),
    );
  }

  Future<ApiResponse<UserInfoDto>> getProfile() async {
    return _request<UserInfoDto>(
      'GET',
      ApiConstants.authProfile,
      fromJsonT: (data) => UserInfoDto.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<UserInfoDto>> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? avatar,
    String? currentPassword,
    String? newPassword,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (avatar != null) body['avatar'] = avatar;
    if (currentPassword != null) body['currentPassword'] = currentPassword;
    if (newPassword != null) body['newPassword'] = newPassword;

    return _request<UserInfoDto>(
      'PUT',
      ApiConstants.authProfile,
      body: body,
      fromJsonT: (data) => UserInfoDto.fromJson(data as Map<String, dynamic>),
    );
  }

  // ================= DASHBOARD =================
  Future<ApiResponse<AdminDashboardData>> getAdminDashboard() async {
    return _request<AdminDashboardData>(
      'GET',
      ApiConstants.dashboardAdmin,
      fromJsonT: (data) =>
          AdminDashboardData.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<TeacherDashboardData>> getTeacherDashboard(
      int teacherId) async {
    return _request<TeacherDashboardData>(
      'GET',
      '${ApiConstants.dashboardTeacher}/$teacherId',
      fromJsonT: (data) =>
          TeacherDashboardData.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<StudentDashboardData>> getStudentDashboard(
      int studentId) async {
    return _request<StudentDashboardData>(
      'GET',
      '${ApiConstants.dashboardStudent}/$studentId',
      fromJsonT: (data) =>
          StudentDashboardData.fromJson(data as Map<String, dynamic>),
    );
  }

  // ================= STUDENTS =================
  Future<ApiResponse<PagedResult<Student>>> getStudents({
    String? keyword,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }
    return _request<PagedResult<Student>>(
      'GET',
      ApiConstants.students,
      queryParams: queryParams,
      fromJsonT: (data) => PagedResult<Student>.fromJson(
        data as Map<String, dynamic>,
        (item) => Student.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  Future<ApiResponse<Student>> getStudentById(int id) async {
    return _request<Student>(
      'GET',
      '${ApiConstants.students}/$id',
      fromJsonT: (data) => Student.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Student>> createStudent(Student student) async {
    return _request<Student>(
      'POST',
      ApiConstants.students,
      body: student.toJson(),
      fromJsonT: (data) => Student.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Student>> updateStudent(int id, Student student) async {
    return _request<Student>(
      'PUT',
      '${ApiConstants.students}/$id',
      body: student.toJson(),
      fromJsonT: (data) => Student.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> deleteStudent(int id) async {
    return _request<dynamic>(
      'DELETE',
      '${ApiConstants.students}/$id',
    );
  }

  Future<ApiResponse<List<Student>>> getStudentsByClass(int classId) async {
    return _request<List<Student>>(
      'GET',
      '${ApiConstants.students}/by-class/$classId',
      fromJsonT: (data) {
        final list = data as List<dynamic>? ?? [];
        return list
            .map((item) => Student.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ================= TEACHERS =================
  Future<ApiResponse<PagedResult<Teacher>>> getTeachers({
    String? keyword,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }
    return _request<PagedResult<Teacher>>(
      'GET',
      ApiConstants.teachers,
      queryParams: queryParams,
      fromJsonT: (data) => PagedResult<Teacher>.fromJson(
        data as Map<String, dynamic>,
        (item) => Teacher.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  Future<ApiResponse<Teacher>> getTeacherById(int id) async {
    return _request<Teacher>(
      'GET',
      '${ApiConstants.teachers}/$id',
      fromJsonT: (data) => Teacher.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Teacher>> createTeacher(Teacher teacher) async {
    return _request<Teacher>(
      'POST',
      ApiConstants.teachers,
      body: teacher.toJson(),
      fromJsonT: (data) => Teacher.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Teacher>> updateTeacher(int id, Teacher teacher) async {
    return _request<Teacher>(
      'PUT',
      '${ApiConstants.teachers}/$id',
      body: teacher.toJson(),
      fromJsonT: (data) => Teacher.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> deleteTeacher(int id) async {
    return _request<dynamic>(
      'DELETE',
      '${ApiConstants.teachers}/$id',
    );
  }

  // ================= SUBJECTS =================
  Future<ApiResponse<PagedResult<Subject>>> getSubjects({
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }
    return _request<PagedResult<Subject>>(
      'GET',
      ApiConstants.subjects,
      queryParams: queryParams,
      fromJsonT: (data) => PagedResult<Subject>.fromJson(
        data as Map<String, dynamic>,
        (item) => Subject.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  Future<ApiResponse<Subject>> getSubjectById(int id) async {
    return _request<Subject>(
      'GET',
      '${ApiConstants.subjects}/$id',
      fromJsonT: (data) => Subject.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Subject>> createSubject(Subject subject) async {
    return _request<Subject>(
      'POST',
      ApiConstants.subjects,
      body: subject.toJson(),
      fromJsonT: (data) => Subject.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Subject>> updateSubject(int id, Subject subject) async {
    return _request<Subject>(
      'PUT',
      '${ApiConstants.subjects}/$id',
      body: subject.toJson(),
      fromJsonT: (data) => Subject.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> deleteSubject(int id) async {
    return _request<dynamic>(
      'DELETE',
      '${ApiConstants.subjects}/$id',
    );
  }

  // ================= CLASSROOMS =================
  Future<ApiResponse<PagedResult<ClassRoom>>> getClassRooms({
    int? teacherId,
    int? subjectId,
    String? keyword,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (teacherId != null) queryParams['teacherId'] = teacherId.toString();
    if (subjectId != null) queryParams['subjectId'] = subjectId.toString();
    if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;

    return _request<PagedResult<ClassRoom>>(
      'GET',
      ApiConstants.classrooms,
      queryParams: queryParams,
      fromJsonT: (data) => PagedResult<ClassRoom>.fromJson(
        data as Map<String, dynamic>,
        (item) => ClassRoom.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  Future<ApiResponse<ClassRoom>> getClassRoomById(int id) async {
    return _request<ClassRoom>(
      'GET',
      '${ApiConstants.classrooms}/$id',
      fromJsonT: (data) => ClassRoom.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ClassRoom>> createClassRoom(ClassRoom classRoom) async {
    return _request<ClassRoom>(
      'POST',
      ApiConstants.classrooms,
      body: classRoom.toJson(),
      fromJsonT: (data) => ClassRoom.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ClassRoom>> updateClassRoom(
      int id, ClassRoom classRoom) async {
    return _request<ClassRoom>(
      'PUT',
      '${ApiConstants.classrooms}/$id',
      body: classRoom.toJson(),
      fromJsonT: (data) => ClassRoom.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> deleteClassRoom(int id) async {
    return _request<dynamic>(
      'DELETE',
      '${ApiConstants.classrooms}/$id',
    );
  }

  Future<ApiResponse<dynamic>> enrollStudent(int classId, int studentId) async {
    return _request<dynamic>(
      'POST',
      '${ApiConstants.classrooms}/$classId/enroll',
      body: {'studentId': studentId},
    );
  }

  Future<ApiResponse<dynamic>> removeStudent(int classId, int studentId) async {
    return _request<dynamic>(
      'DELETE',
      '${ApiConstants.classrooms}/$classId/enroll/$studentId',
    );
  }

  // ================= ATTENDANCE =================
  Future<ApiResponse<AttendanceSession>> createSession(
      AttendanceSession session) async {
    return _request<AttendanceSession>(
      'POST',
      ApiConstants.attendanceSessions,
      body: session.toJson(),
      fromJsonT: (data) =>
          AttendanceSession.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AttendanceSession>> getSessionById(int sessionId) async {
    return _request<AttendanceSession>(
      'GET',
      '${ApiConstants.attendanceSessions}/$sessionId',
      fromJsonT: (data) =>
          AttendanceSession.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<AttendanceSession>>> getSessionsByClass(
      int classId) async {
    return _request<List<AttendanceSession>>(
      'GET',
      '${ApiConstants.attendanceSessions}/by-class/$classId',
      fromJsonT: (data) {
        final list = data as List<dynamic>? ?? [];
        return list
            .map((item) =>
                AttendanceSession.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<dynamic>> manualCheckIn({
    required int sessionId,
    required int studentId,
    required String status,
    String? note,
  }) async {
    return _request<dynamic>(
      'POST',
      '${ApiConstants.attendanceSessions}/$sessionId/check-in',
      body: {
        'studentId': studentId,
        'status': status,
        'note': note,
      },
    );
  }

  Future<ApiResponse<AttendanceRecord>> qrCheckIn({
    required int sessionId,
    required int studentId,
    required String qrCode,
    double? latitude,
    double? longitude,
  }) async {
    return _request<AttendanceRecord>(
      'POST',
      '${ApiConstants.attendanceSessions}/$sessionId/qr-checkin',
      body: {
        'studentId': studentId,
        'qrCode': qrCode,
        'latitude': latitude,
        'longitude': longitude,
      },
      fromJsonT: (data) =>
          AttendanceRecord.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AttendanceRecord>> wifiCheckIn({
    required int sessionId,
    required int studentId,
    required String wifiSSID,
    double? latitude,
    double? longitude,
  }) async {
    return _request<AttendanceRecord>(
      'POST',
      '${ApiConstants.attendanceSessions}/$sessionId/wifi-checkin',
      body: {
        'studentId': studentId,
        'wifiSSID': wifiSSID,
        'latitude': latitude,
        'longitude': longitude,
      },
      fromJsonT: (data) =>
          AttendanceRecord.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<StudentAttendanceHistoryItem>>>
      getStudentAttendanceHistory(int studentId) async {
    return _request<List<StudentAttendanceHistoryItem>>(
      'GET',
      '${ApiConstants.attendanceStudent}/$studentId',
      fromJsonT: (data) {
        final list = data as List<dynamic>? ?? [];
        return list
            .map((item) => StudentAttendanceHistoryItem.fromJson(
                item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<ClassAttendanceReport>> getClassAttendanceReport(
      int classId) async {
    return _request<ClassAttendanceReport>(
      'GET',
      '${ApiConstants.attendanceReport}/$classId',
      fromJsonT: (data) =>
          ClassAttendanceReport.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> updateRecordStatus({
    required int recordId,
    required String status,
    String? note,
  }) async {
    return _request<dynamic>(
      'PUT',
      '${ApiConstants.attendanceRecords}/$recordId',
      body: {
        'status': status,
        'note': note,
      },
    );
  }
}
