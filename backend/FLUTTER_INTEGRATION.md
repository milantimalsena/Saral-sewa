# Flutter Integration Guide - Saral Sewa Backend

This guide explains how to integrate the Django REST API with the Flutter frontend.

## Backend Configuration for Flutter

### 1. CORS Settings

Edit `saral_sewa/settings.py`:

```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:8100",  # Flutter web
    "http://127.0.0.1:8080",  # Flutter web alternative
]

CORS_ALLOW_CREDENTIALS = True
```

### 2. Required Headers

Ensure your Flutter app sends these headers:

```
Content-Type: application/json
Authorization: Bearer {access_token}
```

## Flutter Implementation

### 1. Install Dependencies

```bash
flutter pub add http dio provider flutter_secure_storage
```

### 2. Create API Service

```dart
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> register({
    required String email,
    required String fullName,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'full_name': fullName,
          'phone_number': phoneNumber,
          'password': password,
          'password_confirm': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'access_token', value: data['access']);
        await storage.write(key: 'refresh_token', value: data['refresh']);
        return data;
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'access_token', value: data['access']);
        await storage.write(key: 'refresh_token', value: data['refresh']);
        return data;
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse('$baseUrl/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await refreshToken();
        return getProfile();
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final token = await storage.read(key: 'access_token');
      final response = await http.patch(
        Uri.parse('$baseUrl/profile/update/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'full_name': fullName,
          'phone_number': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = await storage.read(key: 'access_token');
      final response = await http.post(
        Uri.parse('$baseUrl/password-change/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirm': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  Future<void> logout() async {
    try {
      final token = await storage.read(key: 'access_token');
      final refreshToken = await storage.read(key: 'refresh_token');

      await http.post(
        Uri.parse('$baseUrl/logout/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      );

      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  Future<void> refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'access_token', value: data['access']);
        await storage.write(key: 'refresh_token', value: data['refresh']);
      } else {
        await logout();
      }
    } catch (e) {
      throw Exception('Token refresh failed: $e');
    }
  }

  Future<Map<String, dynamic>> verifyToken() async {
    try {
      final token = await storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse('$baseUrl/verify-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Invalid token');
      }
    } catch (e) {
      throw Exception('Token verification failed: $e');
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password-reset-request/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('Password reset request failed: $e');
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password-reset/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'new_password': newPassword,
          'new_password_confirm': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }
}
```

### 3. Create Auth Provider

```dart
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;

  Future<void> register({
    required String email,
    required String fullName,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final data = await _apiService.register(
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        password: password,
      );
      _user = data['user'];
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _apiService.login(
        email: email,
        password: password,
      );
      _user = data['user'];
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    try {
      _user = await _apiService.getProfile();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
```

### 4. Usage in Flutter Widgets

```dart
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await context.read<AuthProvider>().login(
                    email: emailController.text,
                    password: passwordController.text,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/home');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Login failed: $e')),
                  );
                }
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.user == null) {
            return Center(child: Text('No user data'));
          }
          
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${authProvider.user!['email']}'),
                Text('Name: ${authProvider.user!['full_name']}'),
                Text('Phone: ${authProvider.user!['phone_number']}'),
                ElevatedButton(
                  onPressed: () {
                    authProvider.logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: Text('Logout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## Testing with Postman

1. Create a Postman Collection
2. Set Environment Variable: `baseUrl = http://127.0.0.1:8000/api`
3. Set Environment Variable: `access_token = (from login response)`
4. Set Environment Variable: `refresh_token = (from login response)`

### Pre-request Script (for token refresh)

```javascript
if (pm.environment.get("access_token_expires")) {
    const now = Math.floor(Date.now() / 1000);
    if (pm.environment.get("access_token_expires") < now) {
        // Token expired, refresh it
        const request = {
            url: pm.environment.get("baseUrl") + "/token/refresh/",
            method: "POST",
            header: {
                "Content-Type": "application/json"
            },
            body: {
                mode: "raw",
                raw: JSON.stringify({
                    refresh: pm.environment.get("refresh_token")
                })
            }
        };
        
        pm.sendRequest(request, (err, response) => {
            if (!err && response.code === 200) {
                const data = response.json();
                pm.environment.set("access_token", data.access);
                pm.environment.set("refresh_token", data.refresh);
            }
        });
    }
}
```

## Common Flutter Issues

### Issue: CORS Error
**Solution:** Ensure backend has correct CORS settings and frontend is accessing from allowed origin

### Issue: Token Expired
**Solution:** Implement token refresh logic before expired token is used

### Issue: API Not Reachable
**Solution:** Check if backend is running and firewall allows connection. Use correct IP/domain.

## Environment Configuration

Create `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );
  
  static const String apiVersion = 'v1';
  static const int timeout = 30; // seconds
}
```

Build with environment:
```bash
flutter run --dart-define=API_BASE_URL=http://your-server:8000/api
```

## Deployment Notes

- Test thoroughly with Flutter on actual devices
- Use HTTPS in production
- Implement proper error handling
- Add loading states
- Cache tokens securely
- Implement automatic token refresh
- Add network connectivity check
- Implement proper logout handling
