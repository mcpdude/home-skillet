import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'config/app_router.dart';
import 'config/routes.dart';
import 'models/property.dart';
import 'providers/auth_provider.dart';
import 'providers/property_provider.dart';
import 'providers/project_provider.dart';
import 'providers/maintenance_provider.dart';
import 'providers/theme_provider.dart';
import 'services/http_client.dart';
import 'services/auth_service.dart';
import 'services/property_service.dart';
import 'services/project_service.dart';
import 'services/maintenance_service.dart';
import 'screens/properties/property_list_screen.dart';
import 'screens/properties/add_edit_property_screen.dart';
import 'screens/properties/property_detail_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'config/api_config.dart';

void main() {
  runApp(const HomeSkilletsApp());
}

class HomeSkilletsApp extends StatelessWidget {
  const HomeSkilletsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // HTTP Client
        Provider<HttpClient>(
          create: (context) => HttpClient(),
        ),
        
        // Services
        ProxyProvider<HttpClient, AuthService>(
          update: (context, httpClient, previous) => AuthService(httpClient: httpClient),
        ),
        ProxyProvider<HttpClient, PropertyService>(
          update: (context, httpClient, previous) => PropertyService(httpClient: httpClient),
        ),
        ProxyProvider<HttpClient, ProjectService>(
          update: (context, httpClient, previous) => ProjectService(httpClient: httpClient),
        ),
        ProxyProvider<HttpClient, MaintenanceService>(
          update: (context, httpClient, previous) => MaintenanceService(httpClient: httpClient),
        ),
        
        // Providers
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(authService: context.read<AuthService>()),
          update: (context, authService, previous) => previous ?? AuthProvider(authService: authService),
        ),
        ChangeNotifierProxyProvider<PropertyService, PropertyProvider>(
          create: (context) => PropertyProvider(propertyService: context.read<PropertyService>()),
          update: (context, propertyService, previous) => previous ?? PropertyProvider(propertyService: propertyService),
        ),
        ChangeNotifierProxyProvider<ProjectService, ProjectProvider>(
          create: (context) => ProjectProvider(projectService: context.read<ProjectService>()),
          update: (context, projectService, previous) => previous ?? ProjectProvider(projectService: projectService),
        ),
        ChangeNotifierProxyProvider<MaintenanceService, MaintenanceProvider>(
          create: (context) => MaintenanceProvider(maintenanceService: context.read<MaintenanceService>()),
          update: (context, maintenanceService, previous) => previous ?? MaintenanceProvider(maintenanceService: maintenanceService),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(),
        ),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          final router = _createRouter(authProvider);
          
          return MaterialApp.router(
            title: 'Home Skillet',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
  
  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: authProvider.isAuthenticated ? AppRoutes.dashboard : AppRoutes.login,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoginRoute = state.location == AppRoutes.login || state.location == AppRoutes.register;
        
        if (!isAuthenticated && !isLoginRoute) {
          return AppRoutes.login;
        }
        
        if (isAuthenticated && isLoginRoute) {
          return AppRoutes.dashboard;
        }
        
        return null;
      },
      routes: [
        // Auth routes
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        
        // Main app routes
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        
        // Property routes
        GoRoute(
          path: AppRoutes.properties,
          builder: (context, state) => const PropertyListScreen(),
        ),
        GoRoute(
          path: AppRoutes.addProperty,
          builder: (context, state) => const AddEditPropertyScreen(),
        ),
        GoRoute(
          path: AppRoutes.editProperty,
          builder: (context, state) {
            final propertyId = state.pathParameters['propertyId']!;
            return AddEditPropertyScreen(
              propertyId: propertyId,
              isEdit: true,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.propertyDetail,
          builder: (context, state) {
            final propertyId = state.pathParameters['propertyId']!;
            return PropertyDetailScreen(propertyId: propertyId);
          },
        ),
      ],
    );
  }
}

// Enhanced Dashboard Screen for property management
class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedDashboardScreen> createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    final propertyProvider = context.read<PropertyProvider>();
    await propertyProvider.loadProperties();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          DashboardHomeTab(),
          PropertyListScreen(),
          ProjectsTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Properties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Dashboard home tab with statistics and quick actions
class DashboardHomeTab extends StatelessWidget {
  const DashboardHomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<PropertyProvider, AuthProvider>(
      builder: (context, propertyProvider, authProvider, child) {
        final properties = propertyProvider.properties;
        final user = authProvider.currentUser;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${user?.firstName ?? 'User'}!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your properties and maintenance projects',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Property statistics
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Properties',
                      value: '${properties.length}',
                      icon: Icons.home,
                      color: Colors.blue,
                      onTap: () => context.push(AppRoutes.properties),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Projects',
                      value: '0', // TODO: Get actual project count
                      icon: Icons.work,
                      color: Colors.orange,
                      onTap: () => context.push(AppRoutes.projects),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Property type breakdown
              if (properties.isNotEmpty) ...[
                Text(
                  'Property Types',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _PropertyTypeBreakdown(properties: properties),
                const SizedBox(height: 24),
              ],
              
              // Quick actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.addProperty),
                      icon: const Icon(Icons.add_home),
                      label: const Text('Add Property'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.projects),
                      icon: const Icon(Icons.construction),
                      label: const Text('New Project'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Recent properties
              if (properties.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Properties',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.properties),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                ...properties.take(3).map((property) => 
                  _PropertyQuickCard(property: property)
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyTypeBreakdown extends StatelessWidget {
  final List<Property> properties;

  const _PropertyTypeBreakdown({Key? key, required this.properties}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typeCount = <PropertyType, int>{};
    for (final property in properties) {
      typeCount[property.type] = (typeCount[property.type] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: typeCount.entries.map((entry) {
            final percentage = (entry.value / properties.length * 100).toInt();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(_getPropertyTypeText(entry.key)),
                  ),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value: entry.value / properties.length,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$percentage%'),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getPropertyTypeText(PropertyType type) {
    switch (type) {
      case PropertyType.house:
        return 'House';
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.condo:
        return 'Condo';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.commercial:
        return 'Commercial';
      case PropertyType.other:
        return 'Other';
    }
  }
}

class _PropertyQuickCard extends StatelessWidget {
  final Property property;

  const _PropertyQuickCard({Key? key, required this.property}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.home,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(property.name),
        subtitle: Text(property.address),
        trailing: Icon(Icons.chevron_right),
        onTap: () => context.push('${AppRoutes.propertyDetail}/${property.id}'),
      ),
    );
  }
}

// Placeholder tabs
class ProjectsTab extends StatelessWidget {
  const ProjectsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Projects Tab - Coming Soon'),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Tab - Coming Soon'),
    );
  }
}