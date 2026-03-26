import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

/// HTTP service for calling the Django backend.
/// Uses JWT token authentication.
class ApiService {
  static const Duration _requestTimeout = Duration(seconds: 20);
  static const int _maxAttempts = 2;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  SharedPreferences? _prefs;
  String? _accessToken;
  String? _refreshToken;

  Future<void> _ensurePrefsLoaded() async {
    _prefs ??= await SharedPreferences.getInstance();
    _accessToken ??= _prefs!.getString('access_token');
    _refreshToken ??= _prefs!.getString('refresh_token');
  }

  Future<void> setTokens(String? access, String? refresh) async {
    await _ensurePrefsLoaded();
    _accessToken = access;
    _refreshToken = refresh;

    if (access == null) {
      await _prefs!.remove('access_token');
    } else {
      await _prefs!.setString('access_token', access);
    }

    if (refresh == null) {
      await _prefs!.remove('refresh_token');
    } else {
      await _prefs!.setString('refresh_token', refresh);
    }
  }

  String? get accessToken => _accessToken;
  String? get refreshTokenValue => _refreshToken;

  Future<bool> hasToken() async {
    await _ensurePrefsLoaded();
    return _accessToken != null && _accessToken!.isNotEmpty;
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    await _ensurePrefsLoaded();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  Future<Map<String, String>> _getAuthHeadersForMultipart() async {
    await _ensurePrefsLoaded();
    return {
      'Accept': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  Uri _uri(String endpoint) {
    final normalized = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse(ApiConfig.endpoint(normalized));
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() requestBuilder,
  ) async {
    Exception? lastError;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await requestBuilder().timeout(_requestTimeout);
        if (kDebugMode) {
          debugPrint('[API] attempt=$attempt status=${response.statusCode}');
        }

        if (response.statusCode >= 500 && attempt < _maxAttempts) {
          await Future<void>.delayed(const Duration(seconds: 1));
          continue;
        }

        return response;
      } on SocketException catch (e) {
        lastError = NetworkException('No internet connection: ${e.message}');
      } on TimeoutException {
        lastError = TimeoutApiException(
          'The server is taking too long to respond. Please try again.',
        );
      } on http.ClientException catch (e) {
        lastError = NetworkException('Network request failed: ${e.message}');
      } on FormatException {
        lastError = NetworkException('Invalid response format from server');
      } on Exception catch (e) {
        lastError = e;
      }

      if (attempt < _maxAttempts) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }

    throw lastError ??
        NetworkException('Unable to reach the server. Please try again.');
  }

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Map<String, String> headers) requestBuilder,
  ) async {
    final headers = await _getAuthHeaders();
    var response = await _sendWithRetry(() => requestBuilder(headers));

    if (response.statusCode == 401) {
      final refreshed = await _attemptTokenRefresh();
      if (!refreshed) {
        await logout();
        throw UnauthorizedException('Session expired. Please sign in again.');
      }

      final retriedHeaders = await _getAuthHeaders();
      response = await _sendWithRetry(() => requestBuilder(retriedHeaders));
    }

    return response;
  }

  Future<bool> _attemptTokenRefresh() async {
    await _ensurePrefsLoaded();
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      return false;
    }

    try {
      final response = await _sendWithRetry(
        () => http.post(
          _uri('/token/refresh/'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'refresh': _refreshToken}),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = _decodeBody(response.body);
        await setTokens(body['access'] as String?, _refreshToken);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _decodeBody(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } on FormatException {
      // Handle HTML error pages or non-JSON responses
      if (rawBody.toString().contains('DOCTYPE') ||
          rawBody.toString().contains('<html>')) {
        return {
          'error': 'Server returned HTML instead of JSON',
          'raw': rawBody,
        };
      }
      return {'error': 'Invalid JSON response: $rawBody'};
    }
  }

  String _extractMessage(
    Map<String, dynamic> body, {
    String fallback = 'Request failed',
  }) {
    final detail = body['detail']?.toString();
    if (detail != null && detail.isNotEmpty) return detail;

    final error = body['error']?.toString();
    if (error != null && error.isNotEmpty) return error;

    final message = body['message']?.toString();
    if (message != null && message.isNotEmpty) return message;

    final errors = body['details'] ?? body['errors'];
    if (errors != null) {
      return _formatErrors(errors);
    }

    return fallback;
  }

  Future<dynamic> login(String email, String password) async {
    final payload = {'email': email, 'password': password};
    if (kDebugMode) {
      debugPrint('[API] POST ${_uri('/login/')} body=$payload');
    }

    final response = await _sendWithRetry(
      () => http.post(
        _uri('/login/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ),
    );

    final body = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final refresh = body['refresh'] as String?;
      await setTokens(body['access'] as String?, refresh);
      return body;
    }

    throw _mapError(response.statusCode, body, fallback: 'Login failed');
  }

  Future<dynamic> register(
    String email,
    String password,
    String fullName,
    String? phoneNumber,
  ) async {
    final payload = {
      'email': email,
      'password': password,
      'full_name': fullName,
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phone_number': phoneNumber,
    };
    if (kDebugMode) {
      debugPrint('[API] POST ${_uri('/register/')} body=$payload');
    }

    final response = await _sendWithRetry(
      () => http.post(
        _uri('/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ),
    );

    final body = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final refresh = body['refresh'] as String?;
      await setTokens(body['access'] as String?, refresh);
      return body;
    }

    throw _mapError(response.statusCode, body, fallback: 'Registration failed');
  }

  Future<void> refreshToken() async {
    final refreshed = await _attemptTokenRefresh();
    if (!refreshed) {
      throw UnauthorizedException('Session expired. Please sign in again.');
    }
  }

  Future<dynamic> get(String endpoint) async {
    if (kDebugMode) {
      debugPrint('[API] GET ${_uri(endpoint)}');
    }

    final response = await _authorizedRequest(
      (headers) => http.get(_uri(endpoint), headers: headers),
    );

    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    if (kDebugMode) {
      debugPrint('[API] POST ${_uri(endpoint)} body=$body');
    }

    final response = await _authorizedRequest(
      (headers) =>
          http.post(_uri(endpoint), headers: headers, body: jsonEncode(body)),
    );

    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    if (kDebugMode) {
      debugPrint('[API] PUT ${_uri(endpoint)} body=$body');
    }

    final response = await _authorizedRequest(
      (headers) =>
          http.put(_uri(endpoint), headers: headers, body: jsonEncode(body)),
    );

    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    if (kDebugMode) {
      debugPrint('[API] PATCH ${_uri(endpoint)} body=$body');
    }

    final response = await _authorizedRequest(
      (headers) =>
          http.patch(_uri(endpoint), headers: headers, body: jsonEncode(body)),
    );

    return _handleResponse(response);
  }

  Future<dynamic> fetchProfile() async {
    return get('/profile/');
  }

  Future<dynamic> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? phone,
    String? address,
    String? citizenshipNumber,
  }) async {
    final payload = <String, dynamic>{'full_name': fullName};
    if (phoneNumber != null) payload['phone_number'] = phoneNumber;
    if (phone != null) payload['phone'] = phone;
    if (address != null) payload['address'] = address;
    if (citizenshipNumber != null) {
      payload['citizenship_number'] = citizenshipNumber;
    }
    return put('/profile/', payload);
  }

  Future<List<dynamic>> fetchServices() async {
    final response = await _sendWithRetry(
      () =>
          http.get(_uri('/services/'), headers: {'Accept': 'application/json'}),
    );

    final body = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final result = body['results'] ?? body['data'] ?? body;
      if (result is List) return result;
      return <dynamic>[];
    }
    throw _mapError(
      response.statusCode,
      body,
      fallback: 'Failed to fetch services',
    );
  }

  Future<List<dynamic>> fetchDocuments() async {
    final result = await get('/documents/');
    if (result is List) return result;
    if (result is Map<String, dynamic> && result['results'] is List) {
      return result['results'] as List<dynamic>;
    }
    return <dynamic>[];
  }

  Future<List<dynamic>> fetchNotifications() async {
    final result = await get('/notifications/');
    if (result is List) return result;
    if (result is Map<String, dynamic> && result['results'] is List) {
      return result['results'] as List<dynamic>;
    }
    return <dynamic>[];
  }

  Future<List<dynamic>> fetchApplications() async {
    final result = await get('/applications/');
    if (result is List) return result;
    if (result is Map<String, dynamic> && result['results'] is List) {
      return result['results'] as List<dynamic>;
    }
    return <dynamic>[];
  }

  Future<dynamic> submitApplication({
    required String serviceId,
    String? remarks,
  }) async {
    return post('/applications/', {
      'service': serviceId,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    });
  }

  Future<dynamic> uploadDocument({
    required String documentType,
    required String documentNumber,
    required String? expiryDate,
    String? filePath,
    required String fileName,
    Uint8List? fileBytes,
  }) async {
    Future<http.Response> sendMultipart(String endpoint) async {
      final headers = await _getAuthHeadersForMultipart();
      final request = http.MultipartRequest('POST', _uri(endpoint));
      request.headers.addAll(headers);
      request.fields['document_type'] = documentType;
      request.fields['document_number'] = documentNumber;
      if (expiryDate != null && expiryDate.isNotEmpty) {
        request.fields['expiry_date'] = expiryDate;
      }

      if (fileBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'document_file',
            fileBytes,
            filename: fileName,
          ),
        );
      } else if (filePath != null && filePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('document_file', filePath),
        );
      } else {
        throw BadRequestException('Document file is required');
      }

      if (kDebugMode) {
        debugPrint('[API] POST multipart ${request.url}');
      }

      final streamedResponse = await request.send().timeout(_requestTimeout);
      return http.Response.fromStream(streamedResponse);
    }

    var response = await sendMultipart('/documents/');
    if (response.statusCode == 401) {
      final refreshed = await _attemptTokenRefresh();
      if (!refreshed) {
        await logout();
        throw UnauthorizedException('Session expired. Please sign in again.');
      }
      response = await sendMultipart('/documents/');
    }

    return _handleResponse(response);
  }

  Future<dynamic> markNotificationAsRead(String notificationId) async {
    return patch('/notifications/$notificationId/', {'is_read': true});
  }

  Future<void> logout() async {
    try {
      if (_refreshToken != null && _refreshToken!.isNotEmpty) {
        await post('/logout/', {'refresh': _refreshToken});
      }
    } catch (_) {
      // Ignore backend logout failures and clear local session anyway.
    }
    await setTokens(null, null);
  }

  dynamic _handleResponse(http.Response response) {
    final body = _decodeBody(response.body);
    if (kDebugMode) {
      debugPrint('[API] response status=${response.statusCode} body=$body');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw _mapError(response.statusCode, body);
  }

  Exception _mapError(
    int statusCode,
    Map<String, dynamic> body, {
    String? fallback,
  }) {
    if (statusCode == 400) {
      return BadRequestException(
        _extractMessage(body, fallback: fallback ?? 'Bad request'),
      );
    }
    if (statusCode == 401) {
      return UnauthorizedException(
        _extractMessage(body, fallback: fallback ?? 'Unauthorized access'),
      );
    }
    if (statusCode == 404) {
      return NotFoundException(
        _extractMessage(body, fallback: fallback ?? 'Resource not found'),
      );
    }
    if (statusCode >= 500) {
      return ServerException(
        _extractMessage(
          body,
          fallback: fallback ?? 'Server error ($statusCode)',
        ),
      );
    }
    return ApiException(
      _extractMessage(
        body,
        fallback: fallback ?? 'Request failed ($statusCode)',
      ),
    );
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

class TimeoutApiException implements Exception {
  final String message;
  TimeoutApiException(this.message);
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
