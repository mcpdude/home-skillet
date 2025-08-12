import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:home_skillet_mobile/screens/auth/forgot_password_screen.dart';
import 'package:home_skillet_mobile/services/auth_service.dart';
import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('ForgotPasswordScreen Widget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    testWidgets('should display forgot password form elements', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      // Assert
      expect(find.text('Reset Password'), findsOneWidget); // App bar title
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Enter your email address and we\'ll send you a link to reset your password.'), findsOneWidget);
      expect(find.byIcon(Icons.lock_reset), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
    });

    testWidgets('should validate email field with invalid email', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      final emailField = find.byKey(const Key('forgot_password_email_field'));
      final sendButton = find.text('Send Reset Link');

      // Act - Enter invalid email and trigger validation
      await tester.enterText(emailField, 'invalid-email');
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pump();

      // Assert
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('should validate email field when empty', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      final sendButton = find.text('Send Reset Link');

      // Act - Try to submit without email
      await tester.tap(sendButton);
      await tester.pump();

      // Assert
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('should enable send button when email is valid', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      final emailField = find.byKey(const Key('forgot_password_email_field'));

      // Act - Enter valid email
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Assert - Button should be enabled
      final sendButton = find.widgetWithText(ElevatedButton, 'Send Reset Link');
      final ElevatedButton buttonWidget = tester.widget(sendButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('should disable send button when email is invalid', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      // Assert - Button should be disabled initially
      final sendButton = find.widgetWithText(ElevatedButton, 'Send Reset Link');
      final ElevatedButton buttonWidget = tester.widget(sendButton);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('should show loading indicator when sending reset email', (WidgetTester tester) async {
      // Arrange
      when(mockAuthService.requestPasswordReset(any))
          .thenAnswer((_) async => Future.delayed(const Duration(seconds: 1)));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      final emailField = find.byKey(const Key('forgot_password_email_field'));
      final sendButton = find.byKey(const Key('forgot_password_send_button'));

      // Act - Enter email and submit
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pump();

      // Assert - Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Button should be disabled during loading
      final ElevatedButton buttonWidget = tester.widget(sendButton);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('should call auth service when send button is pressed', (WidgetTester tester) async {
      // Arrange
      when(mockAuthService.requestPasswordReset(any))
          .thenAnswer((_) async {});
      
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      final emailField = find.byKey(const Key('forgot_password_email_field'));
      final sendButton = find.byKey(const Key('forgot_password_send_button'));

      // Act - Enter email and submit
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Assert
      verify(mockAuthService.requestPasswordReset('test@example.com')).called(1);
    });

    testWidgets('should show success view after email is sent successfully', (WidgetTester tester) async {
      // Arrange
      when(mockAuthService.requestPasswordReset(any))
          .thenAnswer((_) async {});
      
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      final emailField = find.byKey(const Key('forgot_password_email_field'));
      final sendButton = find.byKey(const Key('forgot_password_send_button'));

      // Act - Send reset email
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Assert - Success view should be shown
      expect(find.text('Email Sent!'), findsOneWidget);
      expect(find.text('We\'ve sent a password reset link to test@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
      expect(find.text('Try Different Email'), findsOneWidget);
    });

    testWidgets('should show error snackbar when sending reset email fails', (WidgetTester tester) async {
      // Arrange
      when(mockAuthService.requestPasswordReset(any))
          .thenThrow(Exception('Failed to send reset email'));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      final emailField = find.byKey(const Key('forgot_password_email_field'));
      final sendButton = find.byKey(const Key('forgot_password_send_button'));

      // Act - Send reset email
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Assert - Error snackbar should be shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Failed to send reset email'), findsOneWidget);
    });

    testWidgets('should return to form view when Try Different Email is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockAuthService.requestPasswordReset(any))
          .thenAnswer((_) async {});
      
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      final emailField = find.byKey(const Key('forgot_password_email_field'));
      final sendButton = find.byKey(const Key('forgot_password_send_button'));

      // First, get to success view
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Act - Tap Try Different Email
      final tryDifferentEmailButton = find.text('Try Different Email');
      await tester.tap(tryDifferentEmailButton);
      await tester.pump();

      // Assert - Should return to form view
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('should submit form when Enter is pressed on email field', (WidgetTester tester) async {
      // Arrange
      when(mockAuthService.requestPasswordReset(any))
          .thenAnswer((_) async {});
      
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      final emailField = find.byKey(const Key('forgot_password_email_field'));

      // Act - Enter email and submit via Enter key
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      verify(mockAuthService.requestPasswordReset('test@example.com')).called(1);
    });

    testWidgets('should navigate back when back button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      
      await tester.tap(backButton);
      await tester.pump();
      // In a full test, we would verify navigation occurred
    });

    testWidgets('should navigate back when Back to Sign In is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      final backToSignInButton = find.text('Back to Sign In');
      expect(backToSignInButton, findsOneWidget);
      
      await tester.tap(backToSignInButton);
      await tester.pump();
      // In a full test, we would verify navigation occurred
    });

    testWidgets('should show proper field labels and hints', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enter your email address'), findsOneWidget);
    });

    testWidgets('should show helpful success message with user email', (WidgetTester tester) async {
      // Arrange
      when(mockAuthService.requestPasswordReset(any))
          .thenAnswer((_) async {});
      
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthService>(
            create: (_) => mockAuthService,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      const testEmail = 'user@example.com';
      final emailField = find.byKey(const Key('forgot_password_email_field'));
      final sendButton = find.byKey(const Key('forgot_password_send_button'));

      // Act
      await tester.enterText(emailField, testEmail);
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Assert - Success message contains user's email
      expect(find.textContaining(testEmail), findsOneWidget);
      expect(find.text('Didn\'t receive the email? Check your spam folder or try again.'), findsOneWidget);
    });
  });
}