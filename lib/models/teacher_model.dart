class Teacher {
  final int id;
  final String teacherCode;
  final String fullName;
  final String email;
  final String? department;
  final int? userId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int assignedClassesCount;

  Teacher({
    required this.id,
    required this.teacherCode,
    required this.fullName,
    required this.email,
    this.department,
    this.userId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.assignedClassesCount = 0,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as int? ?? 0,
      teacherCode: json['teacherCode'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      department: json['department'] as String?,
      userId: json['userId'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      assignedClassesCount: json['assignedClassesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teacherCode': teacherCode,
      'fullName': fullName,
      'email': email,
      'department': department,
      'userId': userId,
      'isActive': isActive,
    };
  }
}
