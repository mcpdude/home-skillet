import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/property_provider.dart';
import '../../providers/project_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_message.dart';
import '../../config/routes.dart';
import '../../models/property.dart';
import 'add_edit_property_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({
    Key? key,
    required this.propertyId,
  }) : super(key: key);

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadPropertyData();
  }

  Future<void> _loadPropertyData() async {
    final projectProvider = context.read<ProjectProvider>();
    await projectProvider.loadProjectsForProperty(widget.propertyId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PropertyProvider, ProjectProvider>(
      builder: (context, propertyProvider, projectProvider, child) {
        final property = propertyProvider.getPropertyById(widget.propertyId);
        final projects = projectProvider.projects;
        final isLoading = projectProvider.isLoading;

        if (property == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Property Not Found')),
            body: const ErrorMessage(
              message: 'The requested property could not be found.',
            ),
          );
        }

        return LoadingOverlay(
          isLoading: isLoading,
          child: Scaffold(
            body: RefreshIndicator(
              onRefresh: _loadPropertyData,
              child: CustomScrollView(
              slivers: [
                // App Bar with Property Image
                SliverAppBar(
                  expandedHeight: 300.0,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      property.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3.0,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    background: property.imageUrls.isNotEmpty
                        ? Image.network(
                            property.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(value, property),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit Property'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete Property'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Property Details
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPropertyInfo(property),
                        const SizedBox(height: 24),
                        _buildProjectsSection(projects),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _createProject(property),
              icon: const Icon(Icons.add),
              label: const Text('New Project'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.3),
      child: Center(
        child: Icon(
          Icons.home,
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildPropertyInfo(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                property.address,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (property.description != null) ...[
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            property.description!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],

        // Property Details Grid
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 8,
                  children: [
                    _buildDetailItem('Type', _getPropertyTypeText(property.type)),
                    if (property.yearBuilt != null)
                      _buildDetailItem('Year Built', property.yearBuilt.toString()),
                    if (property.bedrooms != null)
                      _buildDetailItem('Bedrooms', property.bedrooms.toString()),
                    if (property.bathrooms != null)
                      _buildDetailItem('Bathrooms', property.bathrooms.toString()),
                    if (property.squareFootage != null)
                      _buildDetailItem('Sq Ft', '${property.squareFootage?.toInt()}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsSection(List<dynamic> projects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Projects (${projects.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
        
        if (projects.isEmpty)
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
                      'Start your first maintenance project for this property',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _createProject(
                        context.read<PropertyProvider>().getPropertyById(widget.propertyId)!,
                      ),
                      child: const Text('Create Project'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...projects.take(3).map((project) => Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(
                      Icons.construction,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    project.title ?? 'Unnamed Project',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(project.description ?? 'No description'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('${AppRoutes.projectDetail}/${project.id}'),
                ),
              )),
      ],
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

  void _handleMenuAction(String action, Property property) {
    switch (action) {
      case 'edit':
        // Navigate to edit property screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddEditPropertyScreen(
              propertyId: property.id,
              isEdit: true,
            ),
          ),
        );
        break;
      case 'delete':
        _confirmDelete(property);
        break;
    }
  }

  void _confirmDelete(Property property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text(
          'Are you sure you want to delete "${property.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await context.read<PropertyProvider>()
                  .deleteProperty(property.id);
              if (success && mounted) {
                context.pop(); // Return to property list
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _createProject(Property property) {
    // TODO: Navigate to create project screen with property pre-selected
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create project functionality coming soon')),
    );
  }
}