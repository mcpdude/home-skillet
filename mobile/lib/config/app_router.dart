import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/properties/property_list_screen.dart';
import '../screens/properties/property_detail_screen.dart';
import '../screens/projects/project_list_screen.dart';
import '../screens/projects/project_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/maintenance/maintenance_dashboard_screen.dart';
import '../widgets/main_layout.dart';
import 'routes.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = 
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey = 
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.splash,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthenticating = authProvider.status == AuthStatus.loading;
        final isOnSplash = state.matchedLocation == AppRoutes.splash;
        final isOnAuth = state.matchedLocation.startsWith('/login') ||
                        state.matchedLocation.startsWith('/register') ||
                        state.matchedLocation.startsWith('/forgot-password');

        // Show splash while checking auth status
        if (isAuthenticating && !isOnSplash) {
          return AppRoutes.splash;
        }

        // If not authenticated and not on auth screens, go to login
        if (!isAuthenticated && !isOnAuth && !isOnSplash) {
          return AppRoutes.login;
        }

        // If authenticated and on auth screens, go to dashboard
        if (isAuthenticated && isOnAuth) {
          return AppRoutes.dashboard;
        }

        // If authenticated and on splash, go to dashboard
        if (isAuthenticated && isOnSplash) {
          return AppRoutes.dashboard;
        }

        return null;
      },
      routes: [
        // Splash Screen
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth Routes
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Main App Shell
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return MainLayout(child: child);
          },
          routes: [
            // Dashboard
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) => const DashboardScreen(),
            ),

            // Properties
            GoRoute(
              path: AppRoutes.properties,
              builder: (context, state) => const PropertyListScreen(),
            ),
            GoRoute(
              path: AppRoutes.propertyDetail,
              builder: (context, state) {
                final propertyId = state.pathParameters['propertyId']!;
                return PropertyDetailScreen(propertyId: propertyId);
              },
            ),

            // Projects
            GoRoute(
              path: AppRoutes.projects,
              builder: (context, state) => const ProjectListScreen(),
            ),
            GoRoute(
              path: AppRoutes.projectDetail,
              builder: (context, state) {
                final projectId = state.pathParameters['projectId']!;
                return ProjectDetailScreen(projectId: projectId);
              },
            ),

            // Maintenance
            GoRoute(
              path: AppRoutes.maintenance,
              builder: (context, state) => const MaintenanceDashboardScreen(),
            ),

            // Profile & Settings
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(state.error.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.dashboard),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}