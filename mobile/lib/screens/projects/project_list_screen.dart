import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/project_provider.dart';
import '../../providers/property_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_message.dart';
import '../../config/routes.dart';
import '../../models/project.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({Key? key}) : super(key: key);

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  ProjectStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    await context.read<ProjectProvider>().loadAllProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProjectProvider, PropertyProvider>(
      builder: (context, projectProvider, propertyProvider, child) {
        final allProjects = projectProvider.projects;
        final filteredProjects = _selectedStatus != null
            ? projectProvider.getProjectsByStatus(_selectedStatus!)
            : allProjects;
        final isLoading = projectProvider.isLoading;
        final hasError = projectProvider.errorMessage != null;

        return LoadingOverlay(
          isLoading: isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Projects'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // TODO: Implement search
                  },
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _loadProjects,
              child: hasError
                  ? ErrorMessage(
                      message: projectProvider.errorMessage!,
                      onRetry: _loadProjects,
                    )
                  : Column(
                      children: [
                        _buildStatusTabs(allProjects),
                        Expanded(
                          child: filteredProjects.isEmpty
                              ? _buildEmptyState()
                              : _buildProjectList(filteredProjects, propertyProvider),
                        ),
                      ],
                    ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _showCreateProjectDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Project'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTabs(List<Project> allProjects) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChip(null, 'All', allProjects.length),
            const SizedBox(width: 8),
            ...ProjectStatus.values.map(
              (status) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildStatusChip(
                  status,
                  _getStatusText(status),
                  allProjects.where((p) => p.status == status).length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ProjectStatus? status, String label, int count) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
      label: Text('$label ($count)'),
      backgroundColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedStatus != null 
                  ? 'No ${_getStatusText(_selectedStatus!).toLowerCase()} projects'
                  : 'No Projects Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedStatus != null
                  ? 'Try changing the filter or create a new project'
                  : 'Start your first home maintenance project',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateProjectDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList(List<Project> projects, PropertyProvider propertyProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        final property = propertyProvider.getPropertyById(project.propertyId);
        return _buildProjectCard(project, property?.name);
      },
    );
  }

  Widget _buildProjectCard(Project project, String? propertyName) {
    final statusColor = _getStatusColor(project.status);
    final isOverdue = project.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.projectDetail}/${project.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (propertyName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                propertyName,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildPriorityChip(project.priority),
                      const SizedBox(height: 4),
                      _buildStatusChip(project.status, statusColor),
                    ],
                  ),
                ],
              ),

              if (project.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  project.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${project.progressPercentage.toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: project.progressPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bottom Info
              Row(
                children: [
                  if (project.dueDate != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isOverdue ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due ${_formatDate(project.dueDate!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverdue ? Colors.red : null,
                        fontWeight: isOverdue ? FontWeight.w500 : null,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (project.estimatedCost != null)
                    Text(
                      '\$${project.estimatedCost!.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                ],
              ),

              if (isOverdue) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(ProjectPriority priority) {
    Color color;
    switch (priority) {
      case ProjectPriority.urgent:
        color = Colors.red;
        break;
      case ProjectPriority.high:
        color = Colors.orange;
        break;
      case ProjectPriority.medium:
        color = Colors.blue;
        break;
      case ProjectPriority.low:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _getPriorityText(priority),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(ProjectStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
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
        return Colors.yellow.shade700;
      case ProjectStatus.cancelled:
        return Colors.red;
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

  String _getPriorityText(ProjectPriority priority) {
    switch (priority) {
      case ProjectPriority.urgent:
        return 'URGENT';
      case ProjectPriority.high:
        return 'HIGH';
      case ProjectPriority.medium:
        return 'MEDIUM';
      case ProjectPriority.low:
        return 'LOW';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Projects'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...ProjectStatus.values.map(
              (status) => RadioListTile<ProjectStatus?>(
                title: Text(_getStatusText(status)),
                value: status,
                groupValue: _selectedStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
            RadioListTile<ProjectStatus?>(
              title: const Text('All'),
              value: null,
              groupValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = null;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCreateProjectDialog() {
    // TODO: Navigate to create project screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Project'),
        content: const Text('Project creation form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}