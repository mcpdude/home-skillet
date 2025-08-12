import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/maintenance_provider.dart';
import '../../providers/property_provider.dart';
import '../../models/maintenance.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_message.dart';
import '../../config/routes.dart';

class MaintenanceDashboardScreen extends StatefulWidget {
  const MaintenanceDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MaintenanceDashboardScreen> createState() => _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState extends State<MaintenanceDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadMaintenanceData();
  }

  Future<void> _loadMaintenanceData() async {
    final maintenanceProvider = context.read<MaintenanceProvider>();
    await maintenanceProvider.loadMaintenanceData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MaintenanceProvider, PropertyProvider>(
      builder: (context, maintenanceProvider, propertyProvider, child) {
        final isLoading = maintenanceProvider.isLoading;
        final hasError = maintenanceProvider.errorMessage != null;

        return LoadingOverlay(
          isLoading: isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Maintenance'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _showSearchDialog(context),
                ),
                PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'filter',
                      child: Text('Filter by Property'),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _loadMaintenanceData,
              child: hasError
                  ? ErrorMessage(
                      message: maintenanceProvider.errorMessage!,
                      onRetry: _loadMaintenanceData,
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Property filter
                          if (propertyProvider.properties.isNotEmpty)
                            _buildPropertyFilter(propertyProvider, maintenanceProvider),
                          
                          const SizedBox(height: 16),

                          // Statistics cards
                          if (maintenanceProvider.stats != null)
                            _buildStatsSection(maintenanceProvider.stats!),
                          
                          const SizedBox(height: 24),

                          // Overdue tasks section
                          _buildOverdueSection(maintenanceProvider),
                          
                          const SizedBox(height: 24),

                          // Due soon section
                          _buildDueSoonSection(maintenanceProvider),
                          
                          const SizedBox(height: 24),

                          // Recent schedules
                          _buildRecentSchedulesSection(maintenanceProvider),
                          
                          const SizedBox(height: 24),

                          // Quick actions
                          _buildQuickActionsSection(),
                        ],
                      ),
                    ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _navigateToCreateSchedule(),
              child: const Icon(Icons.add),
              tooltip: 'Create Maintenance Schedule',
            ),
          ),
        );
      },
    );
  }

  Widget _buildPropertyFilter(PropertyProvider propertyProvider, MaintenanceProvider maintenanceProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Property',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: maintenanceProvider.selectedPropertyId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'All Properties',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Properties'),
                ),
                ...propertyProvider.properties.map(
                  (property) => DropdownMenuItem<String?>(
                    value: property.id,
                    child: Text(property.name),
                  ),
                ),
              ],
              onChanged: (propertyId) {
                maintenanceProvider.setSelectedProperty(propertyId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(MaintenanceStats stats) {
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
              'Active Schedules',
              stats.activeSchedules.toString(),
              Icons.schedule,
              Colors.blue,
            ),
            _buildStatCard(
              'Overdue Tasks',
              stats.overdueTasks.toString(),
              Icons.warning,
              stats.overdueTasks > 0 ? Colors.red : Colors.green,
            ),
            _buildStatCard(
              'Completed Tasks',
              stats.completedTasks.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Completion Rate',
              '${(stats.completionRate * 100).toStringAsFixed(0)}%',
              Icons.trending_up,
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

  Widget _buildOverdueSection(MaintenanceProvider provider) {
    final overdueTasks = provider.overdueTasks.take(3).toList();

    if (overdueTasks.isEmpty) {
      return const SizedBox.shrink();
    }

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
              'Overdue Tasks',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _navigateToTasksList(status: MaintenanceStatus.overdue),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...overdueTasks.map((task) => _buildTaskCard(task, isOverdue: true)),
      ],
    );
  }

  Widget _buildDueSoonSection(MaintenanceProvider provider) {
    final dueSoonTasks = provider.dueSoonTasks.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Due Soon',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToTasksList(),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (dueSoonTasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All caught up!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No maintenance tasks due soon',
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
          ...dueSoonTasks.map((task) => _buildTaskCard(task)),
      ],
    );
  }

  Widget _buildRecentSchedulesSection(MaintenanceProvider provider) {
    final recentSchedules = provider.activeSchedules.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Schedules',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToSchedulesList(),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentSchedules.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No schedules yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first maintenance schedule',
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
          ...recentSchedules.map((schedule) => _buildScheduleCard(schedule)),
      ],
    );
  }

  Widget _buildTaskCard(MaintenanceTask task, {bool isOverdue = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue ? Colors.red : _getPriorityColor(task.priority),
          child: Icon(
            isOverdue ? Icons.warning : _getPriorityIcon(task.priority),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getStatusText(task.status)),
            Text(
              'Due: ${_formatDate(task.dueDate)}',
              style: TextStyle(
                color: isOverdue ? Colors.red : null,
                fontWeight: isOverdue ? FontWeight.w500 : null,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleTaskAction(action, task),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'complete',
              child: Text('Mark Complete'),
            ),
            const PopupMenuItem(
              value: 'skip',
              child: Text('Skip'),
            ),
            const PopupMenuItem(
              value: 'view',
              child: Text('View Details'),
            ),
          ],
        ),
        onTap: () => _navigateToTaskDetail(task.id),
      ),
    );
  }

  Widget _buildScheduleCard(MaintenanceSchedule schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(schedule.priority),
          child: Icon(
            _getPriorityIcon(schedule.priority),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          schedule.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getFrequencyText(schedule.frequency)),
            Text('Next due: ${_formatDate(schedule.nextDue)}'),
          ],
        ),
        trailing: schedule.isOverdue
            ? Icon(Icons.warning, color: Colors.red)
            : schedule.isDueSoon
                ? Icon(Icons.schedule, color: Colors.orange)
                : null,
        onTap: () => _navigateToScheduleDetail(schedule.id),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
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
              'Add Schedule',
              Icons.add_circle_outline,
              _navigateToCreateSchedule,
            ),
            _buildActionButton(
              'View Calendar',
              Icons.calendar_month,
              _navigateToCalendar,
            ),
            _buildActionButton(
              'All Tasks',
              Icons.list,
              () => _navigateToTasksList(),
            ),
            _buildActionButton(
              'Statistics',
              Icons.analytics,
              _navigateToStats,
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

  // Helper methods
  Color _getPriorityColor(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return Colors.green;
      case MaintenancePriority.medium:
        return Colors.orange;
      case MaintenancePriority.high:
        return Colors.red;
      case MaintenancePriority.critical:
        return Colors.red.shade900;
    }
  }

  IconData _getPriorityIcon(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return Icons.low_priority;
      case MaintenancePriority.medium:
        return Icons.priority_high;
      case MaintenancePriority.high:
        return Icons.priority_high;
      case MaintenancePriority.critical:
        return Icons.error;
    }
  }

  String _getStatusText(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.active:
        return 'Active';
      case MaintenanceStatus.completed:
        return 'Completed';
      case MaintenanceStatus.overdue:
        return 'Overdue';
      case MaintenanceStatus.skipped:
        return 'Skipped';
      case MaintenanceStatus.paused:
        return 'Paused';
    }
  }

  String _getFrequencyText(MaintenanceFrequency frequency) {
    switch (frequency) {
      case MaintenanceFrequency.weekly:
        return 'Weekly';
      case MaintenanceFrequency.monthly:
        return 'Monthly';
      case MaintenanceFrequency.quarterly:
        return 'Quarterly';
      case MaintenanceFrequency.semiAnnually:
        return 'Semi-annually';
      case MaintenanceFrequency.annually:
        return 'Annually';
      case MaintenanceFrequency.custom:
        return 'Custom';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // Navigation methods
  void _navigateToCreateSchedule() {
    context.push('/maintenance/schedules/create');
  }

  void _navigateToSchedulesList() {
    context.push('/maintenance/schedules');
  }

  void _navigateToTasksList({MaintenanceStatus? status}) {
    String route = '/maintenance/tasks';
    if (status != null) {
      route += '?status=${status.name}';
    }
    context.push(route);
  }

  void _navigateToCalendar() {
    context.push('/maintenance/calendar');
  }

  void _navigateToStats() {
    context.push('/maintenance/stats');
  }

  void _navigateToTaskDetail(String taskId) {
    context.push('/maintenance/tasks/$taskId');
  }

  void _navigateToScheduleDetail(String scheduleId) {
    context.push('/maintenance/schedules/$scheduleId');
  }

  // Action handlers
  void _handleMenuAction(String action) {
    switch (action) {
      case 'filter':
        _showPropertyFilterDialog();
        break;
      case 'refresh':
        _loadMaintenanceData();
        break;
    }
  }

  void _handleTaskAction(String action, MaintenanceTask task) async {
    final provider = context.read<MaintenanceProvider>();
    
    switch (action) {
      case 'complete':
        await _completeTask(task);
        break;
      case 'skip':
        await _skipTask(task);
        break;
      case 'view':
        _navigateToTaskDetail(task.id);
        break;
    }
  }

  Future<void> _completeTask(MaintenanceTask task) async {
    try {
      final provider = context.read<MaintenanceProvider>();
      await provider.completeTask(CompleteMaintenanceTaskRequest(
        taskId: task.id,
        notes: 'Completed from dashboard',
      ));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task marked as complete')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete task: $e')),
        );
      }
    }
  }

  Future<void> _skipTask(MaintenanceTask task) async {
    try {
      final provider = context.read<MaintenanceProvider>();
      await provider.skipTask(task.id, reason: 'Skipped from dashboard');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task skipped')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to skip task: $e')),
        );
      }
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Search maintenance...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement search functionality
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showPropertyFilterDialog() {
    // TODO: Implement property filter dialog
  }
}