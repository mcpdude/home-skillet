import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';

import 'package:home_skillet_mobile/services/auth_service.dart';
import 'package:home_skillet_mobile/models/auth_models.dart';
import 'package:home_skillet_mobile/models/user.dart';
import 'package:home_skillet_mobile/config/api_config.dart';
import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      authService = AuthService(httpClient: mockHttpClient);
    });

    group('login', () {
      test('should return AuthResponse when login is successful', () async {
        // Arrange
        final loginRequest = LoginRequest.fromJson(TestData.mockLoginRequest);
        final expectedResponse = Response<Map<String, dynamic>>(
          data: TestData.mockAuthResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await authService.login(loginRequest);

        // Assert
        expect(result, isA<AuthResponse>());
        expect(result.accessToken, equals('mock_access_token'));
        expect(result.refreshToken, equals('mock_refresh_token'));
        expect(result.user['email'], equals('test@example.com'));
        
        verify(mockHttpClient.post('/auth/login', data: loginRequest.toJson(), forceNodeBackend: true)).called(1);
      });

      test('should throw exception when login fails with 401', () async {
        // Arrange
        final loginRequest = LoginRequest.fromJson(TestData.mockLoginRequest);
        
        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 401,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => authService.login(loginRequest),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Invalid email or password')
          )),
        );
      });

      test('should throw exception when login fails with 400', () async {
        // Arrange
        final loginRequest = LoginRequest.fromJson(TestData.mockLoginRequest);
        
        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 400,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => authService.login(loginRequest),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Please check your email and password')
          )),
        );
      });

      test('should throw generic exception for other errors', () async {
        // Arrange
        final loginRequest = LoginRequest.fromJson(TestData.mockLoginRequest);
        
        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 500,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => authService.login(loginRequest),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Login failed. Please try again.')
          )),
        );
      });
    });

    group('register', () {
      test('should return AuthResponse when registration is successful', () async {
        // Arrange
        final registerRequest = RegisterRequest.fromJson(TestData.mockRegisterRequest);
        final expectedResponse = Response<Map<String, dynamic>>(
          data: TestData.mockAuthResponse,
          statusCode: 201,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await authService.register(registerRequest);

        // Assert
        expect(result, isA<AuthResponse>());
        expect(result.accessToken, equals('mock_access_token'));
        expect(result.refreshToken, equals('mock_refresh_token'));
        
        verify(mockHttpClient.post('/auth/register', data: registerRequest.toJson(), forceNodeBackend: true)).called(1);
      });

      test('should throw exception when email already exists', () async {
        // Arrange
        final registerRequest = RegisterRequest.fromJson(TestData.mockRegisterRequest);
        
        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 409,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => authService.register(registerRequest),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('An account with this email already exists')
          )),
        );
      });
    });

    group('refreshToken', () {
      test('should return AuthResponse when token refresh is successful', () async {
        // Arrange
        final refreshRequest = RefreshTokenRequest(refreshToken: 'mock_refresh_token');
        final expectedResponse = Response<Map<String, dynamic>>(
          data: TestData.mockAuthResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await authService.refreshToken(refreshRequest);

        // Assert
        expect(result, isA<AuthResponse>());
        expect(result.accessToken, equals('mock_access_token'));
        
        verify(mockHttpClient.post('/auth/refresh', data: refreshRequest.toJson())).called(1);
      });

      test('should throw exception when refresh fails', () async {
        // Arrange
        final refreshRequest = RefreshTokenRequest(refreshToken: 'invalid_token');
        
        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 401,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => authService.refreshToken(refreshRequest),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Session expired. Please log in again.')
          )),
        );
      });
    });

    group('getCurrentUser', () {
      test('should return User when request is successful', () async {
        // Arrange
        final expectedResponse = Response<Map<String, dynamic>>(
          data: TestData.mockUser,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.get(any))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await authService.getCurrentUser();

        // Assert
        expect(result, isA<User>());
        expect(result.email, equals('test@example.com'));
        expect(result.firstName, equals('John'));
        expect(result.lastName, equals('Doe'));
        
        verify(mockHttpClient.get('/users/profile')).called(1);
      });

      test('should throw exception when request fails', () async {
        // Arrange
        when(mockHttpClient.get(any))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 401,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => authService.getCurrentUser(),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Failed to load user profile')
          )),
        );
      });
    });

    group('updateProfile', () {
      test('should return updated User when request is successful', () async {
        // Arrange
        final user = User.fromJson(TestData.mockUser);
        final updatedUserData = Map<String, dynamic>.from(TestData.mockUser);
        updatedUserData['first_name'] = 'Jane';
        
        final expectedResponse = Response<Map<String, dynamic>>(
          data: updatedUserData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.put(any, data: anyNamed('data')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await authService.updateProfile(user);

        // Assert
        expect(result, isA<User>());
        expect(result.firstName, equals('Jane'));
        
        verify(mockHttpClient.put('/users/profile', data: user.toJson())).called(1);
      });
    });

    group('changePassword', () {
      test('should complete successfully when password change is successful', () async {
        // Arrange
        final expectedResponse = Response<Map<String, dynamic>>(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.put(any, data: anyNamed('data')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        await authService.changePassword(
          currentPassword: 'oldpassword',
          newPassword: 'newpassword',
        );

        // Assert
        verify(mockHttpClient.put('/auth/change-password', data: {
          'current_password': 'oldpassword',
          'new_password': 'newpassword',
        })).called(1);
      });

      test('should throw exception when current password is incorrect', () async {
        // Arrange
        when(mockHttpClient.put(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 400,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => authService.changePassword(
            currentPassword: 'wrongpassword',
            newPassword: 'newpassword',
          ),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Current password is incorrect')
          )),
        );
      });
    });

    group('logout', () {
      test('should complete without throwing when logout API succeeds', () async {
        // Arrange
        final expectedResponse = Response<Map<String, dynamic>>(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(any, forceNodeBackend: anyNamed('forceNodeBackend')))
            .thenAnswer((_) async => expectedResponse);

        // Act & Assert
        expect(() => authService.logout(), returnsNormally);
        
        verify(mockHttpClient.post('/auth/logout', forceNodeBackend: true)).called(1);
      });

      test('should complete without throwing even when logout API fails', () async {
        // Arrange
        when(mockHttpClient.post(any, forceNodeBackend: anyNamed('forceNodeBackend')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
            ));

        // Act & Assert
        expect(() => authService.logout(), returnsNormally);
      });
    });

    group('requestPasswordReset', () {
      test('should complete successfully when password reset request succeeds', () async {
        // Arrange
        const email = 'test@example.com';
        final expectedResponse = Response<Map<String, dynamic>>(
          data: {'message': 'Password reset email sent'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        await authService.requestPasswordReset(email);

        // Assert
        verify(mockHttpClient.post('/auth/forgot-password', data: {'email': email})).called(1);
      });

      test('should throw exception when password reset request fails', () async {
        // Arrange
        const email = 'test@example.com';
        
        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 400,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => authService.requestPasswordReset(email),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Failed to request password reset')
          )),
        );
      });
    });

    group('resetPassword', () {
      test('should complete successfully when password reset succeeds', () async {
        // Arrange
        const token = 'reset_token_123';
        const newPassword = 'newpassword123';
        final expectedResponse = Response<Map<String, dynamic>>(
          data: {'message': 'Password reset successful'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        await authService.resetPassword(token: token, newPassword: newPassword);

        // Assert
        verify(mockHttpClient.post('/auth/reset-password', data: {
          'token': token,
          'new_password': newPassword,
        })).called(1);
      });

      test('should throw exception when reset token is invalid', () async {
        // Arrange
        const token = 'invalid_token';
        const newPassword = 'newpassword123';
        
        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 400,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => authService.resetPassword(token: token, newPassword: newPassword),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Invalid or expired reset token')
          )),
        );
      });
    });

    group('verifyEmail', () {
      test('should complete successfully when email verification succeeds', () async {
        // Arrange
        const token = 'verify_token_123';
        final expectedResponse = Response<Map<String, dynamic>>(
          data: {'message': 'Email verified successfully'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => expectedResponse);

        // Act
        await authService.verifyEmail(token);

        // Assert
        verify(mockHttpClient.post('/auth/verify-email', data: {'token': token})).called(1);
      });

      test('should throw exception when verification token is invalid', () async {
        // Arrange
        const token = 'invalid_token';
        
        when(mockHttpClient.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 400,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act & Assert
        expect(
          () => authService.verifyEmail(token),
          throwsA(predicate((e) => 
            e is Exception && 
            e.toString().contains('Invalid verification token')
          )),
        );
      });
    });

    group('authentication state', () {
      test('should return correct authentication state for JWT', () {
        // Act & Assert
        expect(authService.isLoggedIn, isFalse); // Will be false since we can't access storage service directly
        expect(authService.currentUserId, isNull);
      });
    });
  });
}