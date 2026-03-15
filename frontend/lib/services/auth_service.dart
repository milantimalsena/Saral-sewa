import 'dart:convert';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user.dart';

/// Exception thrown by Clerk API calls.
class ClerkException implements Exception {
  final String message;
  ClerkException(this.message);

  @override
  String toString() => message;
}

/// Service that talks directly to the **Clerk Frontend API** using the native
/// mobile flow. Clerk's native flow requires managing a `__client` token that
/// is returned on every response. This token must be sent with every subsequent
/// request via the `Authorization: Bearer <__client>` header (for non-browser
/// clients) or as a `__clerk_client_id` query parameter.
class ClerkService {
  static const String publishableKey =
      'pk_test_dmFzdC1iZW5nYWwtMTMuY2xlcmsuYWNjb3VudHMuZGV2JA';

  static const String frontendApi = 'vast-bengal-13.clerk.accounts.dev';

  static final String _baseUrl = 'https://$frontendApi/v1';

  // Custom deep link used as the OAuth redirect target.
  // Add this URL to Clerk Dashboard → Redirect URLs (native/mobile).
  static final Uri _oauthRedirectUri = Uri.parse('saralsewa://oauth');

  final _storage = const FlutterSecureStorage();

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  /// Build headers for Clerk Frontend API requests.
  /// For the very first request (no client token yet) we omit Authorization.
  /// Once we have a `__client` token we send it as the Bearer token.
  Future<Map<String, String>> _getHeaders() async {
    final clientToken = await _storage.read(key: 'clerk_client_token');
    return {
      'Content-Type': 'application/x-www-form-urlencoded',
      if (clientToken != null) 'Authorization': clientToken,
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return {};
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    return {'data': body};
  }

  String _extractError(Map<String, dynamic> body) {
    final errors = body['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      return errors[0]['long_message'] ??
          errors[0]['message'] ??
          'Request failed';
    }
    return body['error'] as String? ?? 'Request failed';
  }

  /// After every Clerk Frontend API response, persist the latest `__client`
  /// token so the next request can use it. Clerk returns it in the response
  /// body under `client` or sometimes at the top level.
  Future<void> _persistClientToken(http.Response response) async {
    // Clerk also returns it via Set-Cookie __client=... but we can't easily
    // read cookies with the http package. Instead we look at the response
    // body's `client` field which has an `id` we can use, OR we look for the
    // `Authorization` header in the response.

    // The safest approach: Clerk returns a header `Authorization` with the
    // refreshed client token in many responses. Check that first.
    final authHeader = response.headers['authorization'];
    if (authHeader != null && authHeader.isNotEmpty) {
      await _storage.write(key: 'clerk_client_token', value: authHeader);
    }
  }

  // -------------------------------------------------------------------------
  // Client initialization  –  Required for native API
  // -------------------------------------------------------------------------

  /// Ensure we have a Clerk client token. Call this before any sign-in/sign-up.
  Future<void> _ensureClient() async {
    final existing = await _storage.read(key: 'clerk_client_token');
    if (existing != null && existing.isNotEmpty) return;

    // Create a fresh client
    final res = await http.get(
      Uri.parse('$_baseUrl/client?_is_native=1'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    await _persistClientToken(res);

    // If the authorization header wasn't set, try to get the token from body
    final stored = await _storage.read(key: 'clerk_client_token');
    if (stored == null || stored.isEmpty) {
      // Some Clerk setups return the token in Set-Cookie header
      final setCookie = res.headers['set-cookie'];
      if (setCookie != null) {
        final match = RegExp(r'__client=([^;]+)').firstMatch(setCookie);
        if (match != null) {
          await _storage.write(
            key: 'clerk_client_token',
            value: match.group(1)!,
          );
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // Token / session management
  // -------------------------------------------------------------------------

  Future<void> _saveSession({
    required String sessionId,
    required String jwt,
  }) async {
    await Future.wait([
      _storage.write(key: 'clerk_session_id', value: sessionId),
      _storage.write(key: 'clerk_jwt', value: jwt),
    ]);
  }

  Future<String?> getSessionToken() async {
    return _storage.read(key: 'clerk_jwt');
  }

  Future<String?> getSessionId() async {
    return _storage.read(key: 'clerk_session_id');
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: 'clerk_session_id'),
      _storage.delete(key: 'clerk_jwt'),
      _storage.delete(key: 'clerk_user'),
      _storage.delete(key: 'clerk_client_token'),
    ]);
  }

  Future<bool> isLoggedIn() async {
    final token = await getSessionToken();
    return token != null && token.isNotEmpty;
  }

  // -------------------------------------------------------------------------
  // Refresh the short-lived session JWT
  // -------------------------------------------------------------------------

  Future<String?> refreshSessionToken() async {
    final sessionId = await getSessionId();
    if (sessionId == null) return null;

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/client/sessions/$sessionId/tokens?_is_native=1'),
        headers: headers,
      );

      await _persistClientToken(response);

      if (response.statusCode != 200) return null;

      final data = _decode(response);
      final jwt = data['jwt'] as String?;
      if (jwt != null) {
        await _storage.write(key: 'clerk_jwt', value: jwt);
      }
      return jwt;
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Fetch current user from active session
  // -------------------------------------------------------------------------

  Future<User?> fetchCurrentUser() async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse('$_baseUrl/client?_is_native=1'),
        headers: headers,
      );
      await _persistClientToken(res);
      if (res.statusCode != 200) return null;

      final body = _decode(res);
      final client = body['response'] as Map<String, dynamic>?;
      if (client == null) return null;

      final sessionId = await getSessionId();
      final sessions = client['sessions'] as List? ?? [];
      for (final s in sessions) {
        if (s['id'] == sessionId) {
          final userData = s['user'] as Map<String, dynamic>?;
          if (userData != null) return User.fromClerkSession(userData);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Sign In (email + password)
  // -------------------------------------------------------------------------

  Future<User> signIn({required String email, required String password}) async {
    await _ensureClient();

    final headers = await _getHeaders();

    // Step 1 – Create a sign-in attempt
    final createRes = await http.post(
      Uri.parse('$_baseUrl/client/sign_ins?_is_native=1'),
      headers: headers,
      body: {'identifier': email, 'strategy': 'password', 'password': password},
    );

    await _persistClientToken(createRes);

    final createBody = _decode(createRes);

    if (createRes.statusCode != 200) {
      throw ClerkException(_extractError(createBody));
    }

    final response = createBody['response'] ?? createBody;
    final status = response['status'];

    if (status != 'complete') {
      throw ClerkException(
        'Additional verification required (status: $status). '
        'Please complete sign-in in the Clerk dashboard or use another strategy.',
      );
    }

    // Step 2 – Extract session & user
    final sessionId = response['created_session_id'] as String;
    final client = createBody['client'] as Map<String, dynamic>?;

    String? jwt;
    Map<String, dynamic>? userData;

    if (client != null) {
      final sessions = client['sessions'] as List? ?? [];
      for (final s in sessions) {
        if (s['id'] == sessionId) {
          jwt = (s['last_active_token'] as Map?)?['jwt'] as String?;
          userData = s['user'] as Map<String, dynamic>?;
          break;
        }
      }
    }

    // If the JWT wasn't in the initial response, fetch it explicitly
    jwt ??= await _fetchSessionJwt(sessionId);

    if (jwt == null) {
      throw ClerkException('Failed to obtain session token.');
    }

    await _saveSession(sessionId: sessionId, jwt: jwt);

    if (userData != null) {
      return User.fromClerkSession(userData);
    }

    // Fallback: build a minimal user from what we know
    return User(
      id: response['user_id'] ?? '',
      email: email,
      firstName: '',
      lastName: '',
    );
  }

  Future<String?> _fetchSessionJwt(String sessionId) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('$_baseUrl/client/sessions/$sessionId/tokens?_is_native=1'),
      headers: headers,
    );
    await _persistClientToken(res);
    if (res.statusCode != 200) return null;
    final data = _decode(res);
    return data['jwt'] as String?;
  }

  // -------------------------------------------------------------------------
  // Sign Up (email + password)
  // -------------------------------------------------------------------------

  Future<User> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    await _ensureClient();

    final headers = await _getHeaders();

    final bodyParams = <String, String>{
      'email_address': email,
      'password': password,
      'first_name': ?firstName,
      'last_name': ?lastName,
    };

    final createRes = await http.post(
      Uri.parse('$_baseUrl/client/sign_ups?_is_native=1'),
      headers: headers,
      body: bodyParams,
    );

    await _persistClientToken(createRes);

    final createBody = _decode(createRes);

    if (createRes.statusCode != 200 && createRes.statusCode != 422) {
      throw ClerkException(_extractError(createBody));
    }

    if (createRes.statusCode == 422) {
      throw ClerkException(_extractError(createBody));
    }

    final response = createBody['response'] ?? createBody;
    final status = response['status'];

    // If email verification is required, Clerk returns "missing_requirements"
    if (status == 'missing_requirements') {
      final signUpId = response['id'] as String;

      // Request email verification code
      await _prepareVerification(signUpId);

      throw ClerkException('VERIFY_EMAIL:$signUpId');
    }

    if (status != 'complete') {
      throw ClerkException(
        'Sign-up requires additional steps (status: $status).',
      );
    }

    // Auto-signed-in after signup
    final sessionId = response['created_session_id'] as String?;
    final client = createBody['client'] as Map<String, dynamic>?;

    String? jwt;
    Map<String, dynamic>? userData;

    if (client != null && sessionId != null) {
      final sessions = client['sessions'] as List? ?? [];
      for (final s in sessions) {
        if (s['id'] == sessionId) {
          jwt = (s['last_active_token'] as Map?)?['jwt'] as String?;
          userData = s['user'] as Map<String, dynamic>?;
          break;
        }
      }
    }

    if (sessionId != null) {
      jwt ??= await _fetchSessionJwt(sessionId);
      if (jwt != null) {
        await _saveSession(sessionId: sessionId, jwt: jwt);
      }
    }

    if (userData != null) {
      return User.fromClerkSession(userData);
    }

    return User(
      id: response['created_user_id'] ?? '',
      email: email,
      firstName: firstName ?? '',
      lastName: lastName ?? '',
    );
  }

  Future<void> _prepareVerification(String signUpId) async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse(
        '$_baseUrl/client/sign_ups/$signUpId/prepare_verification?_is_native=1',
      ),
      headers: headers,
      body: {'strategy': 'email_code'},
    );
  }

