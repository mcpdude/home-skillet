import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:home_skillet_mobile/providers/auth_provider.dart';
import 'package:home_skillet_mobile/models/auth_models.dart';
import 'package:home_skillet_mobile/models/user.dart';
import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('AuthProvider', () {
    late AuthProvider authProvider;
    late MockAuthService mockAuthService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockStorageService = MockStorageService();
      authProvider = AuthProvider(
        authService: mockAuthService,
        storageService: mockStorageService,
      );
    });

    group('initialization', () {
      test('should set status to authenticated when valid token exists', () async {
        // Arrange
        when(mockStorageService.getAccessToken())
            .thenAnswer((_) async => 'valid_token');
        when(mockAuthService.getCurrentUser())
            .thenAnswer((_) async => User.fromJson(TestData.mockUser));

        // Act
        await authProvider.initialize();

        // Assert
        ProviderTestHelpers.verifyAuthProviderState(
          authProvider,
          expectedStatus: AuthStatus.authenticated,
          expectedLoading: false,
          expectedAuthenticated: true,
        );
      });

      test('should set status to unauthenticated when no token exists', () async {
        // Arrange
        when(mockStorageService.getAccessToken())
            .thenAnswer((_) async => null);

        // Act
        await authProvider.initialize();

        // Assert
        ProviderTestHelpers.verifyAuthProviderState(
          authProvider,
          expectedStatus: AuthStatus.unauthenticated,
          expectedLoading: false,
          expectedAuthenticated: false,
        );
      });

      test('should set status to unauthenticated when token is invalid', () async {
        // Arrange
        when(mockStorageService.getAccessToken())
            .thenAnswer((_) async => 'invalid_token');
        when(mockAuthService.getCurrentUser())
            .thenThrow(Exception('Invalid token'));

        // Act
        await authProvider.initialize();

        // Assert
        ProviderTestHelpers.verifyAuthProviderState(
          authProvider,
          expectedStatus: AuthStatus.unauthenticated,
          expectedLoading: false,
          expectedAuthenticated: false,
        );
      });
    });

    group('login', () {
      test('should set authenticated state when login is successful', () async {
        // Arrange
        final mockResponse = AuthResponse.fromJson(TestData.mockAuthResponse);
        when(mockAuthService.login(any))
            .thenAnswer((_) async => mockResponse);
        when(mockStorageService.saveTokens(
          accessToken: anyNamed('accessToken'),
          refreshToken: anyNamed('refreshToken'),
        )).thenAnswer((_) async {});

        // Act
        final result = await authProvider.login('test@example.com', 'password123');

        // Assert
        expect(result, isTrue);
        ProviderTestHelpers.verifyAuthProviderState(
          authProvider,
          expectedStatus: AuthStatus.authenticated,
          expectedLoading: false,
          expectedAuthenticated: true,
        );
        expect(authProvider.user?.email, equals('test@example.com'));

        verify(mockStorageService.saveTokens(
          accessToken: 'mock_access_token',
          refreshToken: 'mock_refresh_token',
        )).called(1);
      });

      test('should set error state when login fails', () async {
        // Arrange
        when(mockAuthService.login(any))
            .thenThrow(Exception('Invalid credentials'));

        // Act
        final result = await authProvider.login('test@example.com', 'wrong_password');

        // Assert
        expect(result, isFalse);
        ProviderTestHelpers.verifyAuthProviderState(
          authProvider,
          expectedStatus: AuthStatus.error,
          expectedLoading: false,
          expectedAuthenticated: false,
        );
        expect(authProvider.errorMessage, contains('Invalid credentials'));
      });

      test('should set loading state during login process', () async {
        // Arrange
        final mockResponse = AuthResponse.fromJson(TestData.mockAuthResponse);
        when(mockAuthService.login(any))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 100));
              return mockResponse;
            });
        when(mockStorageService.saveTokens(
          accessToken: anyNamed('accessToken'),
          refreshToken: anyNamed('refreshToken'),
        )).thenAnswer((_) async {});

        // Act
        final loginFuture = authProvider.login('test@example.com', 'password123');
        
        // Assert loading state
        expect(authProvider.isLoading, isTrue);
        
        await loginFuture;
        
        // Assert final state
        expect(authProvider.isLoading, isFalse);
      });
    });

    group('register', () {
      test('should set authenticated state when registration is successful', () async {
        // Arrange
        final mockResponse = AuthResponse.fromJson(TestData.mockAuthResponse);
        when(mockAuthService.register(any))
            .thenAnswer((_) async => mockResponse);
        when(mockStorageService.saveTokens(
          accessToken: anyNamed('accessToken'),
          refreshToken: anyNamed('refreshToken'),
        )).thenAnswer((_) async {});

        // Act
        final result = await authProvider.register(
          email: 'test@example.com',
          password: 'password123',
          firstName: 'John',
          lastName: 'Doe',
        );

        // Assert
        expect(result, isTrue);
        ProviderTestHelpers.verifyAuthProviderState(
          authProvider,
          expectedStatus: AuthStatus.authenticated,
          expectedLoading: false,
          expectedAuthenticated: true,
        );
        expect(authProvider.user?.email, equals('test@example.com'));
      });

      test('should set error state when registration fails', () async {
        // Arrange
        when(mockAuthService.register(any))
            .thenThrow(Exception('Email already exists'));

        // Act
        final result = await authProvider.register(
          email: 'existing@example.com',
          password: 'password123',
          firstName: 'John',
          lastName: 'Doe',
        );

        // Assert
        expect(result, isFalse);
        ProviderTestHelpers.verifyAuthProviderState(
          authProvider,
          expectedStatus: AuthStatus.error,
          expectedLoading: false,
          expectedAuthenticated: false,
        );
        expect(authProvider.errorMessage, contains('Email already exists'));
      });
    });

    group('logout', () {
      test('should clear user state and set unauthenticated status', () async {
        // Arrange - Set up authenticated state first by logging in
        final mockResponse = AuthResponse.fromJson(TestData.mockAuthResponse);
        when(mockAuthService.login(any)).thenAnswer((_) async => mockResponse);
        when(mockStorageService.saveTokens(
          accessToken: anyNamed('accessToken'),
          refreshToken: anyNamed('refreshToken'),
        )).thenAnswer((_) async {});
        
        await authProvider.login('test@example.com', 'password123');
        
        when(mockAuthService.logout()).thenAnswer((_) async {});
        when(mockStorageService.clearTokens()).thenAnswer((_) async {});

        // Act
        await authProvider.logout();

        // Assert
        ProviderTestHelpers.verifyAuthProviderState(
          authProvider,
          expectedStatus: AuthStatus.unauthenticated,
          expectedLoading: false,
          expectedAuthenticated: false,
        );
        expect(authProvider.user, isNull);
        expect(authProvider.errorMessage, isNull);

        verify(mockStorageService.clearTokens()).called(1);
      });

      test('should clear local state even if API call fails', () async {
        // Arrange - Set up authenticated state first by logging in
        final mockResponse = AuthResponse.fromJson(TestData.mockAuthResponse);
        when(mockAuthService.login(any)).thenAnswer((_) async => mockResponse);
        when(mockStorageService.saveTokens(
          accessToken: anyNamed('accessToken'),
          refreshToken: anyNamed('refreshToken'),
        )).thenAnswer((_) async {});
        
        await authProvider.login('test@example.com', 'password123');
        
        when(mockAuthService.logout()).thenThrow(Exception('Network error'));
        when(mockStorageService.clearTokens()).thenAnswer((_) async {});

        // Act
        await authProvider.logout();

        // Assert
        ProviderTestHelpers.verifyAuthProviderState(
          authProvider,
          expectedStatus: AuthStatus.unauthenticated,
          expectedLoading: false,
          expectedAuthenticated: false,
        );
        expect(authProvider.user, isNull);

        verify(mockStorageService.clearTokens()).called(1);
      });
    });

    group('refreshToken', () {
      test('should return true and update tokens when refresh is successful', () async {
        // Arrange
        final mockResponse = AuthResponse.fromJson(TestData.mockAuthResponse);
        when(mockStorageService.getRefreshToken())
            .thenAnswer((_) async => 'valid_refresh_token');
        when(mockAuthService.refreshToken(any))
            .thenAnswer((_) async => mockResponse);
        when(mockStorageService.saveTokens(
          accessToken: anyNamed('accessToken'),
          refreshToken: anyNamed('refreshToken'),
        )).thenAnswer((_) async {});

        // Act
        final result = await authProvider.refreshToken();

        // Assert
        expect(result, isTrue);
        verify(mockStorageService.saveTokens(
          accessToken: 'mock_access_token',
          refreshToken: 'mock_refresh_token',
        )).called(1);
      });

      test('should logout and return false when refresh fails', () async {
        // Arrange
        when(mockStorageService.getRefreshToken())
            .thenAnswer((_) async => 'invalid_refresh_token');
        when(mockAuthService.refreshToken(any))
            .thenThrow(Exception('Refresh failed'));
        when(mockAuthService.logout()).thenAnswer((_) async {});
        when(mockStorageService.clearTokens()).thenAnswer((_) async {});

        // Act
        final result = await authProvider.refreshToken();

        // Assert
        expect(result, isFalse);
        ProviderTestHelpers.verifyAuthProviderState(
          authProvider,
          expectedStatus: AuthStatus.unauthenticated,
          expectedAuthenticated: false,
        );
        verify(mockStorageService.clearTokens()).called(1);
      });

      test('should logout and return false when no refresh token exists', () async {
        // Arrange
        when(mockStorageService.getRefreshToken())
            .thenAnswer((_) async => null);
        when(mockAuthService.logout()).thenAnswer((_) async {});
        when(mockStorageService.clearTokens()).thenAnswer((_) async {});

        // Act
        final result = await authProvider.refreshToken();

        // Assert
        expect(result, isFalse);
        verify(mockStorageService.clearTokens()).called(1);
      });
    });

    group('updateProfile', () {
      test('should update user when profile update is successful', () async {
        // Arrange
        final originalUser = User.fromJson(TestData.mockUser);
        final updatedUserData = Map<String, dynamic>.from(TestData.mockUser);
        updatedUserData['first_name'] = 'Jane';
        final updatedUser = User.fromJson(updatedUserData);
        
        when(mockAuthService.updateProfile(any))
            .thenAnswer((_) async => updatedUser);

        // Act
        final result = await authProvider.updateProfile(updatedUser);

        // Assert
        expect(result, isTrue);
        expect(authProvider.user?.firstName, equals('Jane'));
        ProviderTestHelpers.verifyAuthProviderState(
          authProvider,
          expectedLoading: false,
        );
      });

      test('should set error state when profile update fails', () async {
        // Arrange
        final user = User.fromJson(TestData.mockUser);
        when(mockAuthService.updateProfile(any))
            .thenThrow(Exception('Update failed'));

        // Act
        final result = await authProvider.updateProfile(user);

        // Assert
        expect(result, isFalse);
        expect(authProvider.errorMessage, contains('Update failed'));
      });
    });
  });
}