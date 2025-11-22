import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userEmailKey = 'userEmail';
  static const String _userTypeKey = 'userType';
  static const String _adminPassword = '123';

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get current user email
  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Get current user type
  static Future<String?> getCurrentUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  // Validate QU email
  static bool isValidQUEmail(String email) {
    return email.toLowerCase().endsWith('@qu.edu.qa');
  }

  // Login with QU email (students)
  static Future<bool> loginWithQUEmail(String email, String password) async {
    if (!isValidQUEmail(email)) {
      return false;
    }

    // For demo purposes, we'll accept any password for QU emails
    // In a real app, you'd validate against a backend
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userTypeKey, 'student');
    return true;
  }

  // Login with any email (bus drivers)
  static Future<bool> loginAsBusDriver(String email, String password) async {
    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return false;
    }

    // For demo purposes, we'll accept any password for valid emails
    // In a real app, you'd validate against a backend
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userTypeKey, 'bus_driver');
    return true;
  }

  // Login as admin
  static Future<bool> loginAsAdmin(String username, String password) async {
    if (username.toLowerCase() == 'admin' && password == _adminPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userEmailKey, 'admin@qu.edu.qa');
      await prefs.setString(_userTypeKey, 'admin');
      return true;
    }
    return false;
  }

  // Sign up with QU email
  static Future<bool> signUpWithEmail(String email, String password, String confirmPassword) async {
    if (!isValidQUEmail(email)) {
      return false;
    }

    if (password != confirmPassword) {
      return false;
    }

    if (password.length < 6) {
      return false;
    }

    // For demo purposes, we'll automatically create the account
    // In a real app, you'd send this to a backend
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userTypeKey, 'student');
    return true;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userTypeKey);
  }
}
