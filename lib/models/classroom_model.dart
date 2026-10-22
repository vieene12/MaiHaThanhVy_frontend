class ClassRoom {
  final int id;
  final String className;
  final int subjectId;
  final String subjectCode;
  final String subjectName;
  final int credits;
  final int teacherId;
  final String teacherName;
  final String teacherEmail;
  final String? room;
  final String? semester;
  final String? schedule;
  final int maxStudents;
  final int enrolledStudentsCount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClassRoom({
    required this.id,
    required this.className,
    required this.subjectId,
    this.subjectCode = '',
    this.subjectName = '',
    this.credits = 0,
    required this.teacherId,
    this.teacherName = '',
    this.teacherEmail = '',
    this.room,
    this.semester,
    this.schedule,
    this.maxStudents = 50,
    this.enrolledStudentsCount = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ClassRoom.fromJson(Map<String, dynamic> json) {
    return ClassRoom(
      id: json['id'] as int? ?? 0,
      className: json['className'] as String? ?? '',
      subjectId: json['subjectId'] as int? ?? 0,
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      credits: json['credits'] as int? ?? 0,
      teacherId: json['teacherId'] as int? ?? 0,
      teacherName: json['teacherName'] as String? ?? '',
      teacherEmail: json['teacherEmail'] as String? ?? '',
      room: json['room'] as String?,
      semester: json['semester'] as String?,
      schedule: json['schedule'] as String?,
      maxStudents: json['maxStudents'] as int? ?? 50,
      enrolledStudentsCount: json['enrolledStudentsCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'room': room,
      'semester': semester,
      'schedule': schedule,
      'maxStudents': maxStudents,
      'isActive': isActive,
    };
  }
}
