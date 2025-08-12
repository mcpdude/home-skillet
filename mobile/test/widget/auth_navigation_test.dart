import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../lib/config/app_router.dart';
import '../../lib/config/routes.dart';
import '../../lib/providers/auth_provider.dart';
import '../../lib/screens/auth/login_screen.dart';
import '../../lib/screens/dashboard/dashboard_screen.dart';
import '../../lib/screens/splash_screen.dart';
import '../helpers/mocks.dart';

void main() {
  group('Authentication-Aware Navigation Tests', () {
    late MockAuthProvider mockAuthProvider;
    late MockPropertyProvider mockPropertyProvider;
    late MockProjectProvider mockProjectProvider;
    late GoRouter router;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockPropertyProvider = MockPropertyProvider();
      mockProjectProvider = MockProjectProvider();
      
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

    group('Authentication State Changes', () {
      testWidgets('shows splash screen when authentication is loading', (tester) async {
        // Setup loading state
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.status).thenReturn(AuthStatus.loading);

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

        // Should show splash screen
        expect(find.byType(SplashScreen), findsOneWidget);
      });

      testWidgets('redirects to login when not authenticated', (tester) async {
        // Setup unauthenticated state
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.status).thenReturn(AuthStatus.unauthenticated);
        when(mockAuthProvider.user).thenReturn(null);

        // Try to navigate to dashboard
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

        // Should be redirected to login
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('redirects to dashboard when authenticated and on auth screen', (tester) async {
        // Setup authenticated state
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.status).thenReturn(AuthStatus.authenticated);
        when(mockAuthProvider.user).thenReturn(MockUserModel());

        // Try to navigate to login
        router.go(AppRoutes.login);

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

        // Should be redirected to dashboard
        expect(find.byType(DashboardScreen), findsOneWidget);
      });

      testWidgets('allows access to auth screens when not authenticated', (tester) async {
        // Setup unauthenticated state
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.status).thenReturn(AuthStatus.unauthenticated);
        when(mockAuthProvider.user).thenReturn(null);

        // Navigate to login
        router.go(AppRoutes.login);

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

        // Should show login screen
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('Protected Route Access', () {
      testWidgets('prevents access to dashboard when not authenticated', (tester) async {
        // Setup unauthenticated state
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.status).thenReturn(AuthStatus.unauthenticated);
        when(mockAuthProvider.user).thenReturn(null);

        // Try to access dashboard directly
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

        // Should be redirected to login, not dashboard
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(DashboardScreen), findsNothing);
      });

      testWidgets('prevents access to properties when not authenticated', (tester) async {
        // Setup unauthenticated state
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.status).thenReturn(AuthStatus.unauthenticated);
        when(mockAuthProvider.user).thenReturn(null);

        // Try to access properties directly
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

        // Should be redirected to login
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('prevents access to projects when not authenticated', (tester) async {
        // Setup unauthenticated state
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.status).thenReturn(AuthStatus.unauthenticated);
        when(mockAuthProvider.user).thenReturn(null);

        // Try to access projects directly
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

        // Should be redirected to login
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('allows access to protected routes when authenticated', (tester) async {
        // Setup authenticated state
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.status).thenReturn(AuthStatus.authenticated);
        when(mockAuthProvider.user).thenReturn(MockUserModel());

        // Navigate to dashboard
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

        // Should show dashboard
        expect(find.byType(DashboardScreen), findsOneWidget);
      });
    });

    group('Authentication State Transitions', () {
      testWidgets('navigates from splash to login when authentication fails', (tester) async {
        // Start in loading state
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.status).thenReturn(AuthStatus.loading);

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
        expect(find.byType(SplashScreen), findsOneWidget);

        // Simulate authentication failure
        when(mockAuthProvider.status).thenReturn(AuthStatus.unauthenticated);
        mockAuthProvider.notifyListeners();
        await tester.pumpAndSettle();

        // Should navigate to login
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('navigates from splash to dashboard when authentication succeeds', (tester) async {
        // Start in loading state
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.status).thenReturn(AuthStatus.loading);

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
        expect(find.byType(SplashScreen), findsOneWidget);

        // Simulate authentication success
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.status).thenReturn(AuthStatus.authenticated);
        when(mockAuthProvider.user).thenReturn(MockUserModel());
        mockAuthProvider.notifyListeners();
        await tester.pumpAndSettle();

        // Should navigate to dashboard
        expect(find.byType(DashboardScreen), findsOneWidget);
      });

      testWidgets('navigates from dashboard to login when user logs out', (tester) async {
        // Start authenticated
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.status).thenReturn(AuthStatus.authenticated);
        when(mockAuthProvider.user).thenReturn(MockUserModel());

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

        // Simulate logout
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.status).thenReturn(AuthStatus.unauthenticated);
        when(mockAuthProvider.user).thenReturn(null);
        mockAuthProvider.notifyListeners();
        await tester.pumpAndSettle();

        // Should navigate to login
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('Router Refresh on Auth Changes', () {
      testWidgets('router refreshes when auth provider notifies listeners', (tester) async {
        // Setup initial state
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.status).thenReturn(AuthStatus.unauthenticated);
        when(mockAuthProvider.user).thenReturn(null);

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
        expect(find.byType(LoginScreen), findsOneWidget);

        // Change auth state and notify
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.status).thenReturn(AuthStatus.authenticated);
        when(mockAuthProvider.user).thenReturn(MockUserModel());
        
        // Simulate the auth provider notifying listeners
        mockAuthProvider.notifyListeners();
        await tester.pumpAndSettle();

        // Router should have refreshed and redirected to dashboard
        expect(find.byType(DashboardScreen), findsOneWidget);
      });
    });
  });
}