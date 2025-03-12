import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Settings',
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Settings
              _buildSectionHeader('App Theme'),
              _buildSettingItem(
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark themes',
                icon: Icons.dark_mode,
                trailing: Switch(
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() {
                      _darkMode = value;
                    });
                    // Toggle theme mode in provider
                    appProvider.toggleThemeMode();
                  },
                  activeColor: AppConstants.primaryColor,
                ),
              ),
              const Divider(),
              
              // Notification Settings
              _buildSectionHeader('Notifications'),
              _buildSettingItem(
                title: 'Enable Notifications',
                subtitle: 'Receive notifications about blood requests and updates',
                icon: Icons.notifications,
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                      if (!value) {
                        _emailNotifications = false;
                        _smsNotifications = false;
                        _pushNotifications = false;
                      }
                    });
                  },
                  activeColor: AppConstants.primaryColor,
                ),
              ),
              if (_notificationsEnabled) ...[
                _buildIndentedSettingItem(
                  title: 'Email Notifications',
                  icon: Icons.email,
                  trailing: Switch(
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() {
                        _emailNotifications = value;
                      });
                    },
                    activeColor: AppConstants.primaryColor,
                  ),
                ),
                _buildIndentedSettingItem(
                  title: 'SMS Notifications',
                  icon: Icons.sms,
                  trailing: Switch(
                    value: _smsNotifications,
                    onChanged: (value) {
                      setState(() {
                        _smsNotifications = value;
                      });
                    },
                    activeColor: AppConstants.primaryColor,
                  ),
                ),
                _buildIndentedSettingItem(
                  title: 'Push Notifications',
                  icon: Icons.notifications_active,
                  trailing: Switch(
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() {
                        _pushNotifications = value;
                      });
                    },
                    activeColor: AppConstants.primaryColor,
                  ),
                ),
              ],
              const Divider(),
              
              // Privacy Settings
              _buildSectionHeader('Privacy & Permission'),
              _buildSettingItem(
                title: 'Location Services',
                subtitle: 'Allow app to access your location for finding nearby blood banks',
                icon: Icons.location_on,
                trailing: Switch(
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                  },
                  activeColor: AppConstants.primaryColor,
                ),
              ),
              const Divider(),
              
              // About & Policies
              _buildSectionHeader('About & Policies'),
              _buildSettingItem(
                title: 'Privacy Policy',
                icon: Icons.privacy_tip,
                onTap: () {
                  // Navigate to privacy policy
                },
              ),
              _buildSettingItem(
                title: 'Terms of Service',
                icon: Icons.description,
                onTap: () {
                  // Navigate to terms of service
                },
              ),
              _buildSettingItem(
                title: 'About Us',
                icon: Icons.info,
                onTap: () {
                  // Navigate to about us
                },
              ),
              const Divider(),
              
              // Account Settings
              _buildSectionHeader('Account'),
              _buildSettingItem(
                title: 'Change Password',
                icon: Icons.lock,
                onTap: () {
                  // Navigate to change password
                },
              ),
              _buildSettingItem(
                title: 'Delete Account',
                icon: Icons.delete_forever,
                iconColor: AppConstants.errorColor,
                titleColor: AppConstants.errorColor,
                onTap: () {
                  // Show delete account confirmation dialog
                  _showDeleteAccountDialog();
                },
              ),
              
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'App Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required IconData icon,
    Color iconColor = AppConstants.primaryColor,
    Color titleColor = AppConstants.darkTextColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: AppConstants.lightTextColor,
                fontSize: 12,
              ),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildIndentedSettingItem({
    required String title,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        leading: Icon(
          icon,
          color: AppConstants.lightTextColor,
          size: 20,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        dense: true,
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is irreversible. All your data will be permanently deleted. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              // Handle delete account
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: Text(
              'DELETE',
              style: TextStyle(
                color: AppConstants.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 