class UserInfoDto {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final String? phoneNumber;
  final String? avatar;
  final bool isEmailVerified;
  final bool hasFaceData;
  final int? studentId;
  final int? teacherId;

  UserInfoDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.avatar,
    this.isEmailVerified = false,
    this.hasFaceData = false,
    this.studentId,
    this.teacherId,
  });

  factory UserInfoDto.fromJson(Map<String, dynamic> json) {
    return UserInfoDto(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: (json['role'] as String? ?? 'STUDENT').toUpperCase(),
      phoneNumber: json['phoneNumber'] as String?,
      avatar: json['avatar'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      hasFaceData: json['hasFaceData'] as bool? ?? false,
      studentId: json['studentId'] as int?,
      teacherId: json['teacherId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'isEmailVerified': isEmailVerified,
      'hasFaceData': hasFaceData,
      'studentId': studentId,
      'teacherId': teacherId,
    };
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isTeacher => role == 'TEACHER';
  bool get isStudent => role == 'STUDENT';
}

class LoginResponse {
  final String? token;
  final UserInfoDto? user;
  final String? role;
  final bool requiresOtp;
  final String? otpType;

  LoginResponse({
    this.token,
    this.user,
    this.role,
    this.requiresOtp = false,
    this.otpType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String?,
      user: json['user'] != null
          ? UserInfoDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      role: json['role'] as String?,
      requiresOtp: json['requiresOtp'] as bool? ?? false,
      otpType: json['otpType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user?.toJson(),
      'role': role,
      'requiresOtp': requiresOtp,
      'otpType': otpType,
    };
  }
}
