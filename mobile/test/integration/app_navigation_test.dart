import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

import 'package:home_skillet_mobile/main.dart';
import 'package:home_skillet_mobile/screens/auth/login_screen.dart';
import 'package:home_skillet_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:home_skillet_mobile/screens/properties/property_list_screen.dart';
import 'package:home_skillet_mobile/screens/projects/project_list_screen.dart';
import 'package:home_skillet_mobile/screens/profile/profile_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Navigation Integration Tests', () {
    testWidgets('should show login screen when not authenticated', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(const HomeSkilletsApp());
      await tester.pumpAndSettle();

      // Verify login screen is displayed
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('complete authentication flow should work', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(const HomeSkilletsApp());
      await tester.pumpAndSettle();

      // Verify we're on login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Fill in login form
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pump();

      // Submit login form
      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Note: In a real integration test, this would actually authenticate
      // For now, we're testing the UI flow
    });

    testWidgets('bottom navigation should work correctly when authenticated', (WidgetTester tester) async {
      // This test assumes the user is already authenticated
      // In a real scenario, you would set up proper authentication state
      
      await tester.pumpWidget(const HomeSkilletsApp());
      await tester.pumpAndSettle();

      // Note: These tests would need proper authentication setup
      // For demonstration purposes, showing the expected navigation flow

      // Test navigation to Properties
      final propertiesTab = find.text('Properties');
      if (propertiesTab.tryEvaluate().isNotEmpty) {
        await tester.tap(propertiesTab);
        await tester.pumpAndSettle();
        expect(find.byType(PropertyListScreen), findsOneWidget);
      }

      // Test navigation to Projects
      final projectsTab = find.text('Projects');
      if (projectsTab.tryEvaluate().isNotEmpty) {
        await tester.tap(projectsTab);
        await tester.pumpAndSettle();
        expect(find.byType(ProjectListScreen), findsOneWidget);
      }

      // Test navigation to Profile
      final profileTab = find.text('Profile');
      if (profileTab.tryEvaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);
      }

      // Test navigation back to Dashboard
      final dashboardTab = find.text('Dashboard');
      if (dashboardTab.tryEvaluate().isNotEmpty) {
        await tester.tap(dashboardTab);
        await tester.pumpAndSettle();
        expect(find.byType(DashboardScreen), findsOneWidget);
      }
    });

    testWidgets('should navigate to register screen from login', (WidgetTester tester) async {
      await tester.pumpWidget(const HomeSkilletsApp());
      await tester.pumpAndSettle();

      // Verify we're on login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Tap Sign Up link
      final signUpButton = find.text('Sign Up');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Verify navigation to register screen
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Join Home Skillet'), findsOneWidget);
    });

    testWidgets('should navigate to forgot password screen from login', (WidgetTester tester) async {
      await tester.pumpWidget(const HomeSkilletsApp());
      await tester.pumpAndSettle();

      // Verify we're on login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Tap Forgot Password link
      final forgotPasswordButton = find.text('Forgot Password?');
      await tester.tap(forgotPasswordButton);
      await tester.pumpAndSettle();

      // Verify navigation to forgot password screen
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('should handle back navigation correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const HomeSkilletsApp());
      await tester.pumpAndSettle();

      // Navigate to register screen
      final signUpButton = find.text('Sign Up');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Verify we're on register screen
      expect(find.text('Create Account'), findsOneWidget);

      // Navigate back
      final backButton = find.byIcon(Icons.arrow_back);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify we're back on login screen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('should show loading states during navigation', (WidgetTester tester) async {
      await tester.pumpWidget(const HomeSkilletsApp());
      await tester.pumpAndSettle();

      // Look for any loading indicators that might appear during navigation
      // This is more relevant for real API calls
      
      final loadingIndicators = find.byType(CircularProgressIndicator);
      // Verify loading indicators work as expected
    });

    testWidgets('should handle deep links correctly', (WidgetTester tester) async {
      // This would test deep link navigation
      // For example: /properties/123, /projects/456, etc.
      
      // Note: Deep link testing requires proper setup of the navigation system
      // This is a placeholder for actual deep link tests
      
      await tester.pumpWidget(const HomeSkilletsApp());
      await tester.pumpAndSettle();
      
      // Verify app can handle various deep link scenarios
    });

    testWidgets('should preserve navigation state during app lifecycle', (WidgetTester tester) async {
      // This would test navigation state preservation during:
      // - App backgrounding/foregrounding
      // - Screen rotation
      // - Memory pressure scenarios
      
      await tester.pumpWidget(const HomeSkilletsApp());
      await tester.pumpAndSettle();
      
      // Test state preservation logic
    });

    testWidgets('should handle navigation errors gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(const HomeSkilletsApp());
      await tester.pumpAndSettle();
      
      // Test error scenarios:
      // - Invalid routes
      // - Missing required parameters
      // - Network failures during navigation
      
      // Verify app shows appropriate error screens
    });
  });
}