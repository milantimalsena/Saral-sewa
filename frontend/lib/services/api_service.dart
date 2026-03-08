import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

/// HTTP service for calling the Django backend.
/// Attaches the Clerk session JWT as a Bearer token.
class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api';

  final ClerkService clerkService;
  late String _baseUrl;

  ApiService({ClerkService? clerkService})
    : clerkService = clerkService ?? ClerkService() {
    _baseUrl = baseUrl;
  }

  void setAndroidEmulatorMode(bool isEmulator) {
    _baseUrl = isEmulator ? androidEmulatorBaseUrl : baseUrl;
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    // Try refreshing the short-lived Clerk JWT if present
    String? token = await clerkService.getSessionToken();
    token ??= await clerkService.refreshSessionToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _getAuthHeadersForMultipart() async {
    String? token = await clerkService.getSessionToken();
    token ??= await clerkService.refreshSessionToken();

    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
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
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

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

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    } else if (statusCode == 401) {
      throw UnauthorizedException(body['detail'] ?? 'Unauthorized access');
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
