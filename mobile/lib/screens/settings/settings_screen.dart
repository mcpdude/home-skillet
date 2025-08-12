import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            context,
            'Account',
            [
              _buildSettingTile(
                context,
                icon: Icons.person,
                title: 'Profile Settings',
                subtitle: 'Manage your personal information',
                onTap: () => _profileSettings(context),
              ),
              _buildSettingTile(
                context,
                icon: Icons.security,
                title: 'Privacy & Security',
                subtitle: 'Password, authentication settings',
                onTap: () => _privacySecurity(context),
              ),
            ],
          ),
          
          _buildSection(
            context,
            'Preferences',
            [
              _buildSettingTile(
                context,
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Push notifications, email alerts',
                onTap: () => _notificationSettings(context),
              ),
              _buildSettingTile(
                context,
                icon: Icons.dark_mode,
                title: 'Appearance',
                subtitle: 'Theme, display options',
                onTap: () => _appearanceSettings(context),
              ),
              _buildSettingTile(
                context,
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English (US)',
                onTap: () => _languageSettings(context),
              ),
            ],
          ),

          _buildSection(
            context,
            'Data & Storage',
            [
              _buildSettingTile(
                context,
                icon: Icons.backup,
                title: 'Backup & Sync',
                subtitle: 'Cloud backup settings',
                onTap: () => _backupSettings(context),
              ),
              _buildSettingTile(
                context,
                icon: Icons.storage,
                title: 'Storage',
                subtitle: 'Manage app data and cache',
                onTap: () => _storageSettings(context),
              ),
            ],
          ),

          _buildSection(
            context,
            'Support',
            [
              _buildSettingTile(
                context,
                icon: Icons.help,
                title: 'Help & Support',
                subtitle: 'FAQs, contact support',
                onTap: () => _helpSupport(context),
              ),
              _buildSettingTile(
                context,
                icon: Icons.feedback,
                title: 'Send Feedback',
                subtitle: 'Report issues, suggest features',
                onTap: () => _sendFeedback(context),
              ),
              _buildSettingTile(
                context,
                icon: Icons.info,
                title: 'About',
                subtitle: 'Version info, terms of service',
                onTap: () => _aboutApp(context),
              ),
            ],
          ),

          _buildSection(
            context,
            'Account Actions',
            [
              _buildSettingTile(
                context,
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                textColor: Colors.red,
                onTap: () => _confirmSignOut(context),
              ),
              _buildSettingTile(
                context,
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                textColor: Colors.red,
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8, top: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: tiles,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: (textColor ?? Theme.of(context).colorScheme.onSurface)
              .withOpacity(0.7),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }

  // Settings actions
  void _profileSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile settings coming soon')),
    );
  }

  void _privacySecurity(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy & security settings coming soon')),
    );
  }

  void _notificationSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings coming soon')),
    );
  }

  void _appearanceSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appearance Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System Default'),
              leading: Radio<String>(
                value: 'system',
                groupValue: 'system', // This would come from app state
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('Light Mode'),
              leading: Radio<String>(
                value: 'light',
                groupValue: 'system',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('Dark Mode'),
              leading: Radio<String>(
                value: 'dark',
                groupValue: 'system',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
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

  void _languageSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language settings coming soon')),
    );
  }

  void _backupSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup settings coming soon')),
    );
  }

  void _storageSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('App Data'),
              subtitle: const Text('~15.2 MB'),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Clear'),
              ),
            ),
            ListTile(
              title: const Text('Cache'),
              subtitle: const Text('~8.7 MB'),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Clear'),
              ),
            ),
            ListTile(
              title: const Text('Images'),
              subtitle: const Text('~42.1 MB'),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Clear'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _helpSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & support coming soon')),
    );
  }

  void _sendFeedback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback feature coming soon')),
    );
  }

  void _aboutApp(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Home Skillet',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.home_work, size: 64),
      children: [
        const Text('Home Skillet helps you manage your home maintenance projects efficiently.'),
        const SizedBox(height: 16),
        const Text('Built with Flutter and powered by modern technology.'),
      ],
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion feature coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}