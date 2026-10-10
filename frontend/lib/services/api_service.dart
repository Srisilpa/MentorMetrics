import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For Flutter Web running on the same PC as FastAPI.
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Invalid response from server. Check that FastAPI is running.',
      );
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception('Invalid login response from server.');
    }

    final message = decoded is Map
        ? decoded['detail'] ?? 'Login failed'
        : 'Login failed';

    throw Exception(message.toString());
  }
}