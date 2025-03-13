import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/theme_helper.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  // Helper function to launch URLs
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // Helper function specifically for social media with multiple fallbacks
  Future<void> _launchSocialMedia(BuildContext context, String url, String username, String platform) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Try alternative URL formats
        String altUrl;
        switch (platform) {
          case 'twitter':
            altUrl = 'https://x.com/$username';
            break;
          case 'instagram':
            altUrl = 'instagram://user?username=$username';
            break;
          case 'github':
            altUrl = 'https://github.com/$username';
            break;
          case 'snapchat':
            altUrl = 'https://www.snapchat.com/add/$username';
            break;
          case 'threads':
            altUrl = 'https://www.threads.net/@$username';
            break;
          default:
            altUrl = url;
        }
        
        final Uri altUri = Uri.parse(altUrl);
        if (await canLaunchUrl(altUri)) {
          await launchUrl(altUri, mode: LaunchMode.externalApplication);
        } else {
          // Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open $platform. Check if you have the app installed.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper function for launching email
  Future<void> _launchEmail(BuildContext context, String email) async {
    final emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        // Try alternative approach
        final String mailtoUrl = 'mailto:$email';
        final Uri mailtoUri = Uri.parse(mailtoUrl);
        
        if (await canLaunchUrl(mailtoUri)) {
          await launchUrl(mailtoUri);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open email client for $email'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;
    
    // Calculate responsive sizes
    final double headerLogoSize = isSmallScreen ? 80.0 : 100.0;
    final double headerIconSize = isSmallScreen ? 50.0 : 60.0;
    final double headerTitleSize = isSmallScreen ? 20.0 : 24.0;
    final double headerSubtitleSize = isSmallScreen ? 14.0 : 16.0;
    
    final double sectionTitleSize = isSmallScreen ? 18.0 : 20.0;
    final double avatarRadius = isSmallScreen ? 35.0 : 40.0;
    final double avatarFontSize = isSmallScreen ? 20.0 : 24.0;
    
    final double nameFontSize = isSmallScreen ? 18.0 : 20.0;
    final double subtitleFontSize = isSmallScreen ? 14.0 : 16.0;
    final double bodyTextSize = isSmallScreen ? 13.0 : 15.0;
    final double iconSize = isSmallScreen ? 14.0 : 16.0;
    
    // Calculate padding based on screen size
    final double horizontalPadding = screenWidth * 0.05;
    final double verticalPadding = screenHeight * 0.02;
    final EdgeInsets standardPadding = EdgeInsets.all(horizontalPadding);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'About Us',
        showBackButton: true,
        showProfilePicture: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // App Logo and Name
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: context.isDarkMode
                              ? Colors.black.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: headerLogoSize,
                          width: headerLogoSize,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.primaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.bloodtype,
                              size: headerIconSize,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(height: verticalPadding),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'BloodLine',
                            style: TextStyle(
                              fontSize: headerTitleSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: verticalPadding * 0.4),
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: headerSubtitleSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: verticalPadding * 1.2),
                  
                  // Developer Information
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Developer',
                          style: TextStyle(
                            fontSize: sectionTitleSize,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        SizedBox(height: verticalPadding * 0.8),
                        
                        // Developer Card
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: context.isDarkMode 
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Developer Profile
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppConstants.primaryColor.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: avatarRadius,
                                      backgroundColor: AppConstants.primaryColor,
                                      child: Text(
                                        'HT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: avatarFontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: horizontalPadding * 0.8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Haseeb Tariq',
                                          style: TextStyle(
                                            fontSize: nameFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: context.textColor,
                                          ),
                                        ),
                                        SizedBox(height: verticalPadding * 0.2),
                                        Text(
                                          'Mobile App Developer',
                                          style: TextStyle(
                                            fontSize: subtitleFontSize,
                                            color: context.secondaryTextColor,
                                          ),
                                        ),
                                        SizedBox(height: verticalPadding * 0.4),
                                        InkWell(
                                          onTap: () async {
                                            await _launchEmail(context, 'haseebawang4545@gmail.com');
                                          },
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.email_outlined,
                                                size: iconSize,
                                                color: AppConstants.primaryColor,
                                              ),
                                              SizedBox(width: horizontalPadding * 0.4),
                                              Expanded(
                                                child: Text(
                                                  'haseebawang4545@gmail.com',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 12 : 14,
                                                    color: AppConstants.primaryColor,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: verticalPadding * 1.2),
                              const Divider(),
                              SizedBox(height: verticalPadding * 0.8),
                              
                              // Social Media Links
                              Text(
                                'Connect with me',
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                              ),
                              SizedBox(height: verticalPadding * 0.8),
                              
                              // Social Links Grid
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: isSmallScreen ? 1.1 : 1.3,
                                mainAxisSpacing: isSmallScreen ? 12 : 16,
                                crossAxisSpacing: isSmallScreen ? 12 : 16,
                                children: [
                                  _buildSocialButton(
                                    context: context,
                                    title: 'Instagram',
                                    icon: Icons.photo_camera,
                                    color: const Color(0xFFE1306C),
                                    onTap: () => _launchSocialMedia(context, 'https://instagram.com/haseeb_awan45', 'haseeb_awan45', 'instagram'),
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  _buildSocialButton(
                                    context: context,
                                    title: 'Twitter',
                                    icon: Icons.alternate_email,
                                    color: const Color(0xFF1DA1F2),
                                    onTap: () => _launchSocialMedia(context, 'https://twitter.com/haseeb_awan45', 'haseeb_awan45', 'twitter'),
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  _buildSocialButton(
                                    context: context,
                                    title: 'GitHub',
                                    icon: Icons.code,
                                    color: const Color(0xFF333333),
                                    onTap: () => _launchSocialMedia(context, 'https://github.com/HaseebTariq45', 'HaseebTariq45', 'github'),
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  _buildSocialButton(
                                    context: context,
                                    title: 'Snapchat',
                                    icon: Icons.whatshot,
                                    color: const Color(0xFFFFFC00),
                                    textColor: Colors.black,
                                    onTap: () => _launchSocialMedia(context, 'https://snapchat.com/add/haseeb_awan45', 'haseeb_awan45', 'snapchat'),
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  _buildSocialButton(
                                    context: context,
                                    title: 'Threads',
                                    icon: Icons.stream,
                                    color: const Color(0xFF000000),
                                    onTap: () => _launchSocialMedia(context, 'https://threads.net/@haseeb_awan45', 'haseeb_awan45', 'threads'),
                                    isSmallScreen: isSmallScreen,
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: verticalPadding * 1.2),
                              const Divider(),
                              SizedBox(height: verticalPadding * 0.8),
                              
                              // GitHub Project
                              InkWell(
                                onTap: () => _launchSocialMedia(context, 'https://github.com/HaseebTariq45', 'HaseebTariq45', 'github'),
                                child: Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: context.isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF333333),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.code,
                                          color: Colors.white,
                                          size: isSmallScreen ? 18 : 20,
                                        ),
                                      ),
                                      SizedBox(width: horizontalPadding * 0.8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'View Project on GitHub',
                                              style: TextStyle(
                                                fontSize: subtitleFontSize,
                                                fontWeight: FontWeight.bold,
                                                color: context.textColor,
                                              ),
                                            ),
                                            SizedBox(height: verticalPadding * 0.2),
                                            Text(
                                              '@HaseebTariq45',
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 12 : 14,
                                                color: context.secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: iconSize,
                                        color: context.isDarkMode ? Colors.grey[400] : Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: verticalPadding * 1.2),
                        
                        // App Information
                        Text(
                          'About This App',
                          style: TextStyle(
                            fontSize: sectionTitleSize,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        SizedBox(height: verticalPadding * 0.8),
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: context.isDarkMode 
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BloodLine',
                                style: TextStyle(
                                  fontSize: subtitleFontSize + 2,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                              ),
                              SizedBox(height: verticalPadding * 0.6),
                              Text(
                                'This application helps connect blood donors with patients in need of blood donations. It provides a platform for requesting blood donations, finding donors, and managing your donor profile.',
                                style: TextStyle(
                                  fontSize: bodyTextSize,
                                  color: context.secondaryTextColor,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: verticalPadding * 0.8),
                              Text(
                                'Features:',
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                              ),
                              SizedBox(height: verticalPadding * 0.4),
                              _FeatureItem(
                                text: 'Create and manage blood donation requests',
                                iconSize: iconSize,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                              _FeatureItem(
                                text: 'Connect with blood donors nearby',
                                iconSize: iconSize,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                              _FeatureItem(
                                text: 'Manage your donor profile and availability',
                                iconSize: iconSize,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                              _FeatureItem(
                                text: 'Receive notifications for blood donation requests',
                                iconSize: iconSize,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                              _FeatureItem(
                                text: 'Track your donation history',
                                iconSize: iconSize,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: verticalPadding * 2),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildSocialButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    Color? textColor,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.w500,
                color: textColor ?? color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  final double iconSize;
  final double fontSize;
  
  const _FeatureItem({
    required this.text,
    this.iconSize = 16,
    this.fontSize = 14,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: AppConstants.successColor,
            size: iconSize,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: context.secondaryTextColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 