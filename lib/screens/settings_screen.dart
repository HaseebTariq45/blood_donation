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

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  String _selectedLanguage = 'English';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _languages = ['English', 'Spanish', 'French', 'Arabic', 'Urdu'];

  @override
  void initState() {
    super.initState();
    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Settings',
        showBackButton: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          children: [
            // App Settings Card
            _buildSettingsCard(
              title: 'App Settings',
              children: [
                // Dark Mode
                _buildSettingItem(
                  title: 'Dark Mode',
                  subtitle: 'Switch between light and dark themes',
                  icon: Icons.dark_mode,
                  trailing: Switch(
                    value: appProvider.isDarkMode,
                    onChanged: (value) {
                      // Toggle theme mode in provider (UI only, as specified)
                      setState(() {
                        appProvider.toggleThemeMode();
                      });
                    },
                    activeColor: AppConstants.primaryColor,
                  ),
                ),
                const Divider(),
                
                // Language Selector
                _buildSettingItem(
                  title: 'Language',
                  subtitle: 'Select your preferred language',
                  icon: Icons.language,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      isDense: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: AppConstants.primaryColor),
                      style: const TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedLanguage = newValue;
                          });
                        }
                      },
                      items: _languages.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Notification Settings Card
            _buildSettingsCard(
              title: 'Notifications',
              children: [
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
                  const Divider(),
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
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Privacy Settings Card
            _buildSettingsCard(
              title: 'Privacy & Permission',
              children: [
                _buildSettingItem(
                  title: 'Location Services',
                  subtitle: 'Allow app to access your location for nearby blood banks',
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
                _buildSettingItem(
                  title: 'Data Usage',
                  subtitle: 'Control how the app uses your data',
                  icon: Icons.data_usage,
                  onTap: () {
                    // Navigate to data usage settings
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // About & Legal Card
            _buildSettingsCard(
              title: 'About & Legal',
              children: [
                _buildSettingItem(
                  title: 'Privacy Policy',
                  icon: Icons.privacy_tip,
                  onTap: () {
                    // Navigate to privacy policy
                  },
                ),
                const Divider(),
                _buildSettingItem(
                  title: 'Terms of Service',
                  icon: Icons.description,
                  onTap: () {
                    // Navigate to terms of service
                  },
                ),
                const Divider(),
                _buildSettingItem(
                  title: 'About Us',
                  icon: Icons.info,
                  onTap: () {
                    // Navigate to about us
                    Navigator.pushNamed(context, '/about_us');
                  },
                ),
                const Divider(),
                _buildSettingItem(
                  title: 'Contact Support',
                  icon: Icons.support_agent,
                  onTap: () {
                    // Navigate to support
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Account Settings Card
            _buildSettingsCard(
              title: 'Account',
              children: [
                _buildSettingItem(
                  title: 'Change Password',
                  icon: Icons.lock,
                  onTap: () {
                    // Navigate to change password
                  },
                ),
                const Divider(),
                _buildSettingItem(
                  title: 'Logout',
                  icon: Icons.logout,
                  onTap: () {
                    _showLogoutDialog();
                  },
                ),
                const Divider(),
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
              ],
            ),
            
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'App Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: children,
            ),
          ),
        ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null)
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
          ],
        ),
      ),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your personal data, donation history, and blood requests will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle account deletion
              // For now, show a success snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deleted successfully'),
                  backgroundColor: AppConstants.errorColor,
                ),
              );
              // Navigate back to login screen
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle logout
              // Navigate back to login screen
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }
} 