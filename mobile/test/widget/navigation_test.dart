import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../lib/config/app_router.dart';
import '../../lib/config/routes.dart';
import '../../lib/providers/auth_provider.dart';
import '../../lib/screens/dashboard/dashboard_screen.dart';
import '../../lib/screens/properties/property_list_screen.dart';
import '../../lib/screens/projects/project_list_screen.dart';
import '../../lib/screens/profile/profile_screen.dart';
import '../../lib/widgets/main_layout.dart';
import '../helpers/mocks.dart';

void main() {
  group('Navigation System Tests', () {
    late MockAuthProvider mockAuthProvider;
    late MockPropertyProvider mockPropertyProvider;
    late MockProjectProvider mockProjectProvider;
    late GoRouter router;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockPropertyProvider = MockPropertyProvider();
      mockProjectProvider = MockProjectProvider();
      
      // Setup authenticated state by default
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.status).thenReturn(AuthStatus.authenticated);
      when(mockAuthProvider.user).thenReturn(MockUserModel());
      
      // Setup empty providers
      when(mockPropertyProvider.properties).thenReturn([]);
      when(mockPropertyProvider.isLoading).thenReturn(false);
      when(mockPropertyProvider.errorMessage).thenReturn(null);
      when(mockProjectProvider.projects).thenReturn([]);
      when(mockProjectProvider.isLoading).thenReturn(false);
      when(mockProjectProvider.errorMessage).thenReturn(null);
      when(mockProjectProvider.overdueProjects).thenReturn([]);
      
      router = AppRouter.createRouter(mockAuthProvider);
    });

    group('Bottom Navigation', () {
      testWidgets('displays correct navigation destinations', (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<PropertyProvider>.value(value: mockPropertyProvider),
              ChangeNotifierProvider<ProjectProvider>.value(value: mockProjectProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // Wait for initial navigation
        await tester.pumpAndSettle();

        // Find the navigation bar
        expect(find.byType(NavigationBar), findsOneWidget);
        
        // Check for all navigation destinations
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Properties'), findsOneWidget);
        expect(find.text('Projects'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
        
        // Check for navigation icons
        expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
        expect(find.byIcon(Icons.home_outlined), findsOneWidget);
        expect(find.byIcon(Icons.construction_outlined), findsOneWidget);
        expect(find.byIcon(Icons.person_outline), findsOneWidget);
      });

      testWidgets('navigates to properties screen when properties tab tapped', (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<PropertyProvider>.value(value: mockPropertyProvider),
              ChangeNotifierProvider<ProjectProvider>.value(value: mockProjectProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on Properties tab
        await tester.tap(find.text('Properties'));
        await tester.pumpAndSettle();

        // Verify we're on the properties screen
        expect(find.byType(PropertyListScreen), findsOneWidget);
      });

      testWidgets('navigates to projects screen when projects tab tapped', (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<PropertyProvider>.value(value: mockPropertyProvider),
              ChangeNotifierProvider<ProjectProvider>.value(value: mockProjectProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on Projects tab
        await tester.tap(find.text('Projects'));
        await tester.pumpAndSettle();

        // Verify we're on the projects screen
        expect(find.byType(ProjectListScreen), findsOneWidget);
      });

      testWidgets('navigates to profile screen when profile tab tapped', (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<PropertyProvider>.value(value: mockPropertyProvider),
              ChangeNotifierProvider<ProjectProvider>.value(value: mockProjectProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        // Verify we're on the profile screen
        expect(find.byType(ProfileScreen), findsOneWidget);
      });

      testWidgets('navigates back to dashboard when dashboard tab tapped', (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<PropertyProvider>.value(value: mockPropertyProvider),
              ChangeNotifierProvider<ProjectProvider>.value(value: mockProjectProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Go to Properties first
        await tester.tap(find.text('Properties'));
        await tester.pumpAndSettle();

        // Then go back to Dashboard
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();

        // Verify we're on the dashboard screen
        expect(find.byType(DashboardScreen), findsOneWidget);
      });

      testWidgets('maintains navigation state correctly', (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<PropertyProvider>.value(value: mockPropertyProvider),
              ChangeNotifierProvider<ProjectProvider>.value(value: mockProjectProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Start on dashboard (index 0)
        final mainLayout = tester.widget<MainLayout>(find.byType(MainLayout));
        expect((mainLayout.child as Widget), isA<DashboardScreen>());

        // Navigate to Properties (index 1)
        await tester.tap(find.text('Properties'));
        await tester.pumpAndSettle();

        // Check that navigation bar shows Properties as selected
        final navigationBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navigationBar.selectedIndex, equals(1));
      });
    });

    group('Route Navigation', () {
      testWidgets('handles direct route navigation', (tester) async {
        // Start with properties route
        router.go(AppRoutes.properties);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<PropertyProvider>.value(value: mockPropertyProvider),
              ChangeNotifierProvider<ProjectProvider>.value(value: mockProjectProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should be on Properties screen
        expect(find.byType(PropertyListScreen), findsOneWidget);
        
        // Navigation bar should reflect the current route
        final navigationBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navigationBar.selectedIndex, equals(1)); // Properties is index 1
      });

      testWidgets('handles invalid routes gracefully', (tester) async {
        // Navigate to invalid route
        router.go('/invalid-route');

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<PropertyProvider>.value(value: mockPropertyProvider),
              ChangeNotifierProvider<ProjectProvider>.value(value: mockProjectProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show error page
        expect(find.text('Page not found'), findsOneWidget);
        expect(find.text('Go to Dashboard'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('error page navigation to dashboard works', (tester) async {
        // Navigate to invalid route
        router.go('/invalid-route');

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<PropertyProvider>.value(value: mockPropertyProvider),
              ChangeNotifierProvider<ProjectProvider>.value(value: mockProjectProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap "Go to Dashboard" button
        await tester.tap(find.text('Go to Dashboard'));
        await tester.pumpAndSettle();

        // Should be on Dashboard
        expect(find.byType(DashboardScreen), findsOneWidget);
      });
    });

    group('Navigation Accessibility', () {
      testWidgets('navigation has proper semantic labels', (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<PropertyProvider>.value(value: mockPropertyProvider),
              ChangeNotifierProvider<ProjectProvider>.value(value: mockProjectProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check that navigation destinations have proper semantics
        expect(
          find.bySemanticsLabel('Dashboard'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Properties'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Projects'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Profile'),
          findsOneWidget,
        );
      });
    });
  });
}