import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/property_provider.dart';
import '../../providers/project_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_message.dart';
import '../../config/routes.dart';
import '../../models/property.dart';
import 'add_edit_property_screen.dart';
import 'property_settings_screen.dart';

class EnhancedPropertyDetailScreen extends StatefulWidget {
  final String propertyId;

  const EnhancedPropertyDetailScreen({
    Key? key,
    required this.propertyId,
  }) : super(key: key);

  @override
  State<EnhancedPropertyDetailScreen> createState() => _EnhancedPropertyDetailScreenState();
}

class _EnhancedPropertyDetailScreenState extends State<EnhancedPropertyDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  PageController _imageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPropertyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imageController.dispose();
    super.dispose();
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
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // Enhanced App Bar with Image Gallery
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
                      background: _buildImageGallery(property),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => _shareProperty(property),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleMenuAction(value, property),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit Property'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'settings',
                            child: ListTile(
                              leading: Icon(Icons.settings),
                              title: Text('Settings'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Delete Property'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ];
              },
              body: Column(
                children: [
                  // Tab Bar
                  Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Theme.of(context).primaryColor,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.info),
                          text: 'Details',
                        ),
                        Tab(
                          icon: Icon(Icons.construction),
                          text: 'Projects',
                        ),
                        Tab(
                          icon: Icon(Icons.analytics),
                          text: 'Analytics',
                        ),
                      ],
                    ),
                  ),
                  
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDetailsTab(property),
                        _buildProjectsTab(projects, property),
                        _buildAnalyticsTab(property, projects),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: _buildFloatingActionButton(property),
          ),
        );
      },
    );
  }

  Widget _buildImageGallery(Property property) {
    if (property.imageUrls.isEmpty) {
      return _buildPlaceholderImage();
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _imageController,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemCount: property.imageUrls.length,
          itemBuilder: (context, index) {
            return Hero(
              tag: 'property_image_${property.id}_$index',
              child: CachedNetworkImage(
                imageUrl: property.imageUrls[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholderImage(),
              ),
            );
          },
        ),
        
        // Image indicators
        if (property.imageUrls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: property.imageUrls.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
          ),
        
        // Image counter
        if (property.imageUrls.length > 1)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${property.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
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

  Widget _buildDetailsTab(Property property) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information Card
          _buildBasicInfoCard(property),
          const SizedBox(height: 16),
          
          // Property Statistics Card
          _buildPropertyStatsCard(property),
          const SizedBox(height: 16),
          
          // Location Information Card
          _buildLocationCard(property),
          const SizedBox(height: 16),
          
          // Additional Details Card
          _buildAdditionalDetailsCard(property),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(Property property) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
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
            
            if (property.description != null) ...[
              const SizedBox(height: 16),
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
            ],
            
            const SizedBox(height: 16),
            _buildPropertyTypeChip(property.type),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyStatsCard(Property property) {
    final stats = <Map<String, dynamic>>[
      if (property.yearBuilt != null)
        {'icon': Icons.calendar_today, 'label': 'Year Built', 'value': property.yearBuilt.toString()},
      if (property.squareFootage != null)
        {'icon': Icons.square_foot, 'label': 'Square Feet', 'value': '${property.squareFootage!.toInt()}'},
      if (property.bedrooms != null)
        {'icon': Icons.bed, 'label': 'Bedrooms', 'value': property.bedrooms.toString()},
      if (property.bathrooms != null)
        {'icon': Icons.bathtub, 'label': 'Bathrooms', 'value': property.bathrooms.toString()},
    ];

    if (stats.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              mainAxisSpacing: 16,
              children: stats.map((stat) => _buildStatItem(
                stat['icon'] as IconData,
                stat['label'] as String,
                stat['value'] as String,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(Property property) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(Icons.map, color: Theme.of(context).primaryColor),
              ),
              title: Text(property.address),
              subtitle: const Text('Tap to view on map'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _viewOnMap(property),
            ),
            
            const Divider(),
            
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _getDirections(property),
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _shareLocation(property),
                    icon: const Icon(Icons.share_location),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalDetailsCard(Property property) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('Property ID', property.id),
            _buildDetailRow('Owner ID', property.ownerId),
            _buildDetailRow('Created', _formatDate(property.createdAt)),
            _buildDetailRow('Last Updated', _formatDate(property.updatedAt)),
            
            if (property.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Images', '${property.imageUrls.length} photo${property.imageUrls.length != 1 ? 's' : ''}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsTab(List<dynamic> projects, Property property) {
    return RefreshIndicator(
      onRefresh: _loadPropertyData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Projects Overview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        projects.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Projects',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${projects.length} project${projects.length != 1 ? 's' : ''} in progress',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _createProject(property),
                      child: const Text('New Project'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Projects List
            if (projects.isEmpty)
              _buildEmptyProjectsState(property)
            else
              ...projects.map((project) => _buildProjectCard(project)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProjectsState(Property property) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.construction,
                size: 64,
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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _createProject(property),
                icon: const Icon(Icons.add),
                label: const Text('Create Project'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(dynamic project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getProjectStatusColor(project.status ?? 'planned'),
          child: Icon(
            _getProjectStatusIcon(project.status ?? 'planned'),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          project.title ?? 'Unnamed Project',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.description != null)
              Text(project.description!),
            const SizedBox(height: 4),
            Text(
              'Status: ${_getProjectStatusText(project.status ?? 'planned')}',
              style: TextStyle(
                color: _getProjectStatusColor(project.status ?? 'planned'),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('${AppRoutes.projectDetail}/${project.id}'),
      ),
    );
  }

  Widget _buildAnalyticsTab(Property property, List<dynamic> projects) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Value Card (Mock data)
          _buildPropertyValueCard(),
          const SizedBox(height: 16),
          
          // Maintenance Summary Card
          _buildMaintenanceSummaryCard(projects),
          const SizedBox(height: 16),
          
          // Cost Analysis Card
          _buildCostAnalysisCard(projects),
          const SizedBox(height: 16),
          
          // Activity Timeline Card
          _buildActivityTimelineCard(property, projects),
        ],
      ),
    );
  }

  Widget _buildPropertyValueCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property Value',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildValueMetric('Estimated Value', '\$450,000', Icons.home, Colors.green),
                _buildValueMetric('Investment', '\$15,000', Icons.trending_up, Colors.blue),
                _buildValueMetric('ROI', '+12%', Icons.percent, Colors.purple),
              ],
            ),
            
            const SizedBox(height: 16),
            Text(
              'Based on recent maintenance investments and market trends',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMaintenanceSummaryCard(List<dynamic> projects) {
    final completedProjects = projects.where((p) => p.status == 'completed').length;
    final activeProjects = projects.where((p) => p.status == 'in_progress').length;
    final plannedProjects = projects.where((p) => p.status == 'planned').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maintenance Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('Completed', completedProjects, Colors.green),
                ),
                Expanded(
                  child: _buildSummaryItem('Active', activeProjects, Colors.orange),
                ),
                Expanded(
                  child: _buildSummaryItem('Planned', plannedProjects, Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildCostAnalysisCard(List<dynamic> projects) {
    // Mock cost data - in real app this would be calculated from projects
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cost Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildCostRow('Total Spent', '\$12,450', Colors.red),
            const SizedBox(height: 8),
            _buildCostRow('Budget Remaining', '\$2,550', Colors.green),
            const SizedBox(height: 8),
            _buildCostRow('Average per Project', '\$2,490', Colors.blue),
            
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.83, // 83% of budget used
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              '83% of annual maintenance budget used',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTimelineCard(Property property, List<dynamic> projects) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Mock activity items
            _buildActivityItem(
              'Property created',
              _formatDate(property.createdAt),
              Icons.home,
              Colors.blue,
            ),
            if (projects.isNotEmpty) ...[
              _buildActivityItem(
                'First project started',
                '2 weeks ago',
                Icons.construction,
                Colors.orange,
              ),
              _buildActivityItem(
                'Project completed',
                '1 week ago',
                Icons.check_circle,
                Colors.green,
              ),
            ],
            _buildActivityItem(
              'Last updated',
              _formatDate(property.updatedAt),
              Icons.edit,
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeChip(PropertyType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        _getPropertyTypeText(type),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(Property property) {
    if (_tabController.index == 1) {
      // Projects tab - show create project FAB
      return FloatingActionButton.extended(
        onPressed: () => _createProject(property),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
        backgroundColor: Theme.of(context).primaryColor,
      );
    }
    
    return FloatingActionButton(
      onPressed: () => _editProperty(property),
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.edit),
    );
  }

  // Helper methods
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
      case PropertyType.other:
        return 'Other';
    }
  }

  Color _getProjectStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'planned':
        return Colors.blue;
      case 'on_hold':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getProjectStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.build;
      case 'planned':
        return Icons.schedule;
      case 'on_hold':
        return Icons.pause_circle;
      default:
        return Icons.schedule;
    }
  }

  String _getProjectStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'planned':
        return 'Planned';
      case 'on_hold':
        return 'On Hold';
      default:
        return 'Planned';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).round()} weeks ago';
    if (difference < 365) return '${(difference / 30).round()} months ago';
    return '${(difference / 365).round()} years ago';
  }

  // Action methods
  void _handleMenuAction(String action, Property property) {
    switch (action) {
      case 'edit':
        _editProperty(property);
        break;
      case 'settings':
        _openSettings(property);
        break;
      case 'delete':
        _confirmDelete(property);
        break;
    }
  }

  void _editProperty(Property property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditPropertyScreen(
          propertyId: property.id,
          isEdit: true,
        ),
      ),
    );
  }

  void _openSettings(Property property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PropertySettingsScreen(
          propertyId: property.id,
        ),
      ),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create project functionality coming soon')),
    );
  }

  void _shareProperty(Property property) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${property.name}...')),
    );
  }

  void _viewOnMap(Property property) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map view coming soon')),
    );
  }

  void _getDirections(Property property) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Directions coming soon')),
    );
  }

  void _shareLocation(Property property) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing location of ${property.name}...')),
    );
  }
}