import 'dart:convert';
import '../models/course.dart';
import 'api_service.dart';

class ClassesService {
  // ── Courses ──

  static Future<List<Course>> getAllCourses({String? search, String? category}) async {
    try {
      String path = '/classes/';
      final params = <String>[];
      if (search != null && search.isNotEmpty) params.add('search=$search');
      if (category != null && category.isNotEmpty) params.add('category=$category');
      if (params.isNotEmpty) path += '?${params.join('&')}';

      final response = await ApiService.getAuth(path);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Course.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Course>> getJoinedCourses() async {
    try {
      final response = await ApiService.getAuth('/classes/joined/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Course.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Course>> getFavoriteCourses() async {
    try {
      final response = await ApiService.getAuth('/classes/favorites/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Course.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> joinClass(String classId) async {
    try {
      final response = await ApiService.postAuth('/classes/$classId/join/', {});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> leaveClass(String classId) async {
    try {
      final response = await ApiService.postAuth('/classes/$classId/leave/', {});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleFavorite(String classId) async {
    try {
      final response = await ApiService.postAuth('/classes/$classId/favorite/', {});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> createClass({
    required String name,
    required String description,
    required String instructor,
    required String location,
    required List<String> schedule,
    required int maxStudents,
    required String category,
    int credits = 0,
  }) async {
    try {
      final response = await ApiService.postAuth('/classes/', {
        'name': name,
        'description': description,
        'instructor': instructor,
        'location': location,
        'schedule': schedule,
        'max_students': maxStudents,
        'credits': credits,
        'category': category,
      });
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ── Events ──

  static Future<List<CalendarEvent>> getAllEvents({String? date, String? courseId}) async {
    try {
      String path = '/events/';
      final params = <String>[];
      if (date != null && date.isNotEmpty) params.add('date=$date');
      if (courseId != null && courseId.isNotEmpty) params.add('course=$courseId');
      if (params.isNotEmpty) path += '?${params.join('&')}';

      final response = await ApiService.getAuth(path);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CalendarEvent.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<CalendarEvent>> getTodayEvents() async {
    try {
      final response = await ApiService.getAuth('/events/today/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CalendarEvent.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<CalendarEvent>> getMyClassEvents() async {
    try {
      final response = await ApiService.getAuth('/events/my-classes/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CalendarEvent.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> toggleEventAttendance(String eventId) async {
    try {
      final response = await ApiService.postAuth('/events/$eventId/attend/', {});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> addEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startTime,
    required DateTime endTime,
    required String eventType,
    required String category,
    String? courseId,
    bool isPublic = true,
  }) async {
    try {
      final response = await ApiService.postAuth('/events/', {
        'title': title,
        'description': description,
        'location': location,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'event_type': eventType,
        'category': category,
        'course_id': courseId,
        'is_public': isPublic,
      });
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
