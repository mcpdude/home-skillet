import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../models/property.dart';
import '../../providers/property_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_overlay.dart';
import 'add_edit_property_screen.dart';

class PropertySettingsScreen extends StatefulWidget {
  final String propertyId;

  const PropertySettingsScreen({
    Key? key,
    required this.propertyId,
  }) : super(key: key);

  @override
  State<PropertySettingsScreen> createState() => _PropertySettingsScreenState();
}

class _PropertySettingsScreenState extends State<PropertySettingsScreen> {
  Property? _property;
  bool _isLoading = false;
  String? _errorMessage;

  // Mock user data - in real app this would come from API
  final List<PropertyUser> _propertyUsers = [
    PropertyUser(
      id: '1',
      email: 'john.doe@example.com',
      name: 'John Doe',
      role: PropertyRole.owner,
      permissions: PropertyPermissions.all(),
      invitedAt: DateTime.now().subtract(const Duration(days: 30)),
      isActive: true,
    ),
    PropertyUser(
      id: '2',
      email: 'jane.smith@example.com', 
      name: 'Jane Smith',
      role: PropertyRole.manager,
      permissions: PropertyPermissions(
        canView: true,
        canEdit: true,
        canDelete: false,
        canManageUsers: true,
        canCreateProjects: true,
        canManageTasks: true,
      ),
      invitedAt: DateTime.now().subtract(const Duration(days: 15)),
      isActive: true,
    ),
    PropertyUser(
      id: '3',
      email: 'contractor@example.com',
      name: 'Mike Contractor',
      role: PropertyRole.contractor,
      permissions: PropertyPermissions(
        canView: true,
        canEdit: false,
        canDelete: false,
        canManageUsers: false,
        canCreateProjects: false,
        canManageTasks: true,
      ),
      invitedAt: DateTime.now().subtract(const Duration(days: 5)),
      isActive: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  void _loadProperty() {
    final propertyProvider = context.read<PropertyProvider>();
    _property = propertyProvider.getPropertyById(widget.propertyId);
    if (_property == null) {
      _errorMessage = 'Property not found';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property Settings')),
        body: const Center(
          child: Text('Property not found'),
        ),
      );
    }

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Property Settings'),
          actions: [
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
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
                  value: 'archive',
                  child: ListTile(
                    leading: Icon(Icons.archive),
                    title: Text('Archive Property'),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Info Card
              _buildPropertyInfoCard(),
              const SizedBox(height: 24),

              // Access Control Section
              _buildAccessControlSection(),
              const SizedBox(height: 24),

              // Notification Settings
              _buildNotificationSettings(),
              const SizedBox(height: 24),

              // Privacy & Security
              _buildPrivacySettings(),
              const SizedBox(height: 24),

              // Data Management
              _buildDataManagementSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Property Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _editProperty,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(Icons.home, color: Theme.of(context).primaryColor),
              ),
              title: Text(_property!.name),
              subtitle: Text(_property!.address),
            ),
            const Divider(),
            Row(
              children: [
                _buildInfoItem('Type', _getPropertyTypeText(_property!.type)),
                const SizedBox(width: 24),
                if (_property!.yearBuilt != null)
                  _buildInfoItem('Built', _property!.yearBuilt.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
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
      ),
    );
  }

  Widget _buildAccessControlSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Access Control',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _inviteUser,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Invite'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Manage who can access this property and their permissions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Users List
            ...(_propertyUsers.map((user) => _buildUserTile(user))),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(PropertyUser user) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
        child: Text(
          user.name.split(' ').map((n) => n[0]).join().toUpperCase(),
          style: TextStyle(
            color: _getRoleColor(user.role),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(user.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getRoleText(user.role),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getRoleColor(user.role),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Added ${_formatDate(user.invitedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => _handleUserAction(action, user),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text('Edit Permissions'),
          ),
          const PopupMenuItem(
            value: 'remove',
            child: Text('Remove Access'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              'Project Updates',
              'Get notified when projects are updated',
              true,
              (value) {},
            ),
            _buildSwitchTile(
              'Task Completions',
              'Get notified when tasks are completed',
              true,
              (value) {},
            ),
            _buildSwitchTile(
              'New Comments',
              'Get notified of new comments and messages',
              false,
              (value) {},
            ),
            _buildSwitchTile(
              'Due Date Reminders',
              'Get reminded about upcoming due dates',
              true,
              (value) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy & Security',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              'Make Property Public',
              'Allow property to be discoverable',
              false,
              (value) {},
            ),
            _buildSwitchTile(
              'Share Usage Analytics',
              'Help improve the app by sharing anonymous usage data',
              true,
              (value) {},
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.security),
              title: const Text('Data Export'),
              subtitle: const Text('Download all property data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _exportData,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock),
              title: const Text('Privacy Policy'),
              subtitle: const Text('View how your data is protected'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _viewPrivacyPolicy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.backup, color: Theme.of(context).primaryColor),
              title: const Text('Backup Property Data'),
              subtitle: const Text('Create a backup of all property information'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _backupData,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.archive, color: Colors.orange),
              title: const Text('Archive Property'),
              subtitle: const Text('Hide property from active list'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _archiveProperty,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Property'),
              subtitle: const Text('Permanently delete property and all data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _deleteProperty,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
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
      case PropertyType.other:
        return 'Other';
    }
  }

  Color _getRoleColor(PropertyRole role) {
    switch (role) {
      case PropertyRole.owner:
        return Colors.purple;
      case PropertyRole.manager:
        return Colors.blue;
      case PropertyRole.contractor:
        return Colors.green;
      case PropertyRole.viewer:
        return Colors.grey;
    }
  }

  String _getRoleText(PropertyRole role) {
    switch (role) {
      case PropertyRole.owner:
        return 'Owner';
      case PropertyRole.manager:
        return 'Manager';
      case PropertyRole.contractor:
        return 'Contractor';
      case PropertyRole.viewer:
        return 'Viewer';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).round()} weeks ago';
    return '${(difference / 30).round()} months ago';
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editProperty();
        break;
      case 'archive':
        _archiveProperty();
        break;
      case 'delete':
        _deleteProperty();
        break;
    }
  }

  void _handleUserAction(String action, PropertyUser user) {
    switch (action) {
      case 'edit':
        _editUserPermissions(user);
        break;
      case 'remove':
        _removeUserAccess(user);
        break;
    }
  }

  void _editProperty() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditPropertyScreen(
          propertyId: widget.propertyId,
          isEdit: true,
        ),
      ),
    );
  }

  void _inviteUser() {
    // Show invite user dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite User'),
        content: const Text('User invitation functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  void _editUserPermissions(PropertyUser user) {
    // Show edit permissions dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${user.name} Permissions'),
        content: const Text('Permission editing functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeUserAccess(PropertyUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Access'),
        content: Text('Remove ${user.name}\'s access to this property?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export functionality coming soon')),
    );
  }

  void _viewPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy policy would be shown here')),
    );
  }

