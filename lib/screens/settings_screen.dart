import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/localization/app_localization.dart';
import '../utils/theme_helper.dart';
import '../utils/location_service.dart';
import '../utils/notification_service.dart';
import 'data_usage_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = false;
  bool _locationEnabled = false;
  bool _emailNotifications = false;
  bool _smsNotifications = false;
  bool _pushNotifications = false;
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
    
    // Load settings from provider
    _loadSettings();
  }
  
  void _loadSettings() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      _locationEnabled = appProvider.isLocationEnabled;
      _notificationsEnabled = appProvider.notificationsEnabled;
      _emailNotifications = appProvider.emailNotificationsEnabled;
      _pushNotifications = appProvider.pushNotificationsEnabled;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;
    
    // Calculate responsive sizes
    final double titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final double itemTitleFontSize = isSmallScreen ? 14.0 : 16.0;
    final double subtitleFontSize = isSmallScreen ? 11.0 : 12.0;
    final double versionFontSize = isSmallScreen ? 10.0 : 12.0;
    final double dropdownFontSize = isSmallScreen ? 12.0 : 14.0;
    
    // Calculate icon sizes
    final double iconSize = isSmallScreen ? 18.0 : 20.0;
    final double indentedIconSize = isSmallScreen ? 16.0 : 18.0;
    final double iconContainerSize = isSmallScreen ? 36.0 : 40.0;
    
    // Calculate padding based on screen size
    final double mainPadding = screenWidth * 0.04;
    final double cardPadding = isSmallScreen ? 12.0 : 16.0;
    final double itemPadding = isSmallScreen ? 6.0 : 8.0;
    final double itemSpacing = isSmallScreen ? 12.0 : 16.0;
    final double sectionSpacing = isSmallScreen ? 12.0 : 16.0;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'settings'.tr(context),
        showBackButton: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ListView(
                padding: EdgeInsets.all(mainPadding),
                children: [
                  // App Settings Card
                  _buildSettingsCard(
                    title: 'app_settings'.tr(context),
                    titleFontSize: titleFontSize,
                    cardPadding: cardPadding,
                    children: [
                      // Dark Mode
                      _buildSettingItem(
                        title: 'dark_mode'.tr(context),
                        subtitle: 'Switch between light and dark themes'.tr(context),
                        icon: Icons.dark_mode,
                        titleFontSize: itemTitleFontSize,
                        subtitleFontSize: subtitleFontSize,
                        iconSize: iconSize,
                        iconContainerSize: iconContainerSize,
                        itemPadding: itemPadding,
                        itemSpacing: itemSpacing,
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
                        titleFontSize: itemTitleFontSize,
                        subtitleFontSize: subtitleFontSize,
                        iconSize: iconSize,
                        iconContainerSize: iconContainerSize,
                        itemPadding: itemPadding,
                        itemSpacing: itemSpacing,
                        trailing: Builder(
                          builder: (context) => Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12, 
                              vertical: isSmallScreen ? 6 : 8
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButton<String>(
                              value: appProvider.selectedLanguage,
                              isDense: true,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.arrow_drop_down, 
                                color: AppConstants.primaryColor,
                                size: isSmallScreen ? 18 : 24,
                              ),
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: dropdownFontSize,
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
                  
                  SizedBox(height: sectionSpacing),
                  
                  // Notification Settings Card
                  _buildSettingsCard(
                    title: 'notifications_settings'.tr(context),
                    titleFontSize: titleFontSize,
                    cardPadding: cardPadding,
                    children: [
                      _buildSettingItem(
                        title: 'Notification Preferences'.tr(context),
                        subtitle: 'Manage your notification preferences',
                        icon: Icons.notifications,
                        titleFontSize: itemTitleFontSize,
                        subtitleFontSize: subtitleFontSize,
                        iconSize: iconSize,
                        iconContainerSize: iconContainerSize,
                        itemPadding: itemPadding,
                        itemSpacing: itemSpacing,
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: isSmallScreen ? 16.0 : 18.0,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54,
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/notification_settings');
                        },
                      ),
                    ],
                  ),
                  
                  SizedBox(height: sectionSpacing),
                  
                  // Privacy Settings Card
                  _buildSettingsCard(
                    title: 'privacy_permission'.tr(context),
                    titleFontSize: titleFontSize,
                    cardPadding: cardPadding,
                    children: [
                      _buildSettingItem(
                        title: 'location_services'.tr(context),
                        subtitle: 'Allow app to access your location for nearby blood banks'.tr(context),
                        icon: Icons.location_on,
                        titleFontSize: itemTitleFontSize,
                        subtitleFontSize: subtitleFontSize,
                        iconSize: iconSize,
                        iconContainerSize: iconContainerSize,
                        itemPadding: itemPadding,
                        itemSpacing: itemSpacing,
                        trailing: Switch(
                          value: _locationEnabled,
                          onChanged: (value) async {
                            final appProvider = Provider.of<AppProvider>(context, listen: false);
                            
                            if (value) {
                              // Try to enable location
                              final success = await appProvider.enableLocation();
                              if (!success) {
                                _showLocationPermissionDialog();
                              }
                            } else {
                              // Disable location
                              await appProvider.disableLocation();
                            }
                            
                            setState(() {
                              _locationEnabled = appProvider.isLocationEnabled;
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
                        titleFontSize: itemTitleFontSize,
                        subtitleFontSize: subtitleFontSize,
                        iconSize: iconSize,
                        iconContainerSize: iconContainerSize,
                        itemPadding: itemPadding,
                        itemSpacing: itemSpacing,
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
                  
                  SizedBox(height: sectionSpacing),
                  
                  // About & Legal Card
                  _buildSettingsCard(
                    title: 'about_legal'.tr(context),
                    titleFontSize: titleFontSize,
                    cardPadding: cardPadding,
                    children: [
                      _buildSettingItem(
                        title: 'privacy_policy'.tr(context),
                        icon: Icons.privacy_tip,
                        titleFontSize: itemTitleFontSize,
                        iconSize: iconSize,
                        iconContainerSize: iconContainerSize,
                        itemPadding: itemPadding,
                        itemSpacing: itemSpacing,
                        onTap: () {
                          // Navigate to privacy policy
                          Navigator.pushNamed(context, '/privacy_policy');
                        },
                      ),
                      const Divider(),
                      _buildSettingItem(
                        title: 'terms_of_service'.tr(context),
                        icon: Icons.description,
                        titleFontSize: itemTitleFontSize,
                        iconSize: iconSize,
                        iconContainerSize: iconContainerSize,
                        itemPadding: itemPadding,
                        itemSpacing: itemSpacing,
                        onTap: () {
                          // Navigate to terms of service
                          Navigator.pushNamed(context, '/terms_conditions');
                        },
                      ),
                      const Divider(),
                      _buildSettingItem(
                        title: 'about_us'.tr(context),
                        icon: Icons.info,
                        titleFontSize: itemTitleFontSize,
                        iconSize: iconSize,
                        iconContainerSize: iconContainerSize,
                        itemPadding: itemPadding,
                        itemSpacing: itemSpacing,
                        onTap: () {
                          // Navigate to about us
                          Navigator.pushNamed(context, '/about_us');
                        },
                      ),
                      const Divider(),
                      _buildSettingItem(
                        title: 'contact_support'.tr(context),
                        icon: Icons.support_agent,
                        titleFontSize: itemTitleFontSize,
                        iconSize: iconSize,
                        iconContainerSize: iconContainerSize,
                        itemPadding: itemPadding,
                        itemSpacing: itemSpacing,
                        onTap: () {
                          // Navigate to support
                        },
                      ),
                    ],
                  ),
                  
                  SizedBox(height: sectionSpacing),
                  
                  // Account Settings Card
                  _buildSettingsCard(
                    title: 'account'.tr(context),
                    titleFontSize: titleFontSize,
                    cardPadding: cardPadding,
                    children: [
                      _buildSettingItem(
                        title: 'change_password'.tr(context),
                        icon: Icons.lock,
                        titleFontSize: itemTitleFontSize,
                        iconSize: iconSize,
                        iconContainerSize: iconContainerSize,
                        itemPadding: itemPadding,
                        itemSpacing: itemSpacing,
                        onTap: () {
                          // Navigate to change password
                          _showChangePasswordDialog(
                            titleFontSize: titleFontSize,
                            bodyFontSize: subtitleFontSize + 2,
                          );
                        },
                      ),
                      const Divider(),
                      _buildSettingItem(
                        title: 'logout'.tr(context),
                        icon: Icons.logout,
                        titleFontSize: itemTitleFontSize,
                        iconSize: iconSize,
                        iconContainerSize: iconContainerSize,
                        itemPadding: itemPadding,
                        itemSpacing: itemSpacing,
                        onTap: () {
                          _showLogoutDialog(
                            titleFontSize: titleFontSize,
                            bodyFontSize: subtitleFontSize + 2,
                          );
                        },
                      ),
                      const Divider(),
                      _buildSettingItem(
                        title: 'delete_account'.tr(context),
                        icon: Icons.delete_forever,
                        iconColor: AppConstants.errorColor,
                        titleColor: AppConstants.errorColor,
                        titleFontSize: itemTitleFontSize,
                        iconSize: iconSize,
                        iconContainerSize: iconContainerSize,
                        itemPadding: itemPadding,
                        itemSpacing: itemSpacing,
                        onTap: () {
                          // Show delete account confirmation dialog
                          _showDeleteAccountDialog(
                            titleFontSize: titleFontSize,
                            bodyFontSize: subtitleFontSize + 2,
                          );
                        },
                      ),
                    ],
                  ),
                  
                  SizedBox(height: sectionSpacing * 1.5),
                  Center(
                    child: Builder(
                      builder: (context) => Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
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
                            fontSize: versionFontSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: sectionSpacing),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title, 
    required List<Widget> children,
    required double titleFontSize,
    required double cardPadding,
  }) {
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
                padding: EdgeInsets.all(cardPadding),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
              Divider(height: 1, color: context.dividerColor),
              Padding(
                padding: EdgeInsets.all(cardPadding),
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
    required double titleFontSize,
    double subtitleFontSize = 12.0,
    required double iconSize,
    double iconContainerSize = 40.0,
    required double itemPadding,
    required double itemSpacing,
  }) {
    return Builder(
      builder: (context) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: itemPadding),
            child: Row(
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  padding: EdgeInsets.all(iconContainerSize * 0.25),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: itemSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? context.textColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: itemPadding * 0.5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
                if (onTap != null && trailing == null)
                  Icon(
                    Icons.chevron_right,
                    color: context.isDarkMode ? Colors.grey[400] : Colors.grey,
                    size: iconSize,
                  ),
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
    required double titleFontSize,
    required double iconSize,
    required double itemPadding,
    required double itemSpacing,
    required double leftPadding,
  }) {
    return Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: leftPadding),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: itemPadding),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppConstants.primaryColor,
                  size: iconSize,
                ),
                SizedBox(width: itemSpacing),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: context.textColor,
                      fontSize: titleFontSize,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
                if (onTap != null && trailing == null)
                  Icon(
                    Icons.chevron_right,
                    color: context.isDarkMode ? Colors.grey[400] : Colors.grey,
                    size: iconSize,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog({
    required double titleFontSize,
    required double bodyFontSize,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(), // Not used
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Theme.of(context).cardColor,
              elevation: 6,
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'logout'.tr(context),
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: Text(
                  'Are you sure you want to logout?'.tr(context),
                  style: TextStyle(
                    fontSize: bodyFontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: <Widget>[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text('cancel'.tr(context)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text('logout'.tr(context)),
                  onPressed: () async {
                    // Show a loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                )
                              ]
                            ),
                            child: const CircularProgressIndicator(),
                          ),
                        );
                      },
                    );
                    
                    try {
                      // Logout user and navigate to login screen
                      final appProvider = Provider.of<AppProvider>(context, listen: false);
                      await appProvider.logout();
                      
                      // Close both dialogs
                      Navigator.of(context).pop(); // Close loading dialog
                      Navigator.of(context).pop(); // Close logout dialog
                      
                      // Navigate to login screen
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    } catch (e) {
                      // Close loading dialog
                      Navigator.of(context).pop();
                      
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to logout: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog({
    required double titleFontSize,
    required double bodyFontSize,
  }) {
    final _passwordController = TextEditingController();
    bool _isLoading = false;
    String _errorMessage = '';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(), // Not used
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Theme.of(context).cardColor,
                  elevation: 6,
                  title: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConstants.errorColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: AppConstants.errorColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'delete_account'.tr(context),
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.errorColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppConstants.errorColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.errorColor.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppConstants.errorColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This action cannot be undone. All your data will be permanently deleted.'.tr(context),
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    color: AppConstants.errorColor.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Please enter your password to confirm:',
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_errorMessage.isNotEmpty) 
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppConstants.errorColor,
                                width: 2,
                              ),
                            ),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  actions: <Widget>[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text('cancel'.tr(context)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    if (_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.errorColor),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.errorColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        label: Text('delete'.tr(context)),
                        onPressed: () async {
                          if (_passwordController.text.isEmpty) {
                            setState(() {
                              _errorMessage = 'Password is required';
                            });
                            return;
                          }
                          
                          setState(() {
                            _isLoading = true;
                            _errorMessage = '';
                          });
                          
                          try {
                            // Delete account and navigate to login screen
                            final appProvider = Provider.of<AppProvider>(context, listen: false);
                            final success = await appProvider.deleteAccount(_passwordController.text);
                            
                            if (success) {
                              // Close dialog and navigate to login
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                              
                              // Show a success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Your account has been deleted'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              setState(() {
                                _isLoading = false;
                                _errorMessage = appProvider.authError;
                              });
                            }
                          } catch (e) {
                            setState(() {
                              _isLoading = false;
                              _errorMessage = 'An error occurred: $e';
                            });
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This feature requires location permission to find blood banks near you. '
          'Please enable location permission in your device settings.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              LocationService().openApplicationSettings();
            },
            child: const Text('OPEN SETTINGS'),
          ),
        ],
      ),
    );
  }

  void _sendTestNotifications() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final notificationService = NotificationService();
    
    // Display a snackbar to inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending test notifications...'),
        duration: Duration(seconds: 2),
      )
    );
    
    // Check which notification types are enabled and send appropriate tests
    if (appProvider.emailNotificationsEnabled) {
      await notificationService.sendEmailNotification(
        appProvider.currentUser.email,
        'Test Notification',
        'This is a test email notification from the BloodLine app.'
      );
    }
    
    if (appProvider.pushNotificationsEnabled) {
      await notificationService.sendPushNotification(
        appProvider.currentUser.id,
        'Test Notification',
        'This is a test push notification from the BloodLine app.'
      );
    }
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test notifications sent successfully!'),
        backgroundColor: AppConstants.successColor,
        duration: Duration(seconds: 3),
      )
    );
  }

  void _showChangePasswordDialog({
    required double titleFontSize,
    required double bodyFontSize,
  }) {
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    bool _isLoading = false;
    String _errorMessage = '';
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(), // Not used
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        
        return StatefulBuilder(
          builder: (context, setState) {
            return ScaleTransition(
              scale: curvedAnimation,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Theme.of(context).cardColor,
                elevation: 6,
                title: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: AppConstants.primaryColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_errorMessage.isNotEmpty) 
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      TextField(
                        controller: _currentPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: const Icon(Icons.vpn_key, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppConstants.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _newPasswordController,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppConstants.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppConstants.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                actions: <Widget>[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text('Cancel'.tr(context)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      child: const CircularProgressIndicator(),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text('Change Password'),
                      onPressed: () async {
                        // Validate inputs
                        if (_currentPasswordController.text.isEmpty ||
                            _newPasswordController.text.isEmpty ||
                            _confirmPasswordController.text.isEmpty) {
                          setState(() {
                            _errorMessage = 'All fields are required';
                          });
                          return;
                        }
                        
                        if (_newPasswordController.text != _confirmPasswordController.text) {
                          setState(() {
                            _errorMessage = 'New passwords do not match';
                          });
                          return;
                        }
                        
                        // Show loading
                        setState(() {
                          _isLoading = true;
                          _errorMessage = '';
                        });
                        
                        try {
                          // Get the current user
                          final user = FirebaseAuth.instance.currentUser;
                          final credentials = EmailAuthProvider.credential(
                            email: user!.email!,
                            password: _currentPasswordController.text,
                          );
                          
                          // Re-authenticate the user
                          await user.reauthenticateWithCredential(credentials);
                          
                          // Change the password
                          await user.updatePassword(_newPasswordController.text);
                          
                          // Close the dialog
                          Navigator.of(context).pop();
                          
                          // Show success message
                          _showSuccessSnackbar('Password changed successfully');
                        } catch (e) {
                          // Show error message
                          setState(() {
                            _isLoading = false;
                            if (e is FirebaseAuthException) {
                              switch (e.code) {
                                case 'wrong-password':
                                  _errorMessage = 'Current password is incorrect';
                                  break;
                                case 'weak-password':
                                  _errorMessage = 'New password is too weak';
                                  break;
                                default:
                                  _errorMessage = 'Error: ${e.message}';
                              }
                            } else {
                              _errorMessage = 'An error occurred. Please try again.';
                            }
                          });
                        }
                      },
                    ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }
} 