import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/localization/app_localization.dart';
import '../utils/theme_helper.dart';
import 'data_usage_screen.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'settings'.tr(context),
        showBackButton: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          children: [
            // App Settings Card
            _buildSettingsCard(
              title: 'app_settings'.tr(context),
              children: [
                // Dark Mode
                _buildSettingItem(
                  title: 'dark_mode'.tr(context),
                  subtitle: 'Switch between light and dark themes'.tr(context),
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
                  title: 'language'.tr(context),
                  subtitle: 'Select your preferred language'.tr(context),
                  icon: Icons.language,
                  trailing: Builder(
                    builder: (context) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButton<String>(
                        value: appProvider.selectedLanguage,
                        isDense: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: AppConstants.primaryColor),
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        dropdownColor: context.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              appProvider.setLanguage(newValue);
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
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Notification Settings Card
            _buildSettingsCard(
              title: 'notifications_settings'.tr(context),
              children: [
                _buildSettingItem(
                  title: 'enable_notifications'.tr(context),
                  subtitle: 'Receive notifications about blood requests and updates'.tr(context),
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
                    title: 'email_notifications'.tr(context),
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
                    title: 'sms_notifications'.tr(context),
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
                    title: 'push_notifications'.tr(context),
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
              title: 'privacy_permission'.tr(context),
              children: [
                _buildSettingItem(
                  title: 'location_services'.tr(context),
                  subtitle: 'Allow app to access your location for nearby blood banks'.tr(context),
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
                  title: 'data_usage'.tr(context),
                  subtitle: 'Control how the app uses your data'.tr(context),
                  icon: Icons.data_usage,
                  onTap: () {
                    // Navigate to data usage settings
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DataUsageScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // About & Legal Card
            _buildSettingsCard(
              title: 'about_legal'.tr(context),
              children: [
                _buildSettingItem(
                  title: 'privacy_policy'.tr(context),
                  icon: Icons.privacy_tip,
                  onTap: () {
                    // Navigate to privacy policy
                    Navigator.pushNamed(context, '/privacy_policy');
                  },
                ),
                const Divider(),
                _buildSettingItem(
                  title: 'terms_of_service'.tr(context),
                  icon: Icons.description,
                  onTap: () {
                    // Navigate to terms of service
                    Navigator.pushNamed(context, '/terms_conditions');
                  },
                ),
                const Divider(),
                _buildSettingItem(
                  title: 'about_us'.tr(context),
                  icon: Icons.info,
                  onTap: () {
                    // Navigate to about us
                    Navigator.pushNamed(context, '/about_us');
                  },
                ),
                const Divider(),
                _buildSettingItem(
                  title: 'contact_support'.tr(context),
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
              title: 'account'.tr(context),
              children: [
                _buildSettingItem(
                  title: 'change_password'.tr(context),
                  icon: Icons.lock,
                  onTap: () {
                    // Navigate to change password
                  },
                ),
                const Divider(),
                _buildSettingItem(
                  title: 'logout'.tr(context),
                  icon: Icons.logout,
                  onTap: () {
                    _showLogoutDialog();
                  },
                ),
                const Divider(),
                _buildSettingItem(
                  title: 'delete_account'.tr(context),
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
              child: Builder(
                builder: (context) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.isDarkMode 
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${'app_version'.tr(context)} 1.0.0',
                    style: TextStyle(
                      color: context.isDarkMode 
                          ? Colors.grey[400]
                          : Colors.grey[500],
                      fontSize: 12,
                    ),
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
    return Builder(
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: context.isDarkMode 
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
              Divider(height: 1, color: context.dividerColor),
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
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required IconData icon,
    Color iconColor = AppConstants.primaryColor,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Builder(
      builder: (context) {
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
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? context.textColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12, 
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildIndentedSettingItem({
    required String title,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Builder(
      builder: (context) => Padding(
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
                  color: AppConstants.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: context.textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
                if (onTap != null && trailing == null)
                  Icon(
                    Icons.chevron_right,
                    color: context.isDarkMode ? Colors.grey[400] : Colors.grey,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('logout'.tr(context)),
          content: Text('Are you sure you want to logout?'.tr(context)),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.tr(context)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('logout'.tr(context)),
              onPressed: () {
                // Logout user and navigate to login screen
                final appProvider = Provider.of<AppProvider>(context, listen: false);
                appProvider.logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('delete_account'.tr(context)),
          content: Text('This action cannot be undone. Are you sure you want to delete your account?'.tr(context)),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.tr(context)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('delete'.tr(context)),
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.errorColor,
              ),
              onPressed: () {
                // Delete account and navigate to login screen
                final appProvider = Provider.of<AppProvider>(context, listen: false);
                appProvider.logout(); // Just logout for now since we don't have a real backend
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }
} 