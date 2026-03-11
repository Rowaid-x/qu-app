import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  // ── Keys for caching user info locally ──
  static const String _userEmailKey = 'userEmail';
  static const String _userTypeKey = 'userType';

  // ── Check if user is logged in (has a valid token) ──
  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getAccessToken();
    if (token == null) return false;

    // Verify the token is still valid by calling /me
    try {
      final response = await ApiService.getAuth('/auth/me/');
      if (response.statusCode == 200) return true;

      // Token expired – try refreshing
      final refreshed = await ApiService.refreshAccessToken();
      return refreshed;
    } catch (_) {
      return false;
    }
  }

  // ── Get cached user email ──
  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // ── Get cached user type ──
  static Future<String?> getCurrentUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  // ── Validate QU email (client-side check) ──
  static bool isValidQUEmail(String email) {
    return email.toLowerCase().endsWith('@qu.edu.qa');
  }

  // ── Helper: save user data from API response ──
  static Future<void> _saveUserFromResponse(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final user = data['user'];
    final tokens = data['tokens'];

    await ApiService.saveTokens(tokens['access'], tokens['refresh']);
    await prefs.setString(_userEmailKey, user['email']);
    await prefs.setString(_userTypeKey, user['user_type']);
  }

  // ── Login with QU email (students) ──
  static Future<Map<String, dynamic>> loginWithQUEmail(String email, String password) async {
    try {
      final response = await ApiService.post('/auth/login/student/', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveUserFromResponse(data);
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['error'] ?? data.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': 'Could not connect to server.'};
    }
  }

  // ── Login with any email (bus drivers) ──
  static Future<Map<String, dynamic>> loginAsBusDriver(String email, String password) async {
    try {
      final response = await ApiService.post('/auth/login/bus-driver/', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveUserFromResponse(data);
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['error'] ?? data.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': 'Could not connect to server.'};
    }
  }

  // ── Login as admin ──
  static Future<Map<String, dynamic>> loginAsAdmin(String username, String password) async {
    try {
      final response = await ApiService.post('/auth/login/admin/', {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveUserFromResponse(data);
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['error'] ?? data.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': 'Could not connect to server.'};
    }
  }

  // ── Sign up with QU email ──
  static Future<Map<String, dynamic>> signUpWithEmail(
      String email, String password, String confirmPassword) async {
    try {
      final response = await ApiService.post('/auth/signup/', {
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveUserFromResponse(data);
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        // DRF returns field-level errors as maps
        String errorMsg = 'Sign up failed.';
        if (data is Map) {
          if (data.containsKey('email')) {
            errorMsg = (data['email'] is List) ? data['email'][0] : data['email'].toString();
          } else if (data.containsKey('confirm_password')) {
            errorMsg = (data['confirm_password'] is List)
                ? data['confirm_password'][0]
                : data['confirm_password'].toString();
          } else if (data.containsKey('non_field_errors')) {
            errorMsg = data['non_field_errors'][0];
          }
        }
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Could not connect to server.'};
    }
  }

  // ── Logout ──
  static Future<void> logout() async {
    try {
      final refreshToken = await ApiService.getRefreshToken();
      if (refreshToken != null) {
        await ApiService.postAuth('/auth/logout/', {'refresh': refreshToken});
      }
    } catch (_) {
      // Even if the server call fails, clear local tokens
    }

    await ApiService.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userTypeKey);
  }
}
