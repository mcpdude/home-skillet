import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../providers/property_provider.dart';
import 'add_edit_property_screen.dart';

/// Simple wrapper screen that provides a clean entry point to property creation
/// This screen can show property type selection or quick templates in the future
class AddPropertyScreen extends StatelessWidget {
  const AddPropertyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Property'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.home_work,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add Your Property',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start managing your property with our comprehensive property management tools.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Property type quick selection
            Text(
              'Choose Property Type',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Property type cards
            _PropertyTypeCard(
              type: PropertyType.house,
              icon: Icons.house,
              title: 'House',
              description: 'Single-family homes and detached properties',
              color: Colors.blue,
              onTap: () => _navigateToAddProperty(context, PropertyType.house),
            ),
            const SizedBox(height: 12),
            
            _PropertyTypeCard(
              type: PropertyType.apartment,
              icon: Icons.apartment,
              title: 'Apartment',
              description: 'Multi-unit residential buildings and units',
              color: Colors.green,
              onTap: () => _navigateToAddProperty(context, PropertyType.apartment),
            ),
            const SizedBox(height: 12),
            
            _PropertyTypeCard(
              type: PropertyType.condo,
              icon: Icons.domain,
              title: 'Condominium',
              description: 'Individual units within a larger complex',
              color: Colors.purple,
              onTap: () => _navigateToAddProperty(context, PropertyType.condo),
            ),
            const SizedBox(height: 12),
            
            _PropertyTypeCard(
              type: PropertyType.townhouse,
              icon: Icons.home_filled,
              title: 'Townhouse',
              description: 'Connected multi-story residential properties',
              color: Colors.orange,
              onTap: () => _navigateToAddProperty(context, PropertyType.townhouse),
            ),
            const SizedBox(height: 12),
            
            _PropertyTypeCard(
              type: PropertyType.commercial,
              icon: Icons.business,
              title: 'Commercial',
              description: 'Office buildings, retail, and commercial spaces',
              color: Colors.red,
              onTap: () => _navigateToAddProperty(context, PropertyType.commercial),
            ),
            const SizedBox(height: 12),
            
            _PropertyTypeCard(
              type: PropertyType.other,
              icon: Icons.more_horiz,
              title: 'Other',
              description: 'Custom property types and mixed-use properties',
              color: Colors.grey,
              onTap: () => _navigateToAddProperty(context, PropertyType.other),
            ),
            const SizedBox(height: 32),
            
            // Quick start option
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _navigateToAddProperty(context, null),
                icon: const Icon(Icons.flash_on),
                label: const Text('Quick Add (I\'ll choose type later)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddProperty(BuildContext context, PropertyType? selectedType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditPropertyScreen(
          preselectedType: selectedType,
        ),
      ),
    );
  }
}

class _PropertyTypeCard extends StatelessWidget {
  final PropertyType type;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _PropertyTypeCard({
    Key? key,
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension to AddEditPropertyScreen to support preselected property type
extension AddEditPropertyScreenExtension on AddEditPropertyScreen {
  static AddEditPropertyScreen withPreselectedType(PropertyType? type) {
    return AddEditPropertyScreen(
      preselectedType: type,
    );
  }
}