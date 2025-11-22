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
  final List<String> schedule; // e.g., ["Sun 10:00-11:30", "Tue 10:00-11:30"]
  final int maxStudents;
  final int credits;
  final DateTime createdAt;
  final EventCategory category;
  
  // Dynamic properties
  int enrolledCount;
  bool isJoined;
  bool isFavorite;
  List<String> enrolledStudents;
  List<CalendarEvent> events;

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
    this.enrolledStudents = const [],
    this.events = const [],
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
    List<String>? enrolledStudents,
    List<CalendarEvent>? events,
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
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      events: events ?? this.events,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'instructor': instructor,
      'location': location,
      'createdBy': createdBy,
      'type': type.index,
      'schedule': schedule,
      'maxStudents': maxStudents,
      'credits': credits,
      'createdAt': createdAt.toIso8601String(),
      'category': category.index,
      'enrolledCount': enrolledCount,
      'isJoined': isJoined,
      'isFavorite': isFavorite,
      'enrolledStudents': enrolledStudents,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      instructor: json['instructor'],
      location: json['location'],
      createdBy: json['createdBy'],
      type: ClassType.values[json['type']],
      schedule: List<String>.from(json['schedule']),
      maxStudents: json['maxStudents'],
      credits: json['credits'] ?? 3,
      createdAt: DateTime.parse(json['createdAt']),
      category: EventCategory.values[json['category'] ?? 0],
      enrolledCount: json['enrolledCount'] ?? 0,
      isJoined: json['isJoined'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      enrolledStudents: List<String>.from(json['enrolledStudents'] ?? []),
    );
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
  
  // Dynamic properties
  List<String> attendees;
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
    this.attendees = const [],
    this.isGoing = false,
  });

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    EventType? type,
    String? addedBy,
    String? classId,
    EventCategory? category,
    bool? isPublic,
    List<String>? attendees,
    bool? isGoing,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      addedBy: addedBy ?? this.addedBy,
      classId: classId ?? this.classId,
      category: category ?? this.category,
      isPublic: isPublic ?? this.isPublic,
      attendees: attendees ?? this.attendees,
      isGoing: isGoing ?? this.isGoing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type.index,
      'addedBy': addedBy,
      'classId': classId,
      'category': category.index,
      'isPublic': isPublic,
      'attendees': attendees,
      'isGoing': isGoing,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      type: EventType.values[json['type']],
      addedBy: json['addedBy'],
      classId: json['classId'],
      category: EventCategory.values[json['category'] ?? 0],
      isPublic: json['isPublic'] ?? true,
      attendees: List<String>.from(json['attendees'] ?? []),
      isGoing: json['isGoing'] ?? false,
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