  void _backupData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup functionality coming soon')),
    );
  }

  void _archiveProperty() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Property'),
        content: const Text('Archive this property? It will be hidden from your active properties list but can be restored later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _deleteProperty() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text(
          'Are you sure you want to permanently delete this property?\n\n'
          'This will delete all associated projects, tasks, and data. This action cannot be undone.',
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
                  .deleteProperty(widget.propertyId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Property deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
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
}

// Property User Management Models
class PropertyUser {
  final String id;
  final String email;
  final String name;
  final PropertyRole role;
  final PropertyPermissions permissions;
  final DateTime invitedAt;
  final bool isActive;

  PropertyUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
    required this.invitedAt,
    required this.isActive,
  });
}

enum PropertyRole {
  owner,
  manager,
  contractor,
  viewer,
}

class PropertyPermissions {
  final bool canView;
  final bool canEdit;
  final bool canDelete;
  final bool canManageUsers;
  final bool canCreateProjects;
  final bool canManageTasks;

  PropertyPermissions({
    required this.canView,
    required this.canEdit,
    required this.canDelete,
    required this.canManageUsers,
    required this.canCreateProjects,
    required this.canManageTasks,
  });

  factory PropertyPermissions.all() {
    return PropertyPermissions(
      canView: true,
      canEdit: true,
      canDelete: true,
      canManageUsers: true,
      canCreateProjects: true,
      canManageTasks: true,
    );
  }

  factory PropertyPermissions.readOnly() {
    return PropertyPermissions(
      canView: true,
      canEdit: false,
      canDelete: false,
      canManageUsers: false,
      canCreateProjects: false,
      canManageTasks: false,
    );
  }
}