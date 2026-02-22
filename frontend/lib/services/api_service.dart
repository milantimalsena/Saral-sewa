import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api';

  final secureStorage = const FlutterSecureStorage();

  late String _baseUrl;

  ApiService() {
    _baseUrl = baseUrl;
  }

  Future<void> setAndroidEmulatorMode(bool isEmulator) async {
    _baseUrl = isEmulator ? androidEmulatorBaseUrl : baseUrl;
  }

  Future<String?> getAccessToken() async {
    try {
      return await secureStorage.read(key: 'access_token');
    } catch (e) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await secureStorage.read(key: 'refresh_token');
    } catch (e) {
      return null;
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      await Future.wait([
        secureStorage.write(key: 'access_token', value: accessToken),
        secureStorage.write(key: 'refresh_token', value: refreshToken),
      ]);
    } catch (e) {
      throw Exception('Failed to save tokens: $e');
    }
  }

  Future<void> clearTokens() async {
    try {
      await Future.wait([
        secureStorage.delete(key: 'access_token'),
        secureStorage.delete(key: 'refresh_token'),
      ]);
    } catch (e) {
      throw Exception('Failed to clear tokens: $e');
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
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
    if (errors is String) {
      return errors;
    } else if (errors is Map) {
      final errorMessages = <String>[];
      errors.forEach((key, value) {
        if (value is List) {
          errorMessages.addAll(List<String>.from(value));
        } else {
          errorMessages.add(value.toString());
        }
      });
      return errorMessages.join('\n');
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
