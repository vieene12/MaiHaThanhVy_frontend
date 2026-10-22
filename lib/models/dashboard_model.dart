class RecentActivity {
  final String type;
  final String description;
  final DateTime timestamp;

  RecentActivity({
    required this.type,
    required this.description,
    required this.timestamp,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'] as String? ?? 'ATTENDANCE',
      description: json['description'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AdminDashboardData {
  final int totalUsers;
  final int totalStudents;
  final int totalTeachers;
  final int totalSubjects;
  final int totalClasses;
  final int totalSessionsToday;
  final int totalAttendanceRecordsToday;
  final double averageAttendanceRate;
  final List<RecentActivity> recentActivities;

  AdminDashboardData({
    required this.totalUsers,
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalSubjects,
    required this.totalClasses,
    required this.totalSessionsToday,
    required this.totalAttendanceRecordsToday,
    required this.averageAttendanceRate,
    required this.recentActivities,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final list = json['recentActivities'] as List<dynamic>? ?? [];
    return AdminDashboardData(
      totalUsers: json['totalUsers'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      totalTeachers: json['totalTeachers'] as int? ?? 0,
      totalSubjects: json['totalSubjects'] as int? ?? 0,
      totalClasses: json['totalClasses'] as int? ?? 0,
      totalSessionsToday: json['totalSessionsToday'] as int? ?? 0,
      totalAttendanceRecordsToday:
          json['totalAttendanceRecordsToday'] as int? ?? 0,
      averageAttendanceRate:
          (json['averageAttendanceRate'] as num?)?.toDouble() ?? 0.0,
      recentActivities: list
          .map((item) =>
              RecentActivity.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TeacherClassSummary {
  final int classRoomId;
  final String className;
  final String subjectName;
  final int studentCount;
  final int sessionCount;

  TeacherClassSummary({
    required this.classRoomId,
    required this.className,
    required this.subjectName,
    required this.studentCount,
    required this.sessionCount,
  });

  factory TeacherClassSummary.fromJson(Map<String, dynamic> json) {
    return TeacherClassSummary(
      classRoomId: json['classRoomId'] as int? ?? 0,
      className: json['className'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      studentCount: json['studentCount'] as int? ?? 0,
      sessionCount: json['sessionCount'] as int? ?? 0,
    );
  }
}

class RecentSession {
  final int sessionId;
  final String className;
  final DateTime sessionDate;
  final int presentCount;
  final int totalStudents;

  RecentSession({
    required this.sessionId,
    required this.className,
    required this.sessionDate,
    required this.presentCount,
    required this.totalStudents,
  });

  factory RecentSession.fromJson(Map<String, dynamic> json) {
    return RecentSession(
      sessionId: json['sessionId'] as int? ?? 0,
      className: json['className'] as String? ?? '',
      sessionDate: json['sessionDate'] != null
          ? DateTime.tryParse(json['sessionDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      presentCount: json['presentCount'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
    );
  }
}

class TeacherDashboardData {
  final int teacherId;
  final String teacherName;
  final int totalClasses;
  final int totalStudents;
  final int totalSessions;
  final int todaySessionsCount;
  final double overallAttendanceRate;
  final List<TeacherClassSummary> classes;
  final List<RecentSession> recentSessions;

  TeacherDashboardData({
    required this.teacherId,
    required this.teacherName,
    required this.totalClasses,
    required this.totalStudents,
    required this.totalSessions,
    required this.todaySessionsCount,
    required this.overallAttendanceRate,
    required this.classes,
    required this.recentSessions,
  });

  factory TeacherDashboardData.fromJson(Map<String, dynamic> json) {
    final classList = json['classes'] as List<dynamic>? ?? [];
    final sessionList = json['recentSessions'] as List<dynamic>? ?? [];
    return TeacherDashboardData(
      teacherId: json['teacherId'] as int? ?? 0,
      teacherName: json['teacherName'] as String? ?? '',
      totalClasses: json['totalClasses'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      totalSessions: json['totalSessions'] as int? ?? 0,
      todaySessionsCount: json['todaySessionsCount'] as int? ?? 0,
      overallAttendanceRate:
          (json['overallAttendanceRate'] as num?)?.toDouble() ?? 0.0,
      classes: classList
          .map((item) =>
              TeacherClassSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentSessions: sessionList
          .map((item) => RecentSession.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentClassAttendance {
  final int classRoomId;
  final String className;
  final String subjectName;
  final int totalSessions;
  final int attendedSessions;
  final double attendanceRate;

  StudentClassAttendance({
    required this.classRoomId,
    required this.className,
    required this.subjectName,
    required this.totalSessions,
    required this.attendedSessions,
    required this.attendanceRate,
  });

  factory StudentClassAttendance.fromJson(Map<String, dynamic> json) {
    return StudentClassAttendance(
      classRoomId: json['classRoomId'] as int? ?? 0,
      className: json['className'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      totalSessions: json['totalSessions'] as int? ?? 0,
      attendedSessions: json['attendedSessions'] as int? ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StudentDashboardData {
  final int studentId;
  final String studentName;
  final String studentCode;
  final int enrolledClassesCount;
  final int totalSessions;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int excusedCount;
  final double attendanceRate;
  final List<StudentClassAttendance> enrolledClasses;

  StudentDashboardData({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.enrolledClassesCount,
    required this.totalSessions,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.excusedCount,
    required this.attendanceRate,
    required this.enrolledClasses,
  });

  factory StudentDashboardData.fromJson(Map<String, dynamic> json) {
    final list = json['enrolledClasses'] as List<dynamic>? ?? [];
    return StudentDashboardData(
      studentId: json['studentId'] as int? ?? 0,
      studentName: json['studentName'] as String? ?? '',
      studentCode: json['studentCode'] as String? ?? '',
      enrolledClassesCount: json['enrolledClassesCount'] as int? ?? 0,
      totalSessions: json['totalSessions'] as int? ?? 0,
      presentCount: json['presentCount'] as int? ?? 0,
      lateCount: json['lateCount'] as int? ?? 0,
      absentCount: json['absentCount'] as int? ?? 0,
      excusedCount: json['excusedCount'] as int? ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
      enrolledClasses: list
          .map((item) =>
              StudentClassAttendance.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
