import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_service.dart';

class ApiService {
  // Configurable base URL. Default is 127.0.0.1:8000 for local development.
  static String defaultBaseUrl = 'http://127.0.0.1:8000';

  static Future<String> _resolveBaseUrl() async {
    return await SessionService.getBaseUrl();
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await SessionService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
      throw Exception('Server returned an unparseable response (HTTP ${response.statusCode})');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (response.statusCode == 401) {
      final msg = decoded is Map ? (decoded['detail'] ?? 'Session expired. Please log in again.') : 'Unauthorized';
      throw Exception(msg);
    }

    if (response.statusCode == 403) {
      final msg = decoded is Map ? (decoded['detail'] ?? 'Access denied. You do not have permission.') : 'Forbidden';
      throw Exception(msg);
    }

    if (response.statusCode == 422) {
      if (decoded is Map && decoded['detail'] is List) {
        final errors = (decoded['detail'] as List).map((e) => e['msg'] ?? e.toString()).join(', ');
        throw Exception('Validation error: $errors');
      }
    }

    final message = decoded is Map
        ? (decoded['detail'] ?? decoded['message'] ?? 'Request failed (${response.statusCode})')
        : 'Request failed (${response.statusCode})';

    throw Exception(message.toString());
  }

  // --- AUTHENTICATION ---
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final baseUrl = await _resolveBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: await _headers(auth: false),
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = _handleResponse(response) as Map<String, dynamic>;
      await SessionService.saveSession(
        token: data['access_token'],
        role: data['role'],
        name: data['name'] ?? 'User',
        email: data['email'] ?? email.trim(),
        userId: data['id'],
      );
      return data;
    } on http.ClientException {
      throw Exception('Could not connect to FastAPI server at $baseUrl. Ensure the backend is running.');
    }
  }

  static Future<Map<String, dynamic>> registerStudent({
    required String name,
    required String email,
    required String password,
    String? rollNumber,
    int? departmentId,
    String? academicYear,
  }) async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: await _headers(auth: false),
          body: jsonEncode({
            'name': name.trim(),
            'email': email.trim(),
            'password': password,
            'roll_number': rollNumber?.trim(),
            'department_id': departmentId,
            'academic_year': academicYear ?? '2026-27',
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .get(
          Uri.parse('$baseUrl/auth/me'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    final data = _handleResponse(response) as Map<String, dynamic>;
    if (data['roll_number'] != null || data['department_name'] != null) {
      await SessionService.saveSession(
        token: (await SessionService.getToken()) ?? '',
        role: data['role'],
        name: data['name'],
        email: data['email'],
        userId: data['id'],
        rollNumber: data['roll_number'],
        department: data['department_name'],
      );
    }
    return data;
  }

  // --- FACULTY ---
  static Future<List<dynamic>> getFaculty({
    bool activeOnly = false,
    int? departmentId,
  }) async {
    final baseUrl = await _resolveBaseUrl();
    var uri = Uri.parse('$baseUrl/faculty?active_only=$activeOnly');
    if (departmentId != null) {
      uri = uri.replace(queryParameters: {
        'active_only': activeOnly.toString(),
        'department_id': departmentId.toString(),
      });
    }
    final response = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 15));
    return _handleResponse(response) as List<dynamic>;
  }

  static Future<List<dynamic>> getFeedbackFaculty() async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .get(Uri.parse('$baseUrl/feedback/faculty'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createFaculty(Map<String, dynamic> data) async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .post(
          Uri.parse('$baseUrl/faculty'),
          headers: await _headers(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateFaculty(int id, Map<String, dynamic> data) async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .put(
          Uri.parse('$baseUrl/faculty/$id'),
          headers: await _headers(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateFacultyStatus(int id, bool isActive) async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .patch(
          Uri.parse('$baseUrl/faculty/$id/status'),
          headers: await _headers(),
          body: jsonEncode({'is_active': isActive}),
        )
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static Future<void> deleteFaculty(int id) async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .delete(Uri.parse('$baseUrl/faculty/$id'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    _handleResponse(response);
  }

  static Future<List<dynamic>> getFacultySubjects(int facultyId) async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .get(Uri.parse('$baseUrl/faculty/$facultyId/subjects'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> assignSubjectToFaculty(int facultyId, int subjectId, {String? academicYear}) async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .post(
          Uri.parse('$baseUrl/faculty/$facultyId/subjects'),
          headers: await _headers(),
          body: jsonEncode({
            'subject_id': subjectId,
            'academic_year': academicYear ?? '2026-27',
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static Future<void> unassignSubjectFromFaculty(int facultyId, int subjectId) async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .delete(Uri.parse('$baseUrl/faculty/$facultyId/subjects/$subjectId'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    _handleResponse(response);
  }

  // --- SUBJECTS ---
  static Future<List<dynamic>> getSubjects({
    bool activeOnly = false,
    int? departmentId,
  }) async {
    final baseUrl = await _resolveBaseUrl();
    var uri = Uri.parse('$baseUrl/subjects?active_only=$activeOnly');
    if (departmentId != null) {
      uri = uri.replace(queryParameters: {
        'active_only': activeOnly.toString(),
        'department_id': departmentId.toString(),
      });
    }
    final response = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 15));
    return _handleResponse(response) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createSubject(Map<String, dynamic> data) async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .post(
          Uri.parse('$baseUrl/subjects'),
          headers: await _headers(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateSubject(int id, Map<String, dynamic> data) async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .put(
          Uri.parse('$baseUrl/subjects/$id'),
          headers: await _headers(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateSubjectStatus(int id, bool isActive) async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .patch(
          Uri.parse('$baseUrl/subjects/$id/status'),
          headers: await _headers(),
          body: jsonEncode({'is_active': isActive}),
        )
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response) as Map<String, dynamic>;
  }

  // --- DEPARTMENTS ---
  static Future<List<dynamic>> getDepartments() async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .get(Uri.parse('$baseUrl/departments'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response) as List<dynamic>;
  }

  // --- FEEDBACK ---
  static Future<Map<String, dynamic>> submitFeedback({
    required int facultyId,
    required int subjectId,
    required String subjectName,
    required int teachingQuality,
    required int subjectKnowledge,
    required int communication,
    required int punctuality,
    required int overallSatisfaction,
    int? rating,
    String? comments,
  }) async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .post(
          Uri.parse('$baseUrl/feedback/submit'),
          headers: await _headers(),
          body: jsonEncode({
            'faculty_id': facultyId,
            'subject_id': subjectId,
            'subject': subjectName,
            'teaching_quality': teachingQuality,
            'subject_knowledge': subjectKnowledge,
            'communication': communication,
            'punctuality': punctuality,
            'overall_satisfaction': overallSatisfaction,
            'rating': rating ?? overallSatisfaction,
            'comments': comments ?? '',
          }),
        )
        .timeout(const Duration(seconds: 20));
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getMyFeedback() async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .get(Uri.parse('$baseUrl/feedback/my'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getAdminAnalytics() async {
    final baseUrl = await _resolveBaseUrl();
    final response = await http
        .get(Uri.parse('$baseUrl/feedback/admin/analytics'), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAdminFeedbackRecords({
    int? facultyId,
    int? subjectId,
    int? departmentId,
    int? rating,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final baseUrl = await _resolveBaseUrl();
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (facultyId != null) params['faculty_id'] = facultyId.toString();
    if (subjectId != null) params['subject_id'] = subjectId.toString();
    if (departmentId != null) params['department_id'] = departmentId.toString();
    if (rating != null) params['rating'] = rating.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$baseUrl/feedback/admin/records').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 15));
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static Future<String> downloadFeedbackCsv({
    int? facultyId,
    int? subjectId,
    int? departmentId,
    int? rating,
  }) async {
    final baseUrl = await _resolveBaseUrl();
    final params = <String, String>{};
    if (facultyId != null) params['faculty_id'] = facultyId.toString();
    if (subjectId != null) params['subject_id'] = subjectId.toString();
    if (departmentId != null) params['department_id'] = departmentId.toString();
    if (rating != null) params['rating'] = rating.toString();

    final uri = Uri.parse('$baseUrl/feedback/admin/export').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 20));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    }
    throw Exception('Failed to download CSV export (${response.statusCode})');
  }
}