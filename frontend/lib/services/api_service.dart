import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

/// HTTP service for calling the Django backend.
/// Uses JWT token authentication.
class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api';

  String? _accessToken;
  String? _refreshToken;
  late String _baseUrl;

  ApiService() {
    _baseUrl = baseUrl;
  }

  void setAndroidEmulatorMode(bool isEmulator) {
    _baseUrl = isEmulator ? androidEmulatorBaseUrl : baseUrl;
  }

  void setTokens(String? access, String? refresh) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  String? get accessToken => _accessToken;

  Future<Map<String, String>> _getAuthHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  Future<Map<String, String>> _getAuthHeadersForMultipart() async {
    return {
      'Accept': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  Future<dynamic> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _accessToken = body['access'];
        _refreshToken = body['refresh'];
        return body;
      } else {
        throw Exception(body['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> refreshToken() async {
    if (_refreshToken == null) return;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _accessToken = body['access'];
      }
    } catch (e) {
      // Token refresh failed
    }
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  Future<dynamic> uploadDocument({
    required String documentType,
    required String documentNumber,
    required String? expiryDate,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final headers = await _getAuthHeadersForMultipart();
      final uri = Uri.parse('$_baseUrl/documents/');
      
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      request.fields['document_type'] = documentType;
      request.fields['document_number'] = documentNumber;
      request.fields['file_name'] = fileName;
      if (expiryDate != null) {
        request.fields['expiry_date'] = expiryDate;
      }

      if (filePath.startsWith('blob:') || filePath.startsWith('http')) {
        request.fields['file_path'] = filePath;
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  Future<dynamic> getDocuments() async {
    return get('/documents/');
  }

  Future<dynamic> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (imageUrl != null) body['image_url'] = imageUrl;
    return patch('/profile/update/', body);
  }

  void logout() {
    _accessToken = null;
    _refreshToken = null;
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    } else if (statusCode == 401) {
      throw UnauthorizedException(body['detail'] ?? body['error'] ?? 'Unauthorized access');
    } else if (statusCode == 400) {
      throw BadRequestException(
        _formatErrors(body['details'] ?? body['error'] ?? 'Bad request'),
      );
    } else if (statusCode == 404) {
      throw NotFoundException(body['detail'] ?? 'Resource not found');
    } else {
      throw ServerException(body['detail'] ?? 'Server error: $statusCode');
    }
  }

  String _formatErrors(dynamic errors) {
    if (errors is String) return errors;
    if (errors is Map) {
      final msgs = <String>[];
      errors.forEach((key, value) {
        if (value is List) {
          msgs.addAll(List<String>.from(value));
        } else {
          msgs.add(value.toString());
        }
      });
      return msgs.join('\n');
    }
    return 'An error occurred';
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class BadRequestException implements Exception {
  final String message;
  BadRequestException(this.message);
  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  @override
  String toString() => message;
}
