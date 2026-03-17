import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Indicates sign-up succeeded but the user must verify their e-mail.
enum PendingAction { none, emailVerification }

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  PendingAction _pendingAction = PendingAction.none;
  String? _pendingSignUpId;

  AuthProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService() {
    _initializeAuth();
  }

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  PendingAction get pendingAction => _pendingAction;
  String? get pendingSignUpId => _pendingSignUpId;
  ApiService get apiService => _apiService;

  // ---------------------------------------------------------------------------
  // Initialise – check for an existing Clerk session
  // ---------------------------------------------------------------------------

  Future<void> _initializeAuth() async {
    try {
      final profile = await _apiService.get('/profile/');
      _user = User.fromBackendProfile(profile as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Sign In
  // ---------------------------------------------------------------------------

  Future<bool> signIn({required String email, required String password}) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result =
          await _apiService.login(email, password) as Map<String, dynamic>;
      final userPayload = result['user'] as Map<String, dynamic>?;
      if (userPayload == null) {
        throw Exception('Missing user data from login response');
      }

      _user = User.fromBackendProfile({
        'id': userPayload['id'],
        'email': userPayload['email'],
        'full_name': userPayload['full_name'] ?? '',
      });

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on UnauthorizedException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } on TimeoutApiException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Sign-in failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Up
  // ---------------------------------------------------------------------------

  Future<bool> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      _pendingAction = PendingAction.none;
      notifyListeners();

      final fullName = [
        firstName?.trim() ?? '',
        lastName?.trim() ?? '',
      ].where((value) => value.isNotEmpty).join(' ');

      final result =
          await _apiService.register(email, password, fullName)
              as Map<String, dynamic>;
      final userPayload = result['user'] as Map<String, dynamic>?;
      if (userPayload == null) {
        throw Exception('Missing user data from registration response');
      }

      _user = User.fromBackendProfile({
        'id': userPayload['id'],
        'email': userPayload['email'],
        'full_name': userPayload['full_name'] ?? fullName,
      });

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on BadRequestException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } on TimeoutApiException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Sign-up failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Verify e-mail (OTP code sent by Clerk)
  // ---------------------------------------------------------------------------

  Future<bool> verifyEmail({required String code}) async {
    _status = AuthStatus.error;
    _errorMessage =
        'Email verification via OTP is not enabled on this backend yet.';
    notifyListeners();
    return false;
  }

  // ---------------------------------------------------------------------------
  // Social / OAuth Sign In (Google, Facebook)
  // ---------------------------------------------------------------------------

  Future<bool> signInWithOAuth({required String strategy}) async {
    _status = AuthStatus.error;
    _errorMessage = 'OAuth sign-in is not enabled on this backend yet.';
    notifyListeners();
    return false;
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();
    await _apiService.logout();

    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }
}
