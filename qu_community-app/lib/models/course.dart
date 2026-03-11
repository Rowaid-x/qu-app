enum ClassType {
  official,
  studentCreated,
}

enum EventCategory {
  academic,
  social,
  sports,
  creative,
  career,
  food,
  other,
}

class Course {
  final String id;
  final String name;
  final String description;
  final String instructor;
  final String location;
  final String createdBy;
  final ClassType type;
  final List<String> schedule;
  final int maxStudents;
  final int credits;
  final DateTime createdAt;
  final EventCategory category;

  int enrolledCount;
  bool isJoined;
  bool isFavorite;

  Course({
    required this.id,
    required this.name,
    required this.description,
    required this.instructor,
    required this.location,
    required this.createdBy,
    required this.type,
    required this.schedule,
    required this.maxStudents,
    this.credits = 3,
    required this.createdAt,
    this.category = EventCategory.academic,
    this.enrolledCount = 0,
    this.isJoined = false,
    this.isFavorite = false,
  });

  Course copyWith({
    String? id,
    String? name,
    String? description,
    String? instructor,
    String? location,
    String? createdBy,
    ClassType? type,
    List<String>? schedule,
    int? maxStudents,
    int? credits,
    DateTime? createdAt,
    EventCategory? category,
    int? enrolledCount,
    bool? isJoined,
    bool? isFavorite,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      instructor: instructor ?? this.instructor,
      location: location ?? this.location,
      createdBy: createdBy ?? this.createdBy,
      type: type ?? this.type,
      schedule: schedule ?? this.schedule,
      maxStudents: maxStudents ?? this.maxStudents,
      credits: credits ?? this.credits,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      isJoined: isJoined ?? this.isJoined,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  static ClassType _parseClassType(String? value) {
    switch (value) {
      case 'official':
        return ClassType.official;
      case 'student_created':
        return ClassType.studentCreated;
      default:
        return ClassType.official;
    }
  }

  static EventCategory _parseCategory(String? value) {
    switch (value) {
      case 'academic':
        return EventCategory.academic;
      case 'social':
        return EventCategory.social;
      case 'sports':
        return EventCategory.sports;
      case 'creative':
        return EventCategory.creative;
      case 'career':
        return EventCategory.career;
      case 'food':
        return EventCategory.food;
      default:
        return EventCategory.other;
    }
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      instructor: json['instructor'] ?? '',
      location: json['location'] ?? '',
      createdBy: json['created_by_email'] ?? 'system',
      type: _parseClassType(json['class_type']),
      schedule: List<String>.from(json['schedule'] ?? []),
      maxStudents: json['max_students'] ?? 60,
      credits: json['credits'] ?? 3,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      category: _parseCategory(json['category']),
      enrolledCount: json['enrolled_count'] ?? 0,
      isJoined: json['is_joined'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  String get categoryString {
    switch (category) {
      case EventCategory.academic:
        return 'academic';
      case EventCategory.social:
        return 'social';
      case EventCategory.sports:
        return 'sports';
      case EventCategory.creative:
        return 'creative';
      case EventCategory.career:
        return 'career';
      case EventCategory.food:
        return 'food';
      case EventCategory.other:
        return 'other';
    }
  }
}

enum EventType {
  classSession,
  assignment,
  exam,
  studyGroup,
  campusEvent,
  socialEvent,
  other,
}

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final EventType type;
  final String addedBy;
  final String? classId;
  final EventCategory category;
  final bool isPublic;
  final int attendeeCount;
  bool isGoing;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.addedBy,
    this.classId,
    this.category = EventCategory.academic,
    this.isPublic = true,
    this.attendeeCount = 0,
    this.isGoing = false,
  });

  static EventType _parseEventType(String? value) {
    switch (value) {
      case 'class_session':
        return EventType.classSession;
      case 'assignment':
        return EventType.assignment;
      case 'exam':
        return EventType.exam;
      case 'study_group':
        return EventType.studyGroup;
      case 'campus_event':
        return EventType.campusEvent;
      case 'social_event':
        return EventType.socialEvent;
      default:
        return EventType.other;
    }
  }

  static String eventTypeToString(EventType type) {
    switch (type) {
      case EventType.classSession:
        return 'class_session';
      case EventType.assignment:
        return 'assignment';
      case EventType.exam:
        return 'exam';
      case EventType.studyGroup:
        return 'study_group';
      case EventType.campusEvent:
        return 'campus_event';
      case EventType.socialEvent:
        return 'social_event';
      case EventType.other:
        return 'other';
    }
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      type: _parseEventType(json['event_type']),
      addedBy: json['added_by_email'] ?? 'system',
      classId: json['course_id'],
      category: Course._parseCategory(json['category']),
      isPublic: json['is_public'] ?? true,
      attendeeCount: json['attendee_count'] ?? 0,
      isGoing: json['is_going'] ?? false,
    );
  }

  Duration get duration => endTime.difference(startTime);

  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
           startTime.month == now.month &&
           startTime.day == now.day;
  }

  bool get isUpcoming => startTime.isAfter(DateTime.now());
}
