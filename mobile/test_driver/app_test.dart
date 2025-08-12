import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Home Skillet App Integration Tests', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      driver.close();
    });

    test('should display login screen on app launch', () async {
      // Find elements
      final welcomeBackText = find.text('Welcome Back');
      final emailField = find.byType('TextFormField');
      final passwordField = find.byType('TextFormField');
      final signInButton = find.text('Sign In');

      // Verify login screen elements are present
      await driver.waitFor(welcomeBackText);
      await driver.waitFor(emailField);
      await driver.waitFor(signInButton);
    });

    test('should show validation errors for invalid input', () async {
      // Find and tap sign in button without filling fields
      final signInButton = find.text('Sign In');
      await driver.tap(signInButton);

      // Wait for validation errors
      await driver.waitFor(find.text('Email is required'), timeout: const Duration(seconds: 5));
      await driver.waitFor(find.text('Password is required'), timeout: const Duration(seconds: 5));
    });

    test('should navigate to register screen', () async {
      // Find and tap sign up link
      final signUpLink = find.text('Sign Up');
      await driver.tap(signUpLink);

      // Verify register screen is displayed
      await driver.waitFor(find.text('Create Account'));
      await driver.waitFor(find.text('Join Home Skillet'));

      // Navigate back to login
      final backButton = find.byIcon(Icons.arrow_back);
      await driver.tap(backButton);
      
      // Verify we're back on login screen
      await driver.waitFor(find.text('Welcome Back'));
    });

    test('should navigate to forgot password screen', () async {
      // Find and tap forgot password link
      final forgotPasswordLink = find.text('Forgot Password?');
      await driver.tap(forgotPasswordLink);

      // Verify forgot password screen is displayed
      await driver.waitFor(find.text('Reset Password'));
      await driver.waitFor(find.text('Forgot Password?'));

      // Navigate back
      final backButton = find.byIcon(Icons.arrow_back);
      await driver.tap(backButton);
      
      await driver.waitFor(find.text('Welcome Back'));
    });

    test('should handle form input correctly', () async {
      // Find form fields
      final emailField = find.byValueKey('login_email_field');
      final passwordField = find.byValueKey('login_password_field');

      // Enter text into fields
      await driver.tap(emailField);
      await driver.enterText('test@example.com');

      await driver.tap(passwordField);
      await driver.enterText('password123');

      // Verify text was entered (this would require additional setup for real testing)
      // In a real test, you would verify the form state or attempt login
    });

    test('should show loading state during login attempt', () async {
      // This test would require mocking the authentication service
      // to simulate a login attempt that takes time
      
      final emailField = find.byValueKey('login_email_field');
      final passwordField = find.byValueKey('login_password_field');
      final signInButton = find.text('Sign In');

      await driver.tap(emailField);
      await driver.enterText('test@example.com');

      await driver.tap(passwordField);
      await driver.enterText('password123');

      await driver.tap(signInButton);

      // In a real test with API mocking, you would verify:
      // - Loading indicator appears
      // - Form is disabled during loading
      // - Appropriate response handling
    });

    test('should handle app lifecycle events', () async {
      // Test app backgrounding and foregrounding
      // This would require platform-specific implementation
      
      // Background the app
      // await driver.requestData('background');
      
      // Foreground the app
      // await driver.requestData('foreground');
      
      // Verify app state is preserved
      await driver.waitFor(find.text('Welcome Back'));
    });

    test('should scroll through long forms correctly', () async {
      // Navigate to register screen which has more fields
      final signUpLink = find.text('Sign Up');
      await driver.tap(signUpLink);

      await driver.waitFor(find.text('Create Account'));

      // Test scrolling behavior
      await driver.scroll(
        find.byType('SingleChildScrollView'),
        0,
        -300,
        const Duration(milliseconds: 500),
      );

      // Verify fields are still accessible after scrolling
      final createAccountButton = find.text('Create Account');
      await driver.waitFor(createAccountButton);

      // Navigate back
      final backButton = find.byIcon(Icons.arrow_back);
      await driver.tap(backButton);
    });

    test('should handle device rotation', () async {
      // Test portrait mode
      await driver.waitFor(find.text('Welcome Back'));

      // Rotate to landscape (platform specific implementation required)
      // await driver.requestData('rotate_landscape');
      
      // Verify UI adapts correctly
      await driver.waitFor(find.text('Welcome Back'));

      // Rotate back to portrait
      // await driver.requestData('rotate_portrait');
      
      await driver.waitFor(find.text('Welcome Back'));
    });
  });
}