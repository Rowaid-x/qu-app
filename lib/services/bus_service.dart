import 'dart:convert';
import '../models/bus.dart';
import 'api_service.dart';

class BusService {
  /// Get all active bus routes
  static Future<List<BusRoute>> getRoutes() async {
    try {
      final response = await ApiService.getAuth('/bus/routes/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BusRoute.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get all active buses with latest location
  static Future<List<Bus>> getActiveBuses() async {
    try {
      final response = await ApiService.getAuth('/bus/active/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Bus.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get driver's assigned bus
  static Future<Bus?> getMyBus() async {
    try {
      final response = await ApiService.getAuth('/bus/my-bus/');
      if (response.statusCode == 200) {
        return Bus.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  /// Start a trip
  static Future<Map<String, dynamic>> startTrip() async {
    try {
      final response = await ApiService.postAuth('/bus/start-trip/', {});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'bus': Bus.fromJson(data['bus'])};
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to start trip'};
    } catch (e) {
      return {'success': false, 'error': 'Could not connect to server.'};
    }
  }

  /// End a trip
  static Future<Map<String, dynamic>> endTrip() async {
    try {
      final response = await ApiService.postAuth('/bus/end-trip/', {});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'bus': Bus.fromJson(data['bus'])};
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to end trip'};
    } catch (e) {
      return {'success': false, 'error': 'Could not connect to server.'};
    }
  }

  /// Update location
  static Future<bool> updateLocation({
    required double latitude,
    required double longitude,
    String currentStop = '',
    String nextStop = '',
    String status = 'on_route',
    String occupancy = 'empty',
  }) async {
    try {
      final response = await ApiService.postAuth('/bus/update-location/', {
        'latitude': latitude,
        'longitude': longitude,
        'current_stop': currentStop,
        'next_stop': nextStop,
        'status': status,
        'occupancy': occupancy,
      });
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
