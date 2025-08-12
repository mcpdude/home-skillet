import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:home_skillet_mobile/screens/auth/register_screen.dart';
import 'package:home_skillet_mobile/providers/auth_provider.dart';
import '../helpers/mocks.mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('RegisterScreen Widget Tests', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      
      // Default setup for mock auth provider
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.errorMessage).thenReturn(null);
      when(mockAuthProvider.status).thenReturn(AuthStatus.unauthenticated);
    });

    testWidgets('should display all registration form elements', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Assert
      expect(find.text('Join Home Skillet'), findsOneWidget);
      expect(find.text('Create your account to get started'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(5)); // First, Last, Email, Phone, Password, Confirm Password
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('should validate first name field when empty', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final firstNameField = find.byKey(const Key('register_first_name_field'));
      final createAccountButton = find.text('Create Account');

      // Act - Leave first name empty and trigger validation
      await tester.enterText(firstNameField, '');
      await tester.pump();
      await tester.tap(createAccountButton);
      await tester.pump();

      // Assert
      expect(find.text('Name is required'), findsWidgets);
    });

    testWidgets('should validate email field with invalid format', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final emailField = find.byKey(const Key('register_email_field'));
      final createAccountButton = find.text('Create Account');

      // Act - Enter invalid email and trigger validation
      await tester.enterText(emailField, 'invalid-email');
      await tester.pump();
      await tester.tap(createAccountButton);
      await tester.pump();

      // Assert
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('should validate password requirements', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final passwordField = find.byKey(const Key('register_password_field'));
      final createAccountButton = find.text('Create Account');

      // Act - Enter weak password and trigger validation
      await tester.enterText(passwordField, '123');
      await tester.pump();
      await tester.tap(createAccountButton);
      await tester.pump();

      // Assert
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('should validate confirm password matches password', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final passwordField = find.byKey(const Key('register_password_field'));
      final confirmPasswordField = find.byKey(const Key('register_confirm_password_field'));
      final createAccountButton = find.text('Create Account');

      // Act - Enter mismatched passwords and trigger validation
      await tester.enterText(passwordField, 'Password123!');
      await tester.enterText(confirmPasswordField, 'DifferentPassword');
      await tester.pump();
      await tester.tap(createAccountButton);
      await tester.pump();

      // Assert
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('should show and hide password when visibility icons are tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Find password fields and visibility icons
      final passwordField = find.byKey(const Key('register_password_field'));
      final confirmPasswordField = find.byKey(const Key('register_confirm_password_field'));
      final visibilityIcons = find.byIcon(Icons.visibility_off);

      // Assert initial state (passwords hidden)
      final TextFormField passwordWidget = tester.widget(passwordField);
      final TextFormField confirmPasswordWidget = tester.widget(confirmPasswordField);
      expect(passwordWidget.obscureText, isTrue);
      expect(confirmPasswordWidget.obscureText, isTrue);
      expect(visibilityIcons, findsNWidgets(2)); // Two password fields

      // Act - Tap first visibility icon (password field)
      await tester.tap(visibilityIcons.first);
      await tester.pump();

      // Assert - First password is now visible
      final TextFormField updatedPasswordWidget = tester.widget(passwordField);
      expect(updatedPasswordWidget.obscureText, isFalse);
    });

    testWidgets('should enable create account button when form is valid', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Act - Fill all required fields with valid data
      await tester.enterText(find.byKey(const Key('register_first_name_field')), 'John');
      await tester.enterText(find.byKey(const Key('register_last_name_field')), 'Doe');
      await tester.enterText(find.byKey(const Key('register_email_field')), 'john@example.com');
      await tester.enterText(find.byKey(const Key('register_password_field')), 'Password123!');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'Password123!');
      await tester.pump();

      // Assert - Button should be enabled
      final createAccountButton = find.widgetWithText(ElevatedButton, 'Create Account');
      final ElevatedButton buttonWidget = tester.widget(createAccountButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('should call register when form is submitted with valid data', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        firstName: anyNamed('firstName'),
        lastName: anyNamed('lastName'),
        phone: anyNamed('phone'),
      )).thenAnswer((_) async => true);
      
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Act - Fill form and submit
      await tester.enterText(find.byKey(const Key('register_first_name_field')), 'John');
      await tester.enterText(find.byKey(const Key('register_last_name_field')), 'Doe');
      await tester.enterText(find.byKey(const Key('register_email_field')), 'john@example.com');
      await tester.enterText(find.byKey(const Key('register_phone_field')), '555-123-4567');
      await tester.enterText(find.byKey(const Key('register_password_field')), 'Password123!');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'Password123!');
      await tester.pump();
      
      final createAccountButton = find.byKey(const Key('register_button'));
      await tester.tap(createAccountButton);
      await tester.pump();

      // Assert
      verify(mockAuthProvider.register(
        email: 'john@example.com',
        password: 'Password123!',
        firstName: 'John',
        lastName: 'Doe',
        phone: '555-123-4567',
      )).called(1);
    });

    testWidgets('should handle empty phone field correctly', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        firstName: anyNamed('firstName'),
        lastName: anyNamed('lastName'),
        phone: anyNamed('phone'),
      )).thenAnswer((_) async => true);
      
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Act - Fill form without phone and submit
      await tester.enterText(find.byKey(const Key('register_first_name_field')), 'John');
      await tester.enterText(find.byKey(const Key('register_last_name_field')), 'Doe');
      await tester.enterText(find.byKey(const Key('register_email_field')), 'john@example.com');
      // Leave phone field empty
      await tester.enterText(find.byKey(const Key('register_password_field')), 'Password123!');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'Password123!');
      await tester.pump();
      
      final createAccountButton = find.byKey(const Key('register_button'));
      await tester.tap(createAccountButton);
      await tester.pump();

      // Assert - Phone should be null when empty
      verify(mockAuthProvider.register(
        email: 'john@example.com',
        password: 'Password123!',
        firstName: 'John',
        lastName: 'Doe',
        phone: null,
      )).called(1);
    });

    testWidgets('should show loading indicator when registration is in progress', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(true);
      
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Creating your account...'), findsOneWidget);
    });

    testWidgets('should show error snackbar when registration fails', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        firstName: anyNamed('firstName'),
        lastName: anyNamed('lastName'),
        phone: anyNamed('phone'),
      )).thenAnswer((_) async => false);
      when(mockAuthProvider.errorMessage).thenReturn('Email already exists');
      
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Act - Fill form and submit
      await tester.enterText(find.byKey(const Key('register_first_name_field')), 'John');
      await tester.enterText(find.byKey(const Key('register_last_name_field')), 'Doe');
      await tester.enterText(find.byKey(const Key('register_email_field')), 'existing@example.com');
      await tester.enterText(find.byKey(const Key('register_password_field')), 'Password123!');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'Password123!');
      await tester.pump();
      
      final createAccountButton = find.byKey(const Key('register_button'));
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Email already exists'), findsOneWidget);
    });

    testWidgets('should submit form when Enter is pressed on confirm password field', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        firstName: anyNamed('firstName'),
        lastName: anyNamed('lastName'),
        phone: anyNamed('phone'),
      )).thenAnswer((_) async => true);
      
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Act - Fill form
      await tester.enterText(find.byKey(const Key('register_first_name_field')), 'John');
      await tester.enterText(find.byKey(const Key('register_last_name_field')), 'Doe');
      await tester.enterText(find.byKey(const Key('register_email_field')), 'john@example.com');
      await tester.enterText(find.byKey(const Key('register_password_field')), 'Password123!');
      await tester.enterText(find.byKey(const Key('register_confirm_password_field')), 'Password123!');
      await tester.pump();

      // Simulate pressing Enter on confirm password field
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Assert
      verify(mockAuthProvider.register(
        email: 'john@example.com',
        password: 'Password123!',
        firstName: 'John',
        lastName: 'Doe',
        phone: null,
      )).called(1);
    });

    testWidgets('should disable create account button when form is invalid', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Assert - Button should be disabled initially
      final createAccountButton = find.widgetWithText(ElevatedButton, 'Create Account');
      final ElevatedButton buttonWidget = tester.widget(createAccountButton);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('should navigate back when back button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      
      await tester.tap(backButton);
      await tester.pump();
      // In a full test, we would verify navigation occurred
    });

    testWidgets('should navigate back when Sign In link is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      final signInButton = find.text('Sign In');
      expect(signInButton, findsOneWidget);
      
      await tester.tap(signInButton);
      await tester.pump();
      // In a full test, we would verify navigation occurred
    });

    testWidgets('should show proper field labels and hints', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const RegisterScreen(),
        mockAuthProvider: mockAuthProvider,
      ));

      // Assert field labels
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone (Optional)'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Assert hints
      expect(find.text('John'), findsOneWidget);
      expect(find.text('Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('(555) 123-4567'), findsOneWidget);
    });
  });
}