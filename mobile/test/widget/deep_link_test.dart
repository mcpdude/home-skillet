import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../lib/config/app_router.dart';
import '../../lib/config/routes.dart';
import '../../lib/providers/auth_provider.dart';
import '../../lib/screens/dashboard/dashboard_screen.dart';
import '../../lib/screens/properties/property_detail_screen.dart';
import '../../lib/screens/properties/property_list_screen.dart';
import '../../lib/screens/projects/project_detail_screen.dart';
import '../../lib/screens/projects/project_list_screen.dart';
import '../../lib/screens/profile/profile_screen.dart';
import '../../lib/screens/settings/settings_screen.dart';
import '../helpers/mocks.dart';

void main() {
  group('Deep Linking Support Tests', () {
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

    group('Direct Route Navigation', () {
      testWidgets('handles deep link to dashboard', (tester) async {
        router.go(AppRoutes.dashboard);

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

        expect(find.byType(DashboardScreen), findsOneWidget);
      });

      testWidgets('handles deep link to properties list', (tester) async {
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

        expect(find.byType(PropertyListScreen), findsOneWidget);
      });

      testWidgets('handles deep link to projects list', (tester) async {
        router.go(AppRoutes.projects);

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

        expect(find.byType(ProjectListScreen), findsOneWidget);
      });

      testWidgets('handles deep link to profile', (tester) async {
        router.go(AppRoutes.profile);

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

        expect(find.byType(ProfileScreen), findsOneWidget);
      });

      testWidgets('handles deep link to settings', (tester) async {
        router.go(AppRoutes.settings);

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

        expect(find.byType(SettingsScreen), findsOneWidget);
      });
    });

    group('Parameterized Routes', () {
      testWidgets('handles deep link to property detail with ID', (tester) async {
        const propertyId = 'test-property-123';
        router.go('/properties/$propertyId');

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

        expect(find.byType(PropertyDetailScreen), findsOneWidget);
        
        // Verify the property ID was passed correctly
        final propertyDetailScreen = tester.widget<PropertyDetailScreen>(
          find.byType(PropertyDetailScreen),
        );
        expect(propertyDetailScreen.propertyId, equals(propertyId));
      });

      testWidgets('handles deep link to project detail with ID', (tester) async {
        const projectId = 'test-project-456';
        router.go('/projects/$projectId');

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

        expect(find.byType(ProjectDetailScreen), findsOneWidget);
        
        // Verify the project ID was passed correctly
        final projectDetailScreen = tester.widget<ProjectDetailScreen>(
          find.byType(ProjectDetailScreen),
        );
        expect(projectDetailScreen.projectId, equals(projectId));
      });

      testWidgets('handles deep link with special characters in ID', (tester) async {
        const propertyId = 'property-with-special-chars_123-abc';
        router.go('/properties/$propertyId');

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

        expect(find.byType(PropertyDetailScreen), findsOneWidget);
        
        final propertyDetailScreen = tester.widget<PropertyDetailScreen>(
          find.byType(PropertyDetailScreen),
        );
        expect(propertyDetailScreen.propertyId, equals(propertyId));
      });
    });

    group('Deep Link Authentication Requirements', () {
      testWidgets('redirects unauthenticated users from protected deep links to login', (tester) async {
        // Setup unauthenticated state
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.status).thenReturn(AuthStatus.unauthenticated);
        when(mockAuthProvider.user).thenReturn(null);

        // Try to deep link to a protected route
        router.go('/properties/test-property-123');

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

        // Should be redirected to login instead of the property detail
        expect(find.byType(PropertyDetailScreen), findsNothing);
        expect(find.text('Login'), findsOneWidget); // Login screen should be shown
      });

      testWidgets('allows authenticated users to access deep linked protected routes', (tester) async {
        // Already authenticated from setUp
        const projectId = 'test-project-789';
        router.go('/projects/$projectId');

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

        expect(find.byType(ProjectDetailScreen), findsOneWidget);
      });
    });

    group('Deep Link Error Handling', () {
      testWidgets('shows error page for invalid deep links', (tester) async {
        router.go('/invalid/deep/link');

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

        expect(find.text('Page not found'), findsOneWidget);
        expect(find.text('Go to Dashboard'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('handles malformed route parameters gracefully', (tester) async {
        // Try to access a property detail route without providing an ID
        router.go('/properties/');

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

        // Should show error page or redirect appropriately
        expect(find.text('Page not found'), findsOneWidget);
      });
    });

    group('Deep Link Navigation State', () {
      testWidgets('maintains correct navigation state after deep linking', (tester) async {
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

        // Check that the navigation bar reflects the current route
        final navigationBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navigationBar.selectedIndex, equals(1)); // Properties is index 1

        // Verify that we can still navigate from here
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
      });

      testWidgets('can navigate back after deep linking to detail screen', (tester) async {
        const propertyId = 'test-property-back-navigation';
        router.go('/properties/$propertyId');

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

        expect(find.byType(PropertyDetailScreen), findsOneWidget);

        // Navigate to another screen using bottom navigation
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
      });
    });

    group('URL State Management', () {
      testWidgets('maintains URL consistency with navigation state', (tester) async {
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

        // Navigate to properties through UI
        await tester.tap(find.text('Properties'));
        await tester.pumpAndSettle();

        // URL should reflect the current route
        expect(router.routerDelegate.currentConfiguration.uri.toString(), 
               equals('/properties'));

        // Navigate to projects
        await tester.tap(find.text('Projects'));
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.toString(), 
               equals('/projects'));
      });
    });
  });
}