class AttendanceSession {
  final int id;
  final int classRoomId;
  final String className;
  final String subjectName;
  final int teacherId;
  final String teacherName;
  final DateTime sessionDate;
  final String startTime;
  final String endTime;
  final String? qrCode;
  final double? latitude;
  final double? longitude;
  final String? wifiSSID;
  final String? note;
  final bool isActive;
  final DateTime? createdAt;
  final int totalStudents;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int excusedCount;

  AttendanceSession({
    required this.id,
    required this.classRoomId,
    this.className = '',
    this.subjectName = '',
    required this.teacherId,
    this.teacherName = '',
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    this.qrCode,
    this.latitude,
    this.longitude,
    this.wifiSSID,
    this.note,
    this.isActive = true,
    this.createdAt,
    this.totalStudents = 0,
    this.presentCount = 0,
    this.lateCount = 0,
    this.absentCount = 0,
    this.excusedCount = 0,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'] as int? ?? 0,
      classRoomId: json['classRoomId'] as int? ?? 0,
      className: json['className'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      teacherId: json['teacherId'] as int? ?? 0,
      teacherName: json['teacherName'] as String? ?? '',
      sessionDate: json['sessionDate'] != null
          ? DateTime.tryParse(json['sessionDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      qrCode: json['qrCode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      wifiSSID: json['wifiSSID'] as String?,
      note: json['note'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      totalStudents: json['totalStudents'] as int? ?? 0,
      presentCount: json['presentCount'] as int? ?? 0,
      lateCount: json['lateCount'] as int? ?? 0,
      absentCount: json['absentCount'] as int? ?? 0,
      excusedCount: json['excusedCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classRoomId': classRoomId,
      'teacherId': teacherId,
      'sessionDate': sessionDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'qrCode': qrCode,
      'latitude': latitude,
      'longitude': longitude,
      'wifiSSID': wifiSSID,
      'note': note,
      'isActive': isActive,
    };
  }
}

class AttendanceRecord {
  final int id;
  final int sessionId;
  final int studentId;
  final String studentCode;
  final String studentName;
  final String? studentAvatar;
  final DateTime checkInTime;
  final String method;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    this.studentCode = '',
    this.studentName = '',
    this.studentAvatar,
    required this.checkInTime,
    required this.method,
    required this.status,
    this.latitude,
    this.longitude,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as int? ?? 0,
      sessionId: json['sessionId'] as int? ?? 0,
      studentId: json['studentId'] as int? ?? 0,
      studentCode: json['studentCode'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      studentAvatar: json['studentAvatar'] as String?,
      checkInTime: json['checkInTime'] != null
          ? DateTime.tryParse(json['checkInTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      method: json['method'] as String? ?? 'MANUAL',
      status: json['status'] as String? ?? 'PRESENT',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

class StudentAttendanceHistoryItem {
  final int recordId;
  final int sessionId;
  final String className;
  final String subjectName;
  final DateTime sessionDate;
  final DateTime checkInTime;
  final String method;
  final String status;
  final String? note;

  StudentAttendanceHistoryItem({
    required this.recordId,
    required this.sessionId,
    required this.className,
    required this.subjectName,
    required this.sessionDate,
    required this.checkInTime,
    required this.method,
    required this.status,
    this.note,
  });

  factory StudentAttendanceHistoryItem.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceHistoryItem(
      recordId: json['recordId'] as int? ?? 0,
      sessionId: json['sessionId'] as int? ?? 0,
      className: json['className'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      sessionDate: json['sessionDate'] != null
          ? DateTime.tryParse(json['sessionDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      checkInTime: json['checkInTime'] != null
          ? DateTime.tryParse(json['checkInTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      method: json['method'] as String? ?? '',
      status: json['status'] as String? ?? 'PRESENT',
      note: json['note'] as String?,
    );
  }
}

class StudentAttendanceSummary {
  final int studentId;
  final String studentCode;
  final String studentName;
  final int totalSessions;
  final int presentSessions;
  final int lateSessions;
  final int absentSessions;
  final int excusedSessions;
  final double attendanceRate;

  StudentAttendanceSummary({
    required this.studentId,
    required this.studentCode,
    required this.studentName,
    required this.totalSessions,
    required this.presentSessions,
    required this.lateSessions,
    required this.absentSessions,
    required this.excusedSessions,
    required this.attendanceRate,
  });

  factory StudentAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceSummary(
      studentId: json['studentId'] as int? ?? 0,
      studentCode: json['studentCode'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      totalSessions: json['totalSessions'] as int? ?? 0,
      presentSessions: json['presentSessions'] as int? ?? 0,
      lateSessions: json['lateSessions'] as int? ?? 0,
      absentSessions: json['absentSessions'] as int? ?? 0,
      excusedSessions: json['excusedSessions'] as int? ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ClassAttendanceReport {
  final int classRoomId;
  final String className;
  final String subjectName;
  final int totalSessions;
  final int totalStudents;
  final List<StudentAttendanceSummary> studentsSummary;

  ClassAttendanceReport({
    required this.classRoomId,
    required this.className,
    required this.subjectName,
    required this.totalSessions,
    required this.totalStudents,
    required this.studentsSummary,
  });

  factory ClassAttendanceReport.fromJson(Map<String, dynamic> json) {
    final list = json['studentsSummary'] as List<dynamic>? ?? [];
    return ClassAttendanceReport(
      classRoomId: json['classRoomId'] as int? ?? 0,
      className: json['className'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      totalSessions: json['totalSessions'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      studentsSummary: list
          .map((item) =>
              StudentAttendanceSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
