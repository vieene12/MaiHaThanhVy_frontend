class Student {
  final int id;
  final String studentCode;
  final String fullName;
  final String email;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phoneNumber;
  final String? address;
  final String? avatar;
  final String? major;
  final int? userId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int enrolledClassesCount;
  final bool hasFaceData;

  Student({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.email,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.address,
    this.avatar,
    this.major,
    this.userId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.enrolledClassesCount = 0,
    this.hasFaceData = false,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int? ?? 0,
      studentCode: json['studentCode'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      gender: json['gender'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      avatar: json['avatar'] as String?,
      major: json['major'] as String?,
      userId: json['userId'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      enrolledClassesCount: json['enrolledClassesCount'] as int? ?? 0,
      hasFaceData: json['hasFaceData'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentCode': studentCode,
      'fullName': fullName,
      'email': email,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'phoneNumber': phoneNumber,
      'address': address,
      'major': major,
      'userId': userId,
      'isActive': isActive,
    };
  }
}
