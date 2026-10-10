import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _keyToken = 'auth_token';
  static const String _keyRole = 'user_role';
  static const String _keyName = 'user_name';
  static const String _keyEmail = 'user_email';
  static const String _keyUserId = 'user_id';
  static const String _keyRollNumber = 'student_roll_number';
  static const String _keyDepartment = 'student_department';
  static const String _keyBaseUrl = 'api_base_url';

  static Future<void> saveSession({
    required String token,
    required String role,
    required String name,
    required String email,
    int? userId,
    String? rollNumber,
    String? department,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRole, role.toLowerCase());
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
    if (userId != null) await prefs.setInt(_keyUserId, userId);
    if (rollNumber != null) await prefs.setString(_keyRollNumber, rollNumber);
    if (department != null) await prefs.setString(_keyDepartment, department);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName) ?? 'User';
  }

  static Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail) ?? '';
  }

  static Future<String?> getRollNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRollNumber);
  }

  static Future<String?> getDepartment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDepartment);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyRollNumber);
    await prefs.remove(_keyDepartment);
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) ?? 'http://127.0.0.1:8000';
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url.trim());
  }
}
