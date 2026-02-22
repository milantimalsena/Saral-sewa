import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  late final AuthService _authService;
  late final ApiService _apiService;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthProvider({ApiService? apiService}) {
    _apiService = apiService ?? ApiService();
    _authService = AuthService(apiService: _apiService);
    _initializeAuth();
  }

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  ApiService get apiService => _apiService;

  Future<void> _initializeAuth() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        await _loadUserProfile();
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      _user = await _authService.getProfile();
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String fullName,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.register(
        email: email,
        fullName: fullName,
        password: password,
        phoneNumber: phoneNumber,
      );

      _user = response.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _formatErrorMessage(e.toString());
      _user = null;
      notifyListeners();

      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.login(
        email: email,
        password: password,
      );

      _user = response.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _formatErrorMessage(e.toString());
      _user = null;
      notifyListeners();

      return false;
    }
  }

  Future<void> logout() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _authService.logout();

      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> refreshProfile() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      _user = await _authService.getProfile();
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _formatErrorMessage(e.toString());
      notifyListeners();

      return false;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      _user = await _authService.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _formatErrorMessage(e.toString());
      notifyListeners();

      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _formatErrorMessage(e.toString());
      notifyListeners();

      return false;
    }
  }

  Future<bool> requestPasswordReset({required String email}) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _authService.requestPasswordReset(email: email);

      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _formatErrorMessage(e.toString());
      notifyListeners();

      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _authService.resetPassword(token: token, newPassword: newPassword);

      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _formatErrorMessage(e.toString());
      notifyListeners();

      return false;
    }
  }

  String _formatErrorMessage(String error) {
    if (error.contains('UnauthorizedException')) {
      return 'Invalid credentials. Please try again.';
    } else if (error.contains('BadRequestException')) {
      return error.replaceFirst('BadRequestException: ', '');
    } else if (error.contains('NotFoundException')) {
      return 'Resource not found.';
    } else if (error.contains('ServerException')) {
      return 'Server error. Please try again later.';
    } else if (error.contains('Request failed')) {
      return 'Network error. Check your connection.';
    }
    return error;
  }
}
