import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/property_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_message.dart';
import '../../config/routes.dart';
import '../../models/property.dart';
import 'add_edit_property_screen.dart';

class PropertyDashboardScreen extends StatefulWidget {
  const PropertyDashboardScreen({Key? key}) : super(key: key);

  @override
  State<PropertyDashboardScreen> createState() => _PropertyDashboardScreenState();
}

class _PropertyDashboardScreenState extends State<PropertyDashboardScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  bool _isSearchActive = false;
  bool _showGridView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: PropertyType.values.length + 1, vsync: this);
    _loadProperties();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    await context.read<PropertyProvider>().loadProperties();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    context.read<PropertyProvider>().searchProperties(query);
    setState(() {
      _isSearchActive = query.isNotEmpty;
    });
  }

  void _onTabChanged() {
    final provider = context.read<PropertyProvider>();
    if (_tabController.index == 0) {
      // All properties
      provider.filterByType(null);
    } else {
      // Filter by specific type
      final type = PropertyType.values[_tabController.index - 1];
      provider.filterByType(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, child) {
        final properties = propertyProvider.properties;
        final isLoading = propertyProvider.isLoading;
        final hasError = propertyProvider.errorMessage != null;
        final propertyCounts = propertyProvider.getPropertiesCountByType();

        return LoadingOverlay(
          isLoading: isLoading,
          child: Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // App Bar with Search
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: true,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'My Properties (${propertyProvider.allProperties.length})',
                        style: const TextStyle(fontSize: 16),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(_showGridView ? Icons.list : Icons.grid_view),
                        onPressed: () {
                          setState(() => _showGridView = !_showGridView);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _showFilterBottomSheet,
                      ),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _buildSearchBar(),
                      ),
                    ),
                  ),

                  // Filter Tabs
                  if (!_isSearchActive)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          onTap: (_) => _onTabChanged(),
                          tabs: [
                            Tab(
                              child: _buildTabWithCount('All', propertyProvider.allProperties.length),
                            ),
                            ...PropertyType.values.map((type) {
                              final count = propertyCounts[type] ?? 0;
                              return Tab(
                                child: _buildTabWithCount(_getPropertyTypeText(type), count),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                ];
              },
              body: RefreshIndicator(
                onRefresh: _loadProperties,
                child: hasError
                    ? ErrorMessage(
                        message: propertyProvider.errorMessage!,
                        onRetry: _loadProperties,
                      )
                    : properties.isEmpty
                        ? _buildEmptyState(propertyProvider)
                        : _buildPropertiesList(properties),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _addProperty,
              icon: const Icon(Icons.add),
              label: const Text('Add Property'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search properties...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _isSearchActive
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<PropertyProvider>().clearFilters();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTabWithCount(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(PropertyProvider provider) {
    if (provider.hasFilters) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'No Properties Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Try adjusting your search or filter criteria',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  context.read<PropertyProvider>().clearFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Properties Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add your first property to start managing home maintenance projects',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addProperty,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Property'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesList(List<Property> properties) {
    if (_showGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          return _buildPropertyGridCard(properties[index]);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          return _buildPropertyCard(property, index);
        },
      );
    }
  }

  Widget _buildPropertyCard(Property property, int index) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Image
          Hero(
            tag: 'property_image_${property.id}',
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: _buildPropertyImage(property),
            ),
          ),
          
          // Property Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        property.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildPropertyTypeChip(property.type),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.address,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (property.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    property.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                
                // Property Stats
                Row(
                  children: [
                    if (property.bedrooms != null) ...[
                      _buildStatItem(Icons.bed_outlined, '${property.bedrooms}'),
                      const SizedBox(width: 16),
                    ],
                    if (property.bathrooms != null) ...[
                      _buildStatItem(Icons.bathtub_outlined, '${property.bathrooms}'),
                      const SizedBox(width: 16),
                    ],
                    if (property.squareFootage != null)
                      _buildStatItem(Icons.square_foot, '${property.squareFootage?.toInt()} sq ft'),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewPropertyDetails(property),
                        icon: const Icon(Icons.visibility),
                        label: const Text('Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewProjects(property),
                        icon: const Icon(Icons.construction),
                        label: const Text('Projects'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handlePropertyAction(value, property),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyGridCard(Property property) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewPropertyDetails(property),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: _buildPropertyImage(property, height: null),
              ),
            ),
            
            // Property Info
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    _buildPropertyTypeChip(property.type, isSmall: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyImage(Property property, {double? height}) {
    if (property.imageUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: CachedNetworkImage(
          imageUrl: property.imageUrls.first,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildPlaceholderImage(height),
        ),
      );
    }
    return _buildPlaceholderImage(height);
  }

  Widget _buildPlaceholderImage([double? height]) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(
        child: Icon(
          Icons.home,
          size: height != null ? height * 0.3 : 64,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildPropertyTypeChip(PropertyType type, {bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _getPropertyTypeColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getPropertyTypeColor(type).withOpacity(0.3),
        ),
      ),
      child: Text(
        _getPropertyTypeText(type),
        style: TextStyle(
          fontSize: isSmall ? 10 : 12,
          color: _getPropertyTypeColor(type),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getPropertyTypeColor(PropertyType type) {
    switch (type) {
      case PropertyType.house:
        return Colors.blue;
      case PropertyType.apartment:
        return Colors.green;
      case PropertyType.condo:
        return Colors.orange;
      case PropertyType.townhouse:
        return Colors.purple;
      case PropertyType.other:
        return Colors.grey;
    }
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
      case PropertyType.other:
        return 'Other';
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Properties',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    context.read<PropertyProvider>().clearFilters();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Property Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PropertyType.values.map((type) {
                return Consumer<PropertyProvider>(
                  builder: (context, provider, child) {
                    final isSelected = provider.selectedTypeFilter == type;
                    return FilterChip(
                      label: Text(_getPropertyTypeText(type)),
                      selected: isSelected,
                      onSelected: (selected) {
                        provider.filterByType(selected ? type : null);
                      },
                      selectedColor: _getPropertyTypeColor(type).withOpacity(0.2),
                      checkmarkColor: _getPropertyTypeColor(type),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addProperty() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditPropertyScreen(),
      ),
    );
  }

  void _viewPropertyDetails(Property property) {
    context.push('${AppRoutes.propertyDetail}/${property.id}');
  }

  void _viewProjects(Property property) {
    context.read<PropertyProvider>().selectProperty(property);
    context.push(AppRoutes.projects);
  }

  void _handlePropertyAction(String action, Property property) {
    switch (action) {
      case 'edit':
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
        _confirmDeleteProperty(property);
        break;
    }
  }

  void _confirmDeleteProperty(Property property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text(
          'Are you sure you want to delete "${property.name}"?\n\n'
          'This action cannot be undone and will also delete all associated projects and tasks.',
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Property deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Custom TabBar Delegate
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}