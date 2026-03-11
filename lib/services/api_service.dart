import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Production server URL
  // For local testing on Android emulator use http://10.0.2.2:8000/api
  // For local testing on iOS simulator / desktop use http://127.0.0.1:8000/api
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://qu-community-app.info/api';
    }
    return 'http://qu-community-app.info/api';
  }

  // ── Token keys in SharedPreferences ──
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // ── Token management ──

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  // ── HTTP helpers ──

  /// Build headers with optional JWT Bearer token
  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// POST request (no auth needed – used for login/signup)
  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await _headers();
    return http.post(url, headers: headers, body: jsonEncode(body));
  }

  /// POST request with auth (used for logout)
  static Future<http.Response> postAuth(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await _headers(auth: true);
    return http.post(url, headers: headers, body: jsonEncode(body));
  }

  /// GET request with auth (used for /me, /dashboard)
  static Future<http.Response> getAuth(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = await _headers(auth: true);
    return http.get(url, headers: headers);
  }

  /// Try to refresh the access token using the refresh token.
  /// Returns true if refresh succeeded, false otherwise.
  static Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final url = Uri.parse('$baseUrl/auth/token/refresh/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveTokens(data['access'], data['refresh'] ?? refreshToken);
        return true;
      }
    } catch (_) {}

    // Refresh failed – tokens are invalid, clear them
    await clearTokens();
    return false;
  }
}
