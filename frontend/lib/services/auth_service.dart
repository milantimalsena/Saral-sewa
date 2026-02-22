import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiService apiService;

  AuthService({required this.apiService});

  Future<AuthResponse> register({
    required String email,
    required String fullName,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final response = await apiService.post('/register/', {
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber ?? '',
        'password': password,
        'password_confirm': password,
      });

      final authResponse = AuthResponse.fromJson(response);

      await apiService.saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiService.post('/login/', {
        'email': email,
        'password': password,
      });

      final authResponse = AuthResponse.fromJson(response);

      await apiService.saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getProfile() async {
    try {
      final response = await apiService.get('/profile/');
      return User.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> updateProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final response = await apiService.patch('/profile/update/', {
        'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      });
      return User.fromJson(response['user']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await apiService.post('/password-change/', {
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirm': newPassword,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await apiService.getRefreshToken();

      if (refreshToken != null) {
        await apiService.post('/logout/', {'refresh': refreshToken});
      }

      await apiService.clearTokens();
    } catch (e) {
      await apiService.clearTokens();
      rethrow;
    }
  }

  Future<void> refreshTokens() async {
    try {
      final refreshToken = await apiService.getRefreshToken();

      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await apiService.post('/token/refresh/', {
        'refresh': refreshToken,
      });

      await apiService.saveTokens(
        response['access'] as String,
        response['refresh'] as String,
      );
    } catch (e) {
      await apiService.clearTokens();
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await apiService.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> requestPasswordReset({required String email}) async {
    try {
      await apiService.post('/password-reset-request/', {'email': email});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await apiService.post('/password-reset/', {
        'token': token,
        'new_password': newPassword,
        'new_password_confirm': newPassword,
      });
    } catch (e) {
      rethrow;
    }
  }
}
