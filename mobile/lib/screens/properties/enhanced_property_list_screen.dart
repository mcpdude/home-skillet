import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/property_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_message.dart';
import '../../config/routes.dart';
import '../../models/property.dart';
import 'add_edit_property_screen.dart';
import 'property_detail_screen.dart';

class EnhancedPropertyListScreen extends StatefulWidget {
  const EnhancedPropertyListScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedPropertyListScreen> createState() => _EnhancedPropertyListScreenState();
}

class _EnhancedPropertyListScreenState extends State<EnhancedPropertyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  PropertyType? _selectedTypeFilter;
  bool _showFilters = false;
  
  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    await context.read<PropertyProvider>().loadProperties();
  }

  void _onSearchChanged(String query) {
    context.read<PropertyProvider>().searchProperties(query);
  }

  void _onTypeFilterChanged(PropertyType? type) {
    setState(() {
      _selectedTypeFilter = type;
    });
    context.read<PropertyProvider>().filterByType(type);
  }

  void _clearFilters() {
    setState(() {
      _selectedTypeFilter = null;
      _searchController.clear();
    });
    context.read<PropertyProvider>().clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, child) {
        final properties = propertyProvider.properties;
        final isLoading = propertyProvider.isLoading;
        final hasError = propertyProvider.errorMessage != null;

        return LoadingOverlay(
          isLoading: isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('My Properties'),
              actions: [
                IconButton(
                  icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadProperties,
                ),
              ],
              bottom: _showFilters
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(120),
                      child: _buildFilterSection(propertyProvider),
                    )
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: _buildSearchBar(),
                    ),
            ),
            body: RefreshIndicator(
              onRefresh: _loadProperties,
              child: hasError
                  ? ErrorMessage(
                      message: propertyProvider.errorMessage!,
                      onRetry: _loadProperties,
                    )
                  : properties.isEmpty
                      ? _buildEmptyState(propertyProvider)
                      : _buildPropertyList(properties, propertyProvider),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _showAddProperty,
              icon: const Icon(Icons.add),
              label: const Text('Add Property'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search properties...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildFilterSection(PropertyProvider propertyProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search properties...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          
          // Filter chips and clear button
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All Types'),
                      selected: _selectedTypeFilter == null,
                      onSelected: (selected) {
                        if (selected) _onTypeFilterChanged(null);
                      },
                    ),
                    ...PropertyType.values.map((type) => FilterChip(
                          label: Text(_getPropertyTypeText(type)),
                          selected: _selectedTypeFilter == type,
                          onSelected: (selected) {
                            _onTypeFilterChanged(selected ? type : null);
                          },
                        )),
                  ],
                ),
              ),
              if (propertyProvider.hasFilters)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(PropertyProvider propertyProvider) {
    final hasFilters = propertyProvider.hasFilters;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.home_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters ? 'No Properties Found' : 'No Properties Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'Try adjusting your search criteria or clear filters to see all properties.'
                  : 'Add your first property to start managing home maintenance projects',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (hasFilters)
              OutlinedButton(
                onPressed: _clearFilters,
                child: const Text('Clear Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: _showAddProperty,
                icon: const Icon(Icons.add),
                label: const Text('Add Property'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyList(List<Property> properties, PropertyProvider propertyProvider) {
    return Column(
      children: [
        // Results summary
        if (propertyProvider.hasFilters)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Text(
              'Found ${properties.length} propert${properties.length == 1 ? 'y' : 'ies'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        
        // Property list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return _buildEnhancedPropertyCard(property);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedPropertyCard(Property property) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Image with gradient overlay
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Background image or placeholder
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: property.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            property.imageUrls.first,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                _buildPlaceholderImage(),
                          ),
                        )
                      : _buildPlaceholderImage(),
                ),
                
                // Property type badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildPropertyTypeChip(property.type),
                ),
                
                // Property name overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    property.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 3.0,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Property Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address
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
                    if (property.yearBuilt != null) ...[
                      _buildStatItem(Icons.calendar_today_outlined, '${property.yearBuilt}'),
                      const SizedBox(width: 16),
                    ],
                    if (property.bedrooms != null) ...[
                      _buildStatItem(Icons.bed_outlined, '${property.bedrooms} bed'),
                      const SizedBox(width: 16),
                    ],
                    if (property.bathrooms != null) ...[
                      _buildStatItem(Icons.bathtub_outlined, '${property.bathrooms} bath'),
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
                        onPressed: () => _viewPropertyDetail(property),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.home,
          size: 64,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildPropertyTypeChip(PropertyType type) {
    Color chipColor;
    switch (type) {
      case PropertyType.house:
        chipColor = Colors.blue;
        break;
      case PropertyType.apartment:
        chipColor = Colors.green;
        break;
      case PropertyType.condo:
        chipColor = Colors.purple;
        break;
      case PropertyType.townhouse:
        chipColor = Colors.orange;
        break;
      case PropertyType.commercial:
        chipColor = Colors.red;
        break;
      case PropertyType.other:
        chipColor = Colors.grey;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getPropertyTypeText(type),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
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
      case PropertyType.commercial:
        return 'Commercial';
      case PropertyType.other:
        return 'Other';
    }
  }

  void _showAddProperty() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditPropertyScreen(),
      ),
    );
  }

  void _viewPropertyDetail(Property property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(propertyId: property.id),
      ),
    );
  }

  void _viewProjects(Property property) {
    // Set selected property and navigate to projects
    context.read<PropertyProvider>().selectProperty(property);
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => ProjectListScreen(propertyId: property.id),
    //   ),
    // );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Projects functionality coming soon!')),
    );
  }
}