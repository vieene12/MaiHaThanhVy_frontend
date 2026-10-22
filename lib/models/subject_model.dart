class Subject {
  final int id;
  final String subjectCode;
  final String subjectName;
  final int credits;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int totalClassesCount;

  Subject({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.credits,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.totalClassesCount = 0,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as int? ?? 0,
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      credits: json['credits'] as int? ?? 3,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      totalClassesCount: json['totalClassesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'credits': credits,
      'description': description,
      'isActive': isActive,
    };
  }
}