  /// Complete email verification after sign-up.
  Future<User> verifyEmail({
    required String signUpId,
    required String code,
  }) async {
    final headers = await _getHeaders();

    final res = await http.post(
      Uri.parse(
        '$_baseUrl/client/sign_ups/$signUpId/attempt_verification?_is_native=1',
      ),
      headers: headers,
      body: {'strategy': 'email_code', 'code': code},
    );

    await _persistClientToken(res);

    final body = _decode(res);

    if (res.statusCode != 200) {
      throw ClerkException(_extractError(body));
    }

    final response = body['response'] ?? body;
    final status = response['status'];

    if (status != 'complete') {
      throw ClerkException('Verification not complete (status: $status).');
    }

    final sessionId = response['created_session_id'] as String?;
    if (sessionId != null) {
      final jwt = await _fetchSessionJwt(sessionId);
      if (jwt != null) {
        await _saveSession(sessionId: sessionId, jwt: jwt);
      }
    }

    return User(
      id: response['created_user_id'] ?? '',
      email: '',
      firstName: '',
      lastName: '',
    );
  }

  // -------------------------------------------------------------------------
  // Social / OAuth login (Google, Facebook, etc.)
  // -------------------------------------------------------------------------

  /// Start an OAuth sign-in flow. This opens the browser for the user to
  /// authenticate with the social provider, then polls for completion.
  Future<User> signInWithOAuth({required String strategy}) async {
    await _ensureClient();

    final headers = await _getHeaders();

    // Step 1 – Create a sign-in with the OAuth strategy
    final createRes = await http.post(
      Uri.parse('$_baseUrl/client/sign_ins?_is_native=1'),
      headers: headers,
      body: {
        'strategy': strategy,
        // Redirect back into the app so the flow can complete reliably.
        'redirect_url': _oauthRedirectUri.toString(),
        'action_complete_redirect_url': _oauthRedirectUri.toString(),
      },
    );

    await _persistClientToken(createRes);
    final createBody = _decode(createRes);

    if (createRes.statusCode != 200) {
      throw ClerkException(_extractError(createBody));
    }

    final response = createBody['response'] ?? createBody;
    final firstFactors =
        response['first_factor_verification'] as Map<String, dynamic>?;

    if (firstFactors == null) {
      throw ClerkException('OAuth flow not supported for this strategy.');
    }

    final externalUrl =
        firstFactors['external_verification_redirect_url'] as String?;
    if (externalUrl == null || externalUrl.isEmpty) {
      throw ClerkException('No redirect URL returned from Clerk.');
    }

    final signInId = response['id'] as String;

    // Step 2 – Open the OAuth URL in the browser
    final uri = Uri.parse(externalUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw ClerkException('Could not open browser for authentication.');
    }

    // Wait for the user to complete OAuth in the browser and return to the app.
    // Without this, the app is backgrounded and polling is unreliable.
    await _waitForOAuthRedirect();

    // Step 3 – Poll the sign-in status until it completes or times out
    return _pollSignInCompletion(signInId);
  }

