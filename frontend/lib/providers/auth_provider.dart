import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Indicates sign-up succeeded but the user must verify their e-mail.
enum PendingAction { none, emailVerification }

class AuthProvider extends ChangeNotifier {
  final ClerkService _clerkService;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  PendingAction _pendingAction = PendingAction.none;
  String? _pendingSignUpId;

  AuthProvider({ClerkService? clerkService})
    : _clerkService = clerkService ?? ClerkService() {
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
  ClerkService get clerkService => _clerkService;

  // ---------------------------------------------------------------------------
  // Initialise – check for an existing Clerk session
  // ---------------------------------------------------------------------------

  Future<void> _initializeAuth() async {
    try {
      final loggedIn = await _clerkService.isLoggedIn();
      if (loggedIn) {
        // Attempt to refresh the token to confirm the session is still valid
        final jwt = await _clerkService.refreshSessionToken();
        if (jwt != null) {
          _status = AuthStatus.authenticated;
        } else {
          await _clerkService.clearSession();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
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

      _user = await _clerkService.signIn(email: email, password: password);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ClerkException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
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

      _user = await _clerkService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ClerkException catch (e) {
      // If Clerk requires email verification, the service throws a special
      // message containing the sign-up ID. Intercept it here.
      if (e.message.startsWith('VERIFY_EMAIL:')) {
        _pendingSignUpId = e.message.replaceFirst('VERIFY_EMAIL:', '');
        _pendingAction = PendingAction.emailVerification;
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
        notifyListeners();
        return false;
      }

      _status = AuthStatus.error;
      _errorMessage = e.message;
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
    if (_pendingSignUpId == null) return false;

    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _user = await _clerkService.verifyEmail(
        signUpId: _pendingSignUpId!,
        code: code,
      );

      _pendingAction = PendingAction.none;
      _pendingSignUpId = null;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ClerkException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Verification failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Social / OAuth Sign In (Google, Facebook)
  // ---------------------------------------------------------------------------

  Future<bool> signInWithOAuth({required String strategy}) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _user = await _clerkService.signInWithOAuth(strategy: strategy);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ClerkException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'OAuth sign-in failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _clerkService.signOut();
    } catch (_) {
      // Clear local state regardless
    }

    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }
}
