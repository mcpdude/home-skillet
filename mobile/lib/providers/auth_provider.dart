import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  AuthProvider({
    required AuthService authService,
    required StorageService storageService,
  })  : _authService = authService,
        _storageService = storageService;

  final AuthService _authService;
  final StorageService _storageService;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;

  // Initialize authentication state
  Future<void> initialize() async {
    try {
      _setLoading(true);
      
      final accessToken = await _storageService.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        // Validate token by getting user info
        final user = await _authService.getCurrentUser();
        _setUser(user);
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _setStatus(AuthStatus.unauthenticated);
      _clearError(); // Don't show error on initialization
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final request = LoginRequest(email: email, password: password);
      final response = await _authService.login(request);
      
      // Store tokens
      await _storageService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      // Parse and store user
      final user = User.fromJson(response.user);
      _setUser(user);
      _setStatus(AuthStatus.authenticated);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      _setStatus(AuthStatus.error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final request = RegisterRequest(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      
      final response = await _authService.register(request);
      
      // Store tokens
      await _storageService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      // Parse and store user
      final user = User.fromJson(response.user);
      _setUser(user);
      _setStatus(AuthStatus.authenticated);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      _setStatus(AuthStatus.error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _setLoading(true);
      
      // Call logout API if needed
      try {
        await _authService.logout();
      } catch (e) {
        // Continue with logout even if API call fails
        debugPrint('Logout API call failed: $e');
      }
      
      // Clear stored tokens
      await _storageService.clearTokens();
      
      // Clear user state
      _setUser(null);
      _setStatus(AuthStatus.unauthenticated);
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) {
        await logout();
        return false;
      }

      final request = RefreshTokenRequest(refreshToken: refreshToken);
      final response = await _authService.refreshToken(request);
      
      // Store new tokens
      await _storageService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile(User updatedUser) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authService.updateProfile(updatedUser);
      _setUser(user);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}