  /// Start an OAuth sign-up flow.
  Future<User> signUpWithOAuth({required String strategy}) async {
    await _ensureClient();

    final headers = await _getHeaders();

    final createRes = await http.post(
      Uri.parse('$_baseUrl/client/sign_ups?_is_native=1'),
      headers: headers,
      body: {
        'strategy': strategy,
        'redirect_url': _oauthRedirectUri.toString(),
        'action_complete_redirect_url': _oauthRedirectUri.toString(),
      },
    );

    await _persistClientToken(createRes);
    final createBody = _decode(createRes);

    if (createRes.statusCode != 200 && createRes.statusCode != 422) {
      throw ClerkException(_extractError(createBody));
    }

    if (createRes.statusCode == 422) {
      throw ClerkException(_extractError(createBody));
    }

    final response = createBody['response'] ?? createBody;
    final verification = response['verifications'] as Map<String, dynamic>?;
    final external = verification?['external_account'] as Map<String, dynamic>?;

    final externalUrl =
        external?['external_verification_redirect_url'] as String?;
    if (externalUrl == null || externalUrl.isEmpty) {
      throw ClerkException('No redirect URL returned from Clerk.');
    }

    final signUpId = response['id'] as String;

    // Open the OAuth URL in the browser
    final uri = Uri.parse(externalUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw ClerkException('Could not open browser for authentication.');
    }

    await _waitForOAuthRedirect();

    // Poll for completion
    return _pollSignUpCompletion(signUpId);
  }

