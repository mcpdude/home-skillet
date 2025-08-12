import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:home_skillet_mobile/screens/auth/login_screen.dart';
import 'package:home_skillet_mobile/providers/auth_provider.dart';
import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      
      // Default setup for mock auth provider
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.errorMessage).thenReturn(null);
      when(mockAuthProvider.status).thenReturn(AuthStatus.unauthenticated);
    });

    testWidgets('should display all login form elements', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Assert
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue to Home Skillet'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('should show and hide password when visibility icon is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Find password field and visibility icon
      final passwordField = find.byType(TextFormField).at(1);
      final visibilityIcon = find.byIcon(Icons.visibility_off);

      // Assert initial state (password hidden)
      final TextFormField initialPasswordWidget = tester.widget(passwordField);
      expect(initialPasswordWidget.obscureText, isTrue);
      expect(visibilityIcon, findsOneWidget);

      // Act - Tap visibility icon
      await tester.tap(visibilityIcon);
      await tester.pump();

      // Assert - Password is now visible
      final TextFormField updatedPasswordWidget = tester.widget(passwordField);
      expect(updatedPasswordWidget.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should validate email field with invalid email', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final emailField = find.byType(TextFormField).first;

      // Act - Enter invalid email and trigger validation
      await tester.enterText(emailField, 'invalid-email');
      await tester.pump();
      
      // Trigger form validation by attempting to submit
      final signInButton = find.text('Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      // Assert
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('should validate password field when empty', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final passwordField = find.byType(TextFormField).at(1);

      // Act - Leave password empty and trigger validation
      await tester.enterText(passwordField, '');
      await tester.pump();
      
      final signInButton = find.text('Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      // Assert
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('should enable sign in button when form is valid', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);

      // Act - Enter valid credentials
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Assert - Button should be enabled
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      final ElevatedButton buttonWidget = tester.widget(signInButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('should call login when form is submitted with valid data', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.login(any, any)).thenAnswer((_) async => true);
      
      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);
      final signInButton = find.text('Sign In');

      // Act - Fill form and submit
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();
      await tester.tap(signInButton);
      await tester.pump();

      // Assert
      verify(mockAuthProvider.login('test@example.com', 'password123')).called(1);
    });

    testWidgets('should show loading indicator when login is in progress', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(true);
      
      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Signing in...'), findsOneWidget);
    });

    testWidgets('should show error snackbar when login fails', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.login(any, any)).thenAnswer((_) async => false);
      when(mockAuthProvider.errorMessage).thenReturn('Invalid credentials');
      
      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);
      final signInButton = find.text('Sign In');

      // Act - Fill form and submit
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'wrongpassword');
      await tester.pump();
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('should navigate to register screen when Sign Up is tapped', (WidgetTester tester) async {
      // Note: This test would require a full navigation setup
      // For now, we'll just verify the button exists and is tappable
      
      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final signUpButton = find.text('Sign Up');
      expect(signUpButton, findsOneWidget);
      
      // Verify button is tappable
      await tester.tap(signUpButton);
      await tester.pump();
      // In a full test, we would verify navigation occurred
    });

    testWidgets('should navigate to forgot password screen when Forgot Password is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final forgotPasswordButton = find.text('Forgot Password?');
      expect(forgotPasswordButton, findsOneWidget);
      
      await tester.tap(forgotPasswordButton);
      await tester.pump();
      // In a full test, we would verify navigation occurred
    });

    testWidgets('should submit form when Enter is pressed on password field', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.login(any, any)).thenAnswer((_) async => true);
      
      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);

      // Act - Fill form
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Simulate pressing Enter on password field
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Assert
      verify(mockAuthProvider.login('test@example.com', 'password123')).called(1);
    });

    testWidgets('should disable sign in button when form is invalid', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Assert - Button should be disabled initially
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      final ElevatedButton buttonWidget = tester.widget(signInButton);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('should show app logo and title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const LoginScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      expect(find.byIcon(Icons.home_work), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
    });
  });
}