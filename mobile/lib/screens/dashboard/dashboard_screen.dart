import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/project_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_message.dart';
import '../../config/routes.dart';
import '../../models/project.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final propertyProvider = context.read<PropertyProvider>();
    final projectProvider = context.read<ProjectProvider>();
    
    await Future.wait([
      propertyProvider.loadProperties(),
      projectProvider.loadAllProjects(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, PropertyProvider, ProjectProvider>(
      builder: (context, authProvider, propertyProvider, projectProvider, child) {
        final user = authProvider.user;
        final isLoading = propertyProvider.isLoading || projectProvider.isLoading;
        final hasError = propertyProvider.errorMessage != null || 
                        projectProvider.errorMessage != null;

        return LoadingOverlay(
          isLoading: isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Welcome, ${user?.firstName ?? 'User'}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => context.push(AppRoutes.settings),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: hasError
                  ? ErrorMessage(
                      message: propertyProvider.errorMessage ?? 
                              projectProvider.errorMessage ?? 
                              'Failed to load dashboard data',
                      onRetry: _loadDashboardData,
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Stats
                          _buildQuickStats(propertyProvider, projectProvider),
                          const SizedBox(height: 24),

                          // Recent Projects
                          _buildRecentProjects(projectProvider),
                          const SizedBox(height: 24),

                          // Overdue Projects
                          _buildOverdueProjects(projectProvider),
                          const SizedBox(height: 24),

                          // Quick Actions
                          _buildQuickActions(),
                        ],
                      ),
                    ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => context.push(AppRoutes.projects),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(PropertyProvider propertyProvider, ProjectProvider projectProvider) {
    final properties = propertyProvider.properties;
    final projects = projectProvider.projects;
    final activeProjects = projects.where((p) => p.status == ProjectStatus.inProgress).length;
    final completedProjects = projects.where((p) => p.status == ProjectStatus.completed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Properties',
              properties.length.toString(),
              Icons.home,
              Colors.blue,
            ),
            _buildStatCard(
              'Active Projects',
              activeProjects.toString(),
              Icons.construction,
              Colors.orange,
            ),
            _buildStatCard(
              'Total Projects',
              projects.length.toString(),
              Icons.folder,
              Colors.green,
            ),
            _buildStatCard(
              'Completed',
              completedProjects.toString(),
              Icons.check_circle,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProjects(ProjectProvider projectProvider) {
    final recentProjects = projectProvider.projects
        .where((p) => p.status != ProjectStatus.completed)
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Projects',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.projects),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentProjects.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.construction,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No projects yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start your first home maintenance project',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recentProjects.map((project) => _buildProjectCard(project)),
      ],
    );
  }

  Widget _buildOverdueProjects(ProjectProvider projectProvider) {
    final overdueProjects = projectProvider.overdueProjects.take(3).toList();

    if (overdueProjects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Overdue Projects',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...overdueProjects.map((project) => _buildProjectCard(project, isOverdue: true)),
      ],
    );
  }

  Widget _buildProjectCard(Project project, {bool isOverdue = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue ? Colors.red : _getStatusColor(project.status),
          child: Icon(
            _getStatusIcon(project.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          project.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getStatusText(project.status)),
            if (project.dueDate != null)
              Text(
                'Due: ${_formatDate(project.dueDate!)}',
                style: TextStyle(
                  color: isOverdue ? Colors.red : null,
                  fontWeight: isOverdue ? FontWeight.w500 : null,
                ),
              ),
          ],
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () => context.push('${AppRoutes.projects}/${project.id}'),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2,
          children: [
            _buildActionButton(
              'Add Property',
              Icons.home_outlined,
              () => context.push(AppRoutes.properties),
            ),
            _buildActionButton(
              'New Project',
              Icons.add_circle_outline,
              () => context.push(AppRoutes.projects),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planned:
        return Colors.grey;
      case ProjectStatus.inProgress:
        return Colors.orange;
      case ProjectStatus.completed:
        return Colors.green;
      case ProjectStatus.onHold:
        return Colors.yellow;
      case ProjectStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planned:
        return Icons.schedule;
      case ProjectStatus.inProgress:
        return Icons.construction;
      case ProjectStatus.completed:
        return Icons.check_circle;
      case ProjectStatus.onHold:
        return Icons.pause_circle;
      case ProjectStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planned:
        return 'Planned';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}