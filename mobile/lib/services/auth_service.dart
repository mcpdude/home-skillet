import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../config/supabase_config.dart';
import '../models/auth_models.dart';
import '../models/user.dart';
import '../services/http_client.dart';
import '../services/supabase_service.dart';

class AuthService {
  final HttpClient _httpClient;

  AuthService({required HttpClient httpClient}) : _httpClient = httpClient;

  // Helper method to determine auth method
  bool get _shouldUseSupabaseAuth => 
    SupabaseConfig.enableAuth && 
    SupabaseConfig.isConfigured() && 
    (ApiConfig.isUsingSupabase || ApiConfig.isUsingHybrid);

  // Login user - supports both JWT and Supabase Auth
  Future<AuthResponse> login(LoginRequest request) async {
    if (_shouldUseSupabaseAuth) {
      return _loginWithSupabase(request);
    } else {
      return _loginWithJWT(request);
    }
  }

  // JWT-based login (primary method)
  Future<AuthResponse> _loginWithJWT(LoginRequest request) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.authEndpoint}/login',
        data: request.toJson(),
        forceNodeBackend: true, // Always use Node.js backend for JWT auth
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(response.data);
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('401')) {
        throw Exception('Invalid email or password');
      } else if (e.toString().contains('400')) {
        throw Exception('Please check your email and password');
      } else {
        throw Exception('Login failed. Please try again.');
      }
    }
  }

  // Supabase Auth-based login (optional)
  Future<AuthResponse> _loginWithSupabase(LoginRequest request) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: request.email,
        password: request.password,
      );

      if (response.user != null && response.session != null) {
        // Convert Supabase user to our User model
        final user = User(
          id: response.user!.id,
          email: response.user!.email ?? '',
          firstName: response.user!.userMetadata?['first_name'] ?? '',
          lastName: response.user!.userMetadata?['last_name'] ?? '',
          phone: response.user!.userMetadata?['phone'],
          isActive: true,
          emailVerified: response.user!.emailConfirmedAt != null,
          createdAt: response.user!.createdAt,
          updatedAt: response.user!.updatedAt,
        );

        return AuthResponse(
          accessToken: response.session!.accessToken,
          refreshToken: response.session!.refreshToken ?? '',
          user: user,
          expiresIn: response.session!.expiresIn ?? 3600,
          tokenType: 'Bearer',
        );
      } else {
        throw Exception('Login failed: Invalid credentials');
      }
    } catch (e) {
      if (e is AuthException) {
        switch (e.statusCode) {
          case '400':
            throw Exception('Invalid email or password');
          case '422':
            throw Exception('Email not confirmed');
          default:
            throw Exception('Login failed: ${e.message}');
        }
      } else {
        throw Exception('Login failed. Please try again.');
      }
    }
  }

  // Register new user - supports both JWT and Supabase Auth
  Future<AuthResponse> register(RegisterRequest request) async {
    if (_shouldUseSupabaseAuth) {
      return _registerWithSupabase(request);
    } else {
      return _registerWithJWT(request);
    }
  }

  // JWT-based registration (primary method)
  Future<AuthResponse> _registerWithJWT(RegisterRequest request) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.authEndpoint}/register',
        data: request.toJson(),
        forceNodeBackend: true, // Always use Node.js backend for JWT auth
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AuthResponse.fromJson(response.data);
      } else {
        throw Exception('Registration failed: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('409')) {
        throw Exception('An account with this email already exists');
      } else if (e.toString().contains('400')) {
        throw Exception('Please check your information and try again');
      } else {
        throw Exception('Registration failed. Please try again.');
      }
    }
  }

  // Supabase Auth-based registration (optional)
  Future<AuthResponse> _registerWithSupabase(RegisterRequest request) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: request.email,
        password: request.password,
        data: {
          'first_name': request.firstName,
          'last_name': request.lastName,
          'phone': request.phone,
        },
      );

      if (response.user != null) {
        // Convert Supabase user to our User model
        final user = User(
          id: response.user!.id,
          email: response.user!.email ?? '',
          firstName: request.firstName,
          lastName: request.lastName,
          phone: request.phone,
          isActive: true,
          emailVerified: response.user!.emailConfirmedAt != null,
          createdAt: response.user!.createdAt,
          updatedAt: response.user!.updatedAt,
        );

        return AuthResponse(
          accessToken: response.session?.accessToken ?? '',
          refreshToken: response.session?.refreshToken ?? '',
          user: user,
          expiresIn: response.session?.expiresIn ?? 3600,
          tokenType: 'Bearer',
        );
      } else {
        throw Exception('Registration failed: Unable to create account');
      }
    } catch (e) {
      if (e is AuthException) {
        switch (e.statusCode) {
          case '422':
            throw Exception('An account with this email already exists');
          case '400':
            throw Exception('Please check your information and try again');
          default:
            throw Exception('Registration failed: ${e.message}');
        }
      } else {
        throw Exception('Registration failed. Please try again.');
      }
    }
  }

  // Refresh access token
  Future<AuthResponse> refreshToken(RefreshTokenRequest request) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.authEndpoint}/refresh',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(response.data);
      } else {
        throw Exception('Token refresh failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Session expired. Please log in again.');
    }
  }

  // Get current user profile
  Future<User> getCurrentUser() async {
    try {
      final response = await _httpClient.get('${ApiConfig.usersEndpoint}/profile');

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      } else {
        throw Exception('Failed to get user profile: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load user profile');
    }
  }

  // Update user profile
  Future<User> updateProfile(User user) async {
    try {
      final response = await _httpClient.put(
        '${ApiConfig.usersEndpoint}/profile',
        data: user.toJson(),
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      } else {
        throw Exception('Failed to update profile: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to update profile');
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _httpClient.put(
        '${ApiConfig.authEndpoint}/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to change password: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('400')) {
        throw Exception('Current password is incorrect');
      } else {
        throw Exception('Failed to change password');
      }
    }
  }

  // Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.authEndpoint}/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to request password reset: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to request password reset');
    }
  }

  // Reset password with token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.authEndpoint}/reset-password',
        data: {
          'token': token,
          'new_password': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reset password: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('400')) {
        throw Exception('Invalid or expired reset token');
      } else {
        throw Exception('Failed to reset password');
      }
    }
  }

  // Verify email
  Future<void> verifyEmail(String token) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.authEndpoint}/verify-email',
        data: {'token': token},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to verify email: ${response.statusMessage}');
      }
    } catch (e) {
      if (e.toString().contains('400')) {
        throw Exception('Invalid verification token');
      } else {
        throw Exception('Failed to verify email');
      }
    }
  }

  // Logout - supports both JWT and Supabase Auth
  Future<void> logout() async {
    if (_shouldUseSupabaseAuth) {
      await _logoutFromSupabase();
    } else {
      await _logoutFromJWT();
    }
  }

  // JWT-based logout (primary method)
  Future<void> _logoutFromJWT() async {
    try {
      await _httpClient.post(
        '${ApiConfig.authEndpoint}/logout',
        forceNodeBackend: true,
      );
    } catch (e) {
      // Logout errors are non-critical, we clear local storage regardless
    }
  }

  // Supabase Auth-based logout (optional)
  Future<void> _logoutFromSupabase() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      // Logout errors are non-critical
    }
  }

  // Auth state helpers
  bool get isLoggedIn {
    if (_shouldUseSupabaseAuth) {
      return SupabaseService.instance.isAuthenticated;
    }
    // For JWT, we need to check storage service (implement in auth provider)
    return false;
  }

  String? get currentUserId {
    if (_shouldUseSupabaseAuth) {
      return SupabaseService.instance.currentUserId;
    }
    // For JWT, we need to check storage service (implement in auth provider)
    return null;
  }
}