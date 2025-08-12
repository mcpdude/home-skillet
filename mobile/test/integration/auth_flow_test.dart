import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:home_skillet_mobile/screens/auth/login_screen.dart';
import 'package:home_skillet_mobile/screens/auth/register_screen.dart';
import 'package:home_skillet_mobile/screens/auth/forgot_password_screen.dart';
import 'package:home_skillet_mobile/providers/auth_provider.dart';
import 'package:home_skillet_mobile/services/auth_service.dart';
import 'package:home_skillet_mobile/services/storage_service.dart';
import 'package:home_skillet_mobile/models/auth_models.dart';
import 'package:home_skillet_mobile/models/user.dart';
import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    late MockAuthService mockAuthService;
    late MockStorageService mockStorageService;
    late AuthProvider authProvider;

    setUp(() {
      mockAuthService = MockAuthService();
      mockStorageService = MockStorageService();
      authProvider = AuthProvider(
        authService: mockAuthService,
        storageService: mockStorageService,
      );
    });

    group('Login Flow', () {
      testWidgets('successful login flow should authenticate user and store tokens', (WidgetTester tester) async {
        // Arrange
        final mockResponse = AuthResponse.fromJson(TestData.mockAuthResponse);
        when(mockAuthService.login(any)).thenAnswer((_) async => mockResponse);
        when(mockStorageService.saveTokens(
          accessToken: anyNamed('accessToken'),
          refreshToken: anyNamed('refreshToken'),
        )).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: const LoginScreen(),
            ),
          ),
        );

        // Act - Fill login form
        await tester.enterText(find.byKey(const Key('login_email_field')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('login_password_field')), 'password123');
        await tester.pump();

        // Submit form
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert
        verify(mockAuthService.login(any)).called(1);
        verify(mockStorageService.saveTokens(
          accessToken: 'mock_access_token',
          refreshToken: 'mock_refresh_token',
        )).called(1);
        
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.user?.email, equals('test@example.com'));
        expect(authProvider.status, equals(AuthStatus.authenticated));
      });

      testWidgets('failed login should show error and not authenticate', (WidgetTester tester) async {
        // Arrange
        when(mockAuthService.login(any)).thenThrow(Exception('Invalid credentials'));

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: const LoginScreen(),
            ),
          ),
        );

        // Act - Fill login form with invalid credentials
        await tester.enterText(find.byKey(const Key('login_email_field')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('login_password_field')), 'wrongpassword');
        await tester.pump();

        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.status, equals(AuthStatus.error));
        expect(authProvider.errorMessage, contains('Invalid credentials'));
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('form validation should prevent submission with invalid data', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: const LoginScreen(),
            ),
          ),
        );

        // Act - Try to submit with invalid email
        await tester.enterText(find.byKey(const Key('login_email_field')), 'invalid-email');
        await tester.enterText(find.byKey(const Key('login_password_field')), 'short');
        await tester.pump();

        // Button should be disabled
        final loginButton = find.widgetWithText(ElevatedButton, 'Sign In');
        final ElevatedButton buttonWidget = tester.widget(loginButton);
        expect(buttonWidget.onPressed, isNull);

        // Try to submit anyway
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pump();

        // Assert - Should show validation errors
        expect(find.text('Please enter a valid email address'), findsOneWidget);
        expect(find.text('Password must be at least 8 characters'), findsOneWidget);
        verifyNever(mockAuthService.login(any));
      });
    });

    group('Registration Flow', () {
      testWidgets('successful registration flow should authenticate user', (WidgetTester tester) async {
        // Arrange
        final mockResponse = AuthResponse.fromJson(TestData.mockAuthResponse);
        when(mockAuthService.register(any)).thenAnswer((_) async => mockResponse);
        when(mockStorageService.saveTokens(
          accessToken: anyNamed('accessToken'),
          refreshToken: anyNamed('refreshToken'),
        )).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: const RegisterScreen(),
            ),
          ),
        );

        // Act - Fill registration form
        await tester.enterText(find.byKey(const Key('register_first_name_field')), 'John');
        await tester.enterText(find.byKey(const Key('register_last_name_field')), 'Doe');
        await tester.enterText(find.byKey(const Key('register_email_field')), 'john@example.com');
        await tester.enterText(find.byKey(const Key('register_password_field')), 'Password123!');
        await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'Password123!');
        await tester.pump();

        // Submit form
        await tester.tap(find.byKey(const Key('register_button')));
        await tester.pumpAndSettle();

        // Assert
        verify(mockAuthService.register(any)).called(1);
        verify(mockStorageService.saveTokens(
          accessToken: 'mock_access_token',
          refreshToken: 'mock_refresh_token',
        )).called(1);
        
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.user?.email, equals('test@example.com'));
        expect(authProvider.status, equals(AuthStatus.authenticated));
      });

      testWidgets('registration with existing email should show error', (WidgetTester tester) async {
        // Arrange
        when(mockAuthService.register(any)).thenThrow(Exception('Email already exists'));

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: const RegisterScreen(),
            ),
          ),
        );

        // Act - Fill registration form
        await tester.enterText(find.byKey(const Key('register_first_name_field')), 'John');
        await tester.enterText(find.byKey(const Key('register_last_name_field')), 'Doe');
        await tester.enterText(find.byKey(const Key('register_email_field')), 'existing@example.com');
        await tester.enterText(find.byKey(const Key('register_password_field')), 'Password123!');
        await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'Password123!');
        await tester.pump();

        await tester.tap(find.byKey(const Key('register_button')));
        await tester.pumpAndSettle();

        // Assert
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.status, equals(AuthStatus.error));
        expect(authProvider.errorMessage, contains('Email already exists'));
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('registration form validation should work correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: const RegisterScreen(),
            ),
          ),
        );

        // Act - Fill form with mismatched passwords
        await tester.enterText(find.byKey(const Key('register_first_name_field')), 'John');
        await tester.enterText(find.byKey(const Key('register_last_name_field')), 'Doe');
        await tester.enterText(find.byKey(const Key('register_email_field')), 'john@example.com');
        await tester.enterText(find.byKey(const Key('register_password_field')), 'Password123!');
        await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'DifferentPassword');
        await tester.pump();

        // Try to submit
        await tester.tap(find.byKey(const Key('register_button')));
        await tester.pump();

        // Assert - Should show validation error
        expect(find.text('Passwords do not match'), findsOneWidget);
        verifyNever(mockAuthService.register(any));
      });
    });

    group('Password Reset Flow', () {
      testWidgets('successful password reset request should show success message', (WidgetTester tester) async {
        // Arrange
        when(mockAuthService.requestPasswordReset(any)).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: Provider<AuthService>(
              create: (_) => mockAuthService,
              child: const ForgotPasswordScreen(),
            ),
          ),
        );

        // Act - Request password reset
        await tester.enterText(find.byKey(const Key('forgot_password_email_field')), 'test@example.com');
        await tester.pump();

        await tester.tap(find.byKey(const Key('forgot_password_send_button')));
        await tester.pumpAndSettle();

        // Assert
        verify(mockAuthService.requestPasswordReset('test@example.com')).called(1);
        expect(find.text('Email Sent!'), findsOneWidget);
        expect(find.textContaining('test@example.com'), findsOneWidget);
      });

      testWidgets('failed password reset request should show error', (WidgetTester tester) async {
        // Arrange
        when(mockAuthService.requestPasswordReset(any)).thenThrow(Exception('User not found'));

        await tester.pumpWidget(
          MaterialApp(
            home: Provider<AuthService>(
              create: (_) => mockAuthService,
              child: const ForgotPasswordScreen(),
            ),
          ),
        );

        // Act - Request password reset with non-existent email
        await tester.enterText(find.byKey(const Key('forgot_password_email_field')), 'nonexistent@example.com');
        await tester.pump();

        await tester.tap(find.byKey(const Key('forgot_password_send_button')));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('User not found'), findsOneWidget);
      });
    });

    group('Authentication State Management', () {
      testWidgets('should maintain authentication state across app lifecycle', (WidgetTester tester) async {
        // Arrange - Simulate existing valid token
        when(mockStorageService.getAccessToken()).thenAnswer((_) async => 'valid_token');
        when(mockAuthService.getCurrentUser()).thenAnswer((_) async => User.fromJson(TestData.mockUser));

        // Act - Initialize auth provider
        await authProvider.initialize();

        // Assert
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.status, equals(AuthStatus.authenticated));
        expect(authProvider.user?.email, equals('test@example.com'));
      });

      testWidgets('should handle token expiration gracefully', (WidgetTester tester) async {
        // Arrange - Set up authenticated state first
        final mockResponse = AuthResponse.fromJson(TestData.mockAuthResponse);
        when(mockAuthService.login(any)).thenAnswer((_) async => mockResponse);
        when(mockStorageService.saveTokens(
          accessToken: anyNamed('accessToken'),
          refreshToken: anyNamed('refreshToken'),
        )).thenAnswer((_) async {});

        await authProvider.login('test@example.com', 'password123');
        expect(authProvider.isAuthenticated, isTrue);

        // Simulate token refresh failure (token expired)
        when(mockStorageService.getRefreshToken()).thenAnswer((_) async => 'expired_token');
        when(mockAuthService.refreshToken(any)).thenThrow(Exception('Token expired'));
        when(mockAuthService.logout()).thenAnswer((_) async {});
        when(mockStorageService.clearTokens()).thenAnswer((_) async {});

        // Act - Try to refresh token
        final result = await authProvider.refreshToken();

        // Assert - Should logout user
        expect(result, isFalse);
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.status, equals(AuthStatus.unauthenticated));
        verify(mockStorageService.clearTokens()).called(1);
      });

      testWidgets('should clear all data on logout', (WidgetTester tester) async {
        // Arrange - Set up authenticated state
        final mockResponse = AuthResponse.fromJson(TestData.mockAuthResponse);
        when(mockAuthService.login(any)).thenAnswer((_) async => mockResponse);
        when(mockStorageService.saveTokens(
          accessToken: anyNamed('accessToken'),
          refreshToken: anyNamed('refreshToken'),
        )).thenAnswer((_) async {});

        await authProvider.login('test@example.com', 'password123');
        expect(authProvider.isAuthenticated, isTrue);

        // Set up logout mocks
        when(mockAuthService.logout()).thenAnswer((_) async {});
        when(mockStorageService.clearTokens()).thenAnswer((_) async {});

        // Act - Logout
        await authProvider.logout();

        // Assert
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.status, equals(AuthStatus.unauthenticated));
        expect(authProvider.user, isNull);
        expect(authProvider.errorMessage, isNull);
        
        verify(mockAuthService.logout()).called(1);
        verify(mockStorageService.clearTokens()).called(1);
      });
    });

    group('Loading States', () {
      testWidgets('should show loading states during authentication operations', (WidgetTester tester) async {
        // Arrange - Set up delayed response
        final mockResponse = AuthResponse.fromJson(TestData.mockAuthResponse);
        when(mockAuthService.login(any)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 500));
          return mockResponse;
        });
        when(mockStorageService.saveTokens(
          accessToken: anyNamed('accessToken'),
          refreshToken: anyNamed('refreshToken'),
        )).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: const LoginScreen(),
            ),
          ),
        );

        // Act - Start login
        await tester.enterText(find.byKey(const Key('login_email_field')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('login_password_field')), 'password123');
        await tester.pump();

        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pump();

        // Assert - Should show loading
        expect(authProvider.isLoading, isTrue);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Signing in...'), findsOneWidget);

        // Wait for completion
        await tester.pumpAndSettle();

        // Assert - Loading should be done
        expect(authProvider.isLoading, isFalse);
        expect(authProvider.isAuthenticated, isTrue);
      });
    });

    group('Form Validation', () {
      testWidgets('should validate all form fields correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: const RegisterScreen(),
            ),
          ),
        );

        // Act - Submit empty form
        await tester.tap(find.byKey(const Key('register_button')));
        await tester.pump();

        // Assert - Should show all validation errors
        expect(find.text('Name is required'), findsNWidgets(2)); // First and last name
        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
        expect(find.text('Confirm password is required'), findsOneWidget);
      });

      testWidgets('should enable submit button only when form is valid', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: authProvider,
              child: const RegisterScreen(),
            ),
          ),
        );

        // Initially disabled
        final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
        ElevatedButton buttonWidget = tester.widget(registerButton);
        expect(buttonWidget.onPressed, isNull);

        // Fill form progressively
        await tester.enterText(find.byKey(const Key('register_first_name_field')), 'John');
        await tester.pump();
        buttonWidget = tester.widget(registerButton);
        expect(buttonWidget.onPressed, isNull); // Still disabled

        await tester.enterText(find.byKey(const Key('register_last_name_field')), 'Doe');
        await tester.enterText(find.byKey(const Key('register_email_field')), 'john@example.com');
        await tester.enterText(find.byKey(const Key('register_password_field')), 'Password123!');
        await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'Password123!');
        await tester.pump();

        // Now should be enabled
        buttonWidget = tester.widget(registerButton);
        expect(buttonWidget.onPressed, isNotNull);
      });
    });
  });
}