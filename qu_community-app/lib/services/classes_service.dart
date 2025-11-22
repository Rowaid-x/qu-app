import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/course.dart';
import 'auth_service.dart';

class ClassesService {
  static const String _coursesKey = 'courses';
  static const String _eventsKey = 'calendar_events';
  static const String _joinedClassesKey = 'joined_classes';
  static const String _favoriteClassesKey = 'favorite_classes';

  // Get all available courses
  static Future<List<Course>> getAllCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getStringList(_coursesKey) ?? [];
    
    if (coursesJson.isEmpty) {
      // Initialize with sample data if empty
      await _initializeSampleData();
      return getAllCourses();
    }
    
    final courses = coursesJson.map((json) => Course.fromJson(jsonDecode(json))).toList();
    
    // Update joined and favorite status for current user
    final currentUser = await AuthService.getCurrentUserEmail();
    if (currentUser != null) {
      final joinedClasses = await getJoinedClassIds();
      final favoriteClasses = await getFavoriteClassIds();
      
      for (int i = 0; i < courses.length; i++) {
        courses[i] = courses[i].copyWith(
          isJoined: joinedClasses.contains(courses[i].id),
          isFavorite: favoriteClasses.contains(courses[i].id),
        );
      }
    }
    
    return courses;
  }

  // Get joined courses for current user
  static Future<List<Course>> getJoinedCourses() async {
    final allCourses = await getAllCourses();
    return allCourses.where((course) => course.isJoined).toList();
  }

  // Get favorite courses for current user
  static Future<List<Course>> getFavoriteCourses() async {
    final allCourses = await getAllCourses();
    return allCourses.where((course) => course.isFavorite).toList();
  }

  // Join a class
  static Future<bool> joinClass(String classId) async {
    try {
      final currentUser = await AuthService.getCurrentUserEmail();
      if (currentUser == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final joinedClasses = prefs.getStringList('${_joinedClassesKey}_$currentUser') ?? [];
      
      if (!joinedClasses.contains(classId)) {
        joinedClasses.add(classId);
        await prefs.setStringList('${_joinedClassesKey}_$currentUser', joinedClasses);
        
        // Update course enrollment count
        await _updateCourseEnrollment(classId, 1);
        
        // Add class events to calendar
        await _addClassEventsToCalendar(classId);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Leave a class
  static Future<bool> leaveClass(String classId) async {
    try {
      final currentUser = await AuthService.getCurrentUserEmail();
      if (currentUser == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final joinedClasses = prefs.getStringList('${_joinedClassesKey}_$currentUser') ?? [];
      
      if (joinedClasses.contains(classId)) {
        joinedClasses.remove(classId);
        await prefs.setStringList('${_joinedClassesKey}_$currentUser', joinedClasses);
        
        // Update course enrollment count
        await _updateCourseEnrollment(classId, -1);
        
        // Remove class events from calendar
        await _removeClassEventsFromCalendar(classId);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Toggle favorite status
  static Future<bool> toggleFavorite(String classId) async {
    try {
      final currentUser = await AuthService.getCurrentUserEmail();
      if (currentUser == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final favoriteClasses = prefs.getStringList('${_favoriteClassesKey}_$currentUser') ?? [];
      
      if (favoriteClasses.contains(classId)) {
        favoriteClasses.remove(classId);
      } else {
        favoriteClasses.add(classId);
      }
      
      await prefs.setStringList('${_favoriteClassesKey}_$currentUser', favoriteClasses);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Create a new class
  static Future<bool> createClass({
    required String name,
    required String description,
    required String location,
    required List<String> schedule,
    required int maxStudents,
    required EventCategory category,
    int credits = 3,
  }) async {
    try {
      final currentUser = await AuthService.getCurrentUserEmail();
      if (currentUser == null) return false;

      final course = Course(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        instructor: currentUser,
        location: location,
        createdBy: currentUser,
        type: ClassType.studentCreated,
        schedule: schedule,
        maxStudents: maxStudents,
        credits: credits,
        createdAt: DateTime.now(),
        category: category,
      );

      final prefs = await SharedPreferences.getInstance();
      final coursesJson = prefs.getStringList(_coursesKey) ?? [];
      coursesJson.add(jsonEncode(course.toJson()));
      await prefs.setStringList(_coursesKey, coursesJson);

      // Automatically join the class as creator
      await joinClass(course.id);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get all calendar events
  static Future<List<CalendarEvent>> getAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getStringList(_eventsKey) ?? [];
    
    final events = eventsJson.map((json) => CalendarEvent.fromJson(jsonDecode(json))).toList();
    
    // Update going status for current user
    final currentUser = await AuthService.getCurrentUserEmail();
    if (currentUser != null) {
      for (int i = 0; i < events.length; i++) {
        events[i] = events[i].copyWith(
          isGoing: events[i].attendees.contains(currentUser),
        );
      }
    }
    
    return events;
  }

  // Get events for today
  static Future<List<CalendarEvent>> getTodayEvents() async {
    final allEvents = await getAllEvents();
    return allEvents.where((event) => event.isToday).toList();
  }

  // Get events for joined classes
  static Future<List<CalendarEvent>> getMyClassEvents() async {
    final joinedClassIds = await getJoinedClassIds();
    final allEvents = await getAllEvents();
    return allEvents.where((event) => 
      event.classId != null && joinedClassIds.contains(event.classId)
    ).toList();
  }

  // Add event to calendar
  static Future<bool> addEvent(CalendarEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList(_eventsKey) ?? [];
      eventsJson.add(jsonEncode(event.toJson()));
      await prefs.setStringList(_eventsKey, eventsJson);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Toggle event attendance
  static Future<bool> toggleEventAttendance(String eventId) async {
    try {
      final currentUser = await AuthService.getCurrentUserEmail();
      if (currentUser == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList(_eventsKey) ?? [];
      
      for (int i = 0; i < eventsJson.length; i++) {
        final event = CalendarEvent.fromJson(jsonDecode(eventsJson[i]));
        if (event.id == eventId) {
          final attendees = List<String>.from(event.attendees);
          if (attendees.contains(currentUser)) {
            attendees.remove(currentUser);
          } else {
            attendees.add(currentUser);
          }
          
          final updatedEvent = event.copyWith(attendees: attendees);
          eventsJson[i] = jsonEncode(updatedEvent.toJson());
          break;
        }
      }
      
      await prefs.setStringList(_eventsKey, eventsJson);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper methods
  static Future<List<String>> getJoinedClassIds() async {
    final currentUser = await AuthService.getCurrentUserEmail();
    if (currentUser == null) return [];
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${_joinedClassesKey}_$currentUser') ?? [];
  }

  static Future<List<String>> getFavoriteClassIds() async {
    final currentUser = await AuthService.getCurrentUserEmail();
    if (currentUser == null) return [];
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${_favoriteClassesKey}_$currentUser') ?? [];
  }

  static Future<void> _updateCourseEnrollment(String classId, int change) async {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getStringList(_coursesKey) ?? [];
    
    for (int i = 0; i < coursesJson.length; i++) {
      final course = Course.fromJson(jsonDecode(coursesJson[i]));
      if (course.id == classId) {
        final updatedCourse = course.copyWith(
          enrolledCount: (course.enrolledCount + change).clamp(0, course.maxStudents),
        );
        coursesJson[i] = jsonEncode(updatedCourse.toJson());
        break;
      }
    }
    
    await prefs.setStringList(_coursesKey, coursesJson);
  }

  static Future<void> _addClassEventsToCalendar(String classId) async {
    final courses = await getAllCourses();
    final course = courses.firstWhere((c) => c.id == classId);
    
    // Add recurring class sessions for the next 4 months
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 120));
    
    for (final scheduleItem in course.schedule) {
      final parts = scheduleItem.split(' ');
      if (parts.length >= 2) {
        final dayName = parts[0]; // e.g., "Sun", "Mon"
        final timeRange = parts[1]; // e.g., "10:00-11:30"
        
        // Generate recurring events
        DateTime currentDate = _getNextWeekday(now, dayName);
        while (currentDate.isBefore(endDate)) {
          final times = timeRange.split('-');
          if (times.length == 2) {
            final startTime = _parseTime(currentDate, times[0]);
            final endTime = _parseTime(currentDate, times[1]);
            
            final event = CalendarEvent(
              id: '${classId}_${currentDate.millisecondsSinceEpoch}',
              title: course.name,
              description: 'Class session',
              location: course.location,
              startTime: startTime,
              endTime: endTime,
              type: EventType.classSession,
              addedBy: 'system',
              classId: classId,
              category: course.category,
            );
            
            await addEvent(event);
          }
          
          currentDate = currentDate.add(const Duration(days: 7));
        }
      }
    }
  }

  static Future<void> _removeClassEventsFromCalendar(String classId) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getStringList(_eventsKey) ?? [];
    
    final filteredEvents = eventsJson.where((eventJson) {
      final event = CalendarEvent.fromJson(jsonDecode(eventJson));
      return event.classId != classId;
    }).toList();
    
    await prefs.setStringList(_eventsKey, filteredEvents);
  }

  static DateTime _getNextWeekday(DateTime date, String dayName) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final targetDay = weekdays.indexOf(dayName) + 1;
    final currentDay = date.weekday;
    
    int daysToAdd = targetDay - currentDay;
    if (daysToAdd <= 0) daysToAdd += 7;
    
    return date.add(Duration(days: daysToAdd));
  }

  static DateTime _parseTime(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  // Initialize sample data
  static Future<void> _initializeSampleData() async {
    final sampleCourses = [
      // Official QU Classes
      Course(
        id: 'cmps251',
        name: 'Data Structures',
        description: 'Introduction to data structures and algorithms including arrays, linked lists, stacks, queues, trees, and graphs.',
        instructor: 'Dr. Ahmed Hassan',
        location: 'Building B, Room 101',
        createdBy: 'system',
        type: ClassType.official,
        schedule: ['Sun 10:00-11:30', 'Tue 10:00-11:30', 'Thu 10:00-11:30'],
        maxStudents: 60,
        credits: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        category: EventCategory.academic,
        enrolledCount: 45,
      ),
      Course(
        id: 'math101',
        name: 'Calculus I',
        description: 'Differential and integral calculus of functions of one variable.',
        instructor: 'Dr. Fatima Al-Zahra',
        location: 'Building A, Room 205',
        createdBy: 'system',
        type: ClassType.official,
        schedule: ['Mon 14:00-15:30', 'Wed 14:00-15:30'],
        maxStudents: 80,
        credits: 4,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        category: EventCategory.academic,
        enrolledCount: 72,
      ),
      Course(
        id: 'engl110',
        name: 'Academic Writing',
        description: 'Development of academic writing skills including research, citation, and argumentation.',
        instructor: 'Prof. John Smith',
        location: 'Building C, Room 301',
        createdBy: 'system',
        type: ClassType.official,
        schedule: ['Tue 16:00-17:30', 'Thu 16:00-17:30'],
        maxStudents: 25,
        credits: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        category: EventCategory.academic,
        enrolledCount: 23,
      ),
      Course(
        id: 'phys201',
        name: 'General Physics',
        description: 'Mechanics, thermodynamics, and wave motion with laboratory component.',
        instructor: 'Dr. Omar Khalil',
        location: 'Physics Lab, Room 150',
        createdBy: 'system',
        type: ClassType.official,
        schedule: ['Mon 10:00-12:00', 'Wed 10:00-12:00'],
        maxStudents: 40,
        credits: 4,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        category: EventCategory.academic,
        enrolledCount: 38,
      ),
      
      // Student-Created Classes
      Course(
        id: 'js_study',
        name: 'JavaScript Study Group',
        description: 'Weekly study sessions covering modern JavaScript, ES6+, and web development frameworks.',
        instructor: 'Sarah Al-Mahmoud',
        location: 'Library, Study Room 201',
        createdBy: 'sarah.mahmoud@qu.edu.qa',
        type: ClassType.studentCreated,
        schedule: ['Wed 16:00-18:00'],
        maxStudents: 20,
        credits: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        category: EventCategory.academic,
        enrolledCount: 12,
      ),
      Course(
        id: 'arabic_tutor',
        name: 'Arabic Tutoring Sessions',
        description: 'Help with Arabic grammar, literature, and conversation for international students.',
        instructor: 'Mohammed Al-Rashid',
        location: 'Student Center, Room 105',
        createdBy: 'mohammed.rashid@qu.edu.qa',
        type: ClassType.studentCreated,
        schedule: ['Sat 14:00-16:00', 'Sun 14:00-16:00'],
        maxStudents: 15,
        credits: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        category: EventCategory.academic,
        enrolledCount: 8,
      ),
      Course(
        id: 'photo_workshop',
        name: 'Photography Workshop',
        description: 'Learn digital photography techniques, composition, and photo editing.',
        instructor: 'Layla Al-Thani',
        location: 'Art Building, Studio 3',
        createdBy: 'layla.thani@qu.edu.qa',
        type: ClassType.studentCreated,
        schedule: ['Fri 15:00-17:00'],
        maxStudents: 12,
        credits: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        category: EventCategory.creative,
        enrolledCount: 9,
      ),
      Course(
        id: 'fitness_boot',
        name: 'Fitness Bootcamp',
        description: 'High-intensity workout sessions to build strength, endurance, and flexibility.',
        instructor: 'Ahmed Al-Kuwari',
        location: 'Sports Complex, Gym 2',
        createdBy: 'ahmed.kuwari@qu.edu.qa',
        type: ClassType.studentCreated,
        schedule: ['Mon 18:00-19:00', 'Thu 18:00-19:00'],
        maxStudents: 25,
        credits: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        category: EventCategory.sports,
        enrolledCount: 18,
      ),
    ];

    final prefs = await SharedPreferences.getInstance();
    final coursesJson = sampleCourses.map((course) => jsonEncode(course.toJson())).toList();
    await prefs.setStringList(_coursesKey, coursesJson);

    // Add some sample calendar events
    final sampleEvents = [
      CalendarEvent(
        id: 'midterm_cmps251',
        title: 'CMPS 251 Midterm Exam',
        description: 'Midterm examination covering chapters 1-5',
        location: 'Building B, Room 101',
        startTime: DateTime.now().add(const Duration(days: 7)).copyWith(hour: 10, minute: 0),
        endTime: DateTime.now().add(const Duration(days: 7)).copyWith(hour: 12, minute: 0),
        type: EventType.exam,
        addedBy: 'system',
        classId: 'cmps251',
        category: EventCategory.academic,
      ),
      CalendarEvent(
        id: 'js_project',
        title: 'JavaScript Final Project Due',
        description: 'Submit your final web application project',
        location: 'Online Submission',
        startTime: DateTime.now().add(const Duration(days: 14)).copyWith(hour: 23, minute: 59),
        endTime: DateTime.now().add(const Duration(days: 14)).copyWith(hour: 23, minute: 59),
        type: EventType.assignment,
        addedBy: 'sarah.mahmoud@qu.edu.qa',
        classId: 'js_study',
        category: EventCategory.academic,
      ),
      CalendarEvent(
        id: 'photo_exhibition',
        title: 'Photography Exhibition',
        description: 'Showcase of student photography work from the workshop',
        location: 'Art Gallery, Main Campus',
        startTime: DateTime.now().add(const Duration(days: 21)).copyWith(hour: 18, minute: 0),
        endTime: DateTime.now().add(const Duration(days: 21)).copyWith(hour: 21, minute: 0),
        type: EventType.campusEvent,
        addedBy: 'layla.thani@qu.edu.qa',
        classId: 'photo_workshop',
        category: EventCategory.creative,
      ),
    ];

    final eventsJson = sampleEvents.map((event) => jsonEncode(event.toJson())).toList();
    await prefs.setStringList(_eventsKey, eventsJson);
  }
}