  Future<void> _waitForOAuthRedirect() async {
    final appLinks = AppLinks();

    bool isMatch(Uri uri) {
      return uri.scheme == _oauthRedirectUri.scheme &&
          (uri.host == _oauthRedirectUri.host ||
              _oauthRedirectUri.host.isEmpty);
    }

    try {
      // If the app was cold-started by the link, handle that too.
      final initial = await appLinks.getInitialLink();
      if (initial != null && isMatch(initial)) {
        return;
      }
    } catch (_) {
      // Best effort — fall back to stream.
    }

    try {
      await appLinks.uriLinkStream
          .firstWhere(isMatch)
          .timeout(const Duration(minutes: 3));
    } on TimeoutException {
      throw ClerkException('OAuth timed out. Please try again.');
    }
  }

  /// Poll the Clerk client until the sign-in is complete or times out.
  Future<User> _pollSignInCompletion(String signInId) async {
    const maxAttempts = 60; // 60 * 3s = 3 minutes
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 3));

      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse('$_baseUrl/client?_is_native=1'),
        headers: headers,
      );
      await _persistClientToken(res);

      final body = _decode(res);
      final client = body['response'] as Map<String, dynamic>?;
      if (client == null) continue;

      final sessions = client['sessions'] as List? ?? [];
      if (sessions.isNotEmpty) {
        // A session was created — the OAuth flow completed
        final session = sessions.last as Map<String, dynamic>;
        final sessionId = session['id'] as String;

        final jwt = await _fetchSessionJwt(sessionId);
        if (jwt != null) {
          await _saveSession(sessionId: sessionId, jwt: jwt);

          final userData = session['user'] as Map<String, dynamic>?;
          if (userData != null) {
            return User.fromClerkSession(userData);
          }

          return User(id: '', email: '', firstName: '', lastName: '');
        }
      }
    }

    throw ClerkException('OAuth sign-in timed out. Please try again.');
  }

  /// Poll the Clerk client until the sign-up is complete or times out.
  Future<User> _pollSignUpCompletion(String signUpId) async {
    const maxAttempts = 60;
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 3));

      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse('$_baseUrl/client?_is_native=1'),
        headers: headers,
      );
      await _persistClientToken(res);

      final body = _decode(res);
      final client = body['response'] as Map<String, dynamic>?;
      if (client == null) continue;

      final sessions = client['sessions'] as List? ?? [];
      if (sessions.isNotEmpty) {
        final session = sessions.last as Map<String, dynamic>;
        final sessionId = session['id'] as String;

        final jwt = await _fetchSessionJwt(sessionId);
        if (jwt != null) {
          await _saveSession(sessionId: sessionId, jwt: jwt);

          final userData = session['user'] as Map<String, dynamic>?;
          if (userData != null) {
            return User.fromClerkSession(userData);
          }

          return User(id: '', email: '', firstName: '', lastName: '');
        }
      }
    }

    throw ClerkException('OAuth sign-up timed out. Please try again.');
  }

  // -------------------------------------------------------------------------
  // Sign Out
  // -------------------------------------------------------------------------

  Future<void> signOut() async {
    final sessionId = await getSessionId();

    if (sessionId != null) {
      try {
        final headers = await _getHeaders();
        await http.post(
          Uri.parse('$_baseUrl/client/sessions/$sessionId/revoke?_is_native=1'),
          headers: headers,
        );
      } catch (_) {
        // Best-effort: clear local state even if the API call fails
      }
    }

    await clearSession();
  }
}
