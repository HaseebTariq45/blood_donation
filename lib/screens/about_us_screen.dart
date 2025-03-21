import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/theme_helper.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  // Helper function to launch URLs
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // Helper function specifically for social media with multiple fallbacks
  Future<void> _launchSocialMedia(
    BuildContext context,
    String url,
    String username,
    String platform,
  ) async {
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
                content: Text(
                  'Could not open $platform. Check if you have the app installed.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Helper function for launching email
  Future<void> _launchEmail(BuildContext context, String email) async {
    final emailLaunchUri = Uri(scheme: 'mailto', path: email);

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
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const CustomAppBar(
          title: 'About Us',
          showBackButton: true,
          showProfilePicture: false,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Get screen dimensions for responsive sizing
            final mediaQuery = MediaQuery.of(context);
            final screenWidth = mediaQuery.size.width;
            final screenHeight = mediaQuery.size.height;

            // Determine screen size categories
            final bool isSmallScreen = screenWidth < 360;
            final bool isLandscape =
                mediaQuery.orientation == Orientation.landscape;

            // Calculate responsive sizing
            final double horizontalPadding = screenWidth * 0.05;
            final double verticalPadding = screenHeight * 0.02;

            // Calculate adaptive sizes based on screen dimensions
            final double headerLogoSize = constraints.maxWidth * 0.25;
            final double headerIconSize = headerLogoSize * 0.6;
            final double headerTitleSize = constraints.maxWidth * 0.06;
            final double headerSubtitleSize = constraints.maxWidth * 0.04;

            final double sectionTitleSize = constraints.maxWidth * 0.05;
            final double avatarRadius = constraints.maxWidth * 0.1;
            final double avatarFontSize = avatarRadius * 0.6;

            final double nameFontSize = constraints.maxWidth * 0.045;
            final double subtitleFontSize = constraints.maxWidth * 0.035;
            final double bodyTextSize = constraints.maxWidth * 0.033;
            final double iconSize = constraints.maxWidth * 0.035;

            // Create adaptive layout for different orientations
            Widget headerContent = Column(
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
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Padding(
                        padding: EdgeInsets.all(headerLogoSize * 0.1),
                        child: Icon(
                          Icons.bloodtype,
                          size: headerIconSize,
                          color: AppConstants.primaryColor,
                        ),
                      ),
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: headerSubtitleSize,
                    ),
                  ),
                ),
              ],
            );

            if (isLandscape) {
              headerContent = Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: headerLogoSize * 0.8,
                    width: headerLogoSize * 0.8,
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
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Padding(
                          padding: EdgeInsets.all(headerLogoSize * 0.08),
                          child: Icon(
                            Icons.bloodtype,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: horizontalPadding),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      SizedBox(height: verticalPadding * 0.2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: headerSubtitleSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // App Logo and Name
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color:
                              context.isDarkMode
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
                    child: headerContent,
                  ),

                  SizedBox(height: verticalPadding * 1.2),

                  // Developer Information
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Developer',
                            style: TextStyle(
                              fontSize: sectionTitleSize,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                        ),
                        SizedBox(height: verticalPadding * 0.8),

                        // Developer Card
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    context.isDarkMode
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
                              LayoutBuilder(
                                builder: (context, innerConstraints) {
                                  return Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppConstants.primaryColor
                                                  .withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: avatarRadius,
                                          backgroundColor:
                                              AppConstants.primaryColor,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: EdgeInsets.all(
                                                avatarRadius * 0.3,
                                              ),
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
                                        ),
                                      ),
                                      SizedBox(width: horizontalPadding * 0.8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Haseeb Tariq',
                                                style: TextStyle(
                                                  fontSize: nameFontSize,
                                                  fontWeight: FontWeight.bold,
                                                  color: context.textColor,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: verticalPadding * 0.2,
                                            ),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Mobile App Developer',
                                                style: TextStyle(
                                                  fontSize: subtitleFontSize,
                                                  color:
                                                      context
                                                          .secondaryTextColor,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: verticalPadding * 0.4,
                                            ),
                                            InkWell(
                                              onTap: () async {
                                                await _launchEmail(
                                                  context,
                                                  'haseebawang4545@gmail.com',
                                                );
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.email_outlined,
                                                    size: iconSize,
                                                    color:
                                                        AppConstants
                                                            .primaryColor,
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        horizontalPadding * 0.4,
                                                  ),
                                                  Expanded(
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        'haseebawang4545@gmail.com',
                                                        style: TextStyle(
                                                          fontSize:
                                                              subtitleFontSize *
                                                              0.9,
                                                          color:
                                                              AppConstants
                                                                  .primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              SizedBox(height: verticalPadding * 1.2),
                              const Divider(),
                              SizedBox(height: verticalPadding * 0.8),

                              // Social Media Links
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Connect with me',
                                  style: TextStyle(
                                    fontSize: subtitleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                  ),
                                ),
                              ),
                              SizedBox(height: verticalPadding * 0.8),

                              // Social Links Grid
                              GridView.count(
                                crossAxisCount: isLandscape ? 5 : 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: isSmallScreen ? 1.1 : 1.3,
                                mainAxisSpacing: screenWidth * 0.03,
                                crossAxisSpacing: screenWidth * 0.03,
                                children: [
                                  _buildSocialButton(
                                    context: context,
                                    title: 'Instagram',
                                    icon: Icons.photo_camera,
                                    color: const Color(0xFFE1306C),
                                    onTap:
                                        () => _launchSocialMedia(
                                          context,
                                          'https://instagram.com/haseeb_awan45',
                                          'haseeb_awan45',
                                          'instagram',
                                        ),
                                    constraints: constraints,
                                  ),
                                  _buildSocialButton(
                                    context: context,
                                    title: 'Twitter',
                                    icon: Icons.alternate_email,
                                    color: const Color(0xFF1DA1F2),
                                    onTap:
                                        () => _launchSocialMedia(
                                          context,
                                          'https://twitter.com/haseeb_awan45',
                                          'haseeb_awan45',
                                          'twitter',
                                        ),
                                    constraints: constraints,
                                  ),
                                  _buildSocialButton(
                                    context: context,
                                    title: 'GitHub',
                                    icon: Icons.code,
                                    color: const Color(0xFF333333),
                                    onTap:
                                        () => _launchSocialMedia(
                                          context,
                                          'https://github.com/HaseebTariq45',
                                          'HaseebTariq45',
                                          'github',
                                        ),
                                    constraints: constraints,
                                  ),
                                  _buildSocialButton(
                                    context: context,
                                    title: 'Snapchat',
                                    icon: Icons.whatshot,
                                    color: const Color(0xFFFFFC00),
                                    textColor: Colors.black,
                                    onTap:
                                        () => _launchSocialMedia(
                                          context,
                                          'https://snapchat.com/add/haseeb_awan45',
                                          'haseeb_awan45',
                                          'snapchat',
                                        ),
                                    constraints: constraints,
                                  ),
                                  _buildSocialButton(
                                    context: context,
                                    title: 'Threads',
                                    icon: Icons.stream,
                                    color: const Color(0xFF000000),
                                    onTap:
                                        () => _launchSocialMedia(
                                          context,
                                          'https://threads.net/@haseeb_awan45',
                                          'haseeb_awan45',
                                          'threads',
                                        ),
                                    constraints: constraints,
                                  ),
                                ],
                              ),

                              SizedBox(height: verticalPadding * 1.2),
                              const Divider(),
                              SizedBox(height: verticalPadding * 0.8),

                              // GitHub Project
                              InkWell(
                                onTap:
                                    () => _launchSocialMedia(
                                      context,
                                      'https://github.com/HaseebTariq45',
                                      'HaseebTariq45',
                                      'github',
                                    ),
                                child: Container(
                                  padding: EdgeInsets.all(screenWidth * 0.04),
                                  decoration: BoxDecoration(
                                    color:
                                        context.isDarkMode
                                            ? const Color(0xFF1E1E1E)
                                            : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          context.isDarkMode
                                              ? const Color(0xFF2C2C2C)
                                              : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          screenWidth * 0.025,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF333333),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.code,
                                          color: Colors.white,
                                          size: iconSize * 1.2,
                                        ),
                                      ),
                                      SizedBox(width: horizontalPadding * 0.8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'View Project on GitHub',
                                                style: TextStyle(
                                                  fontSize: subtitleFontSize,
                                                  fontWeight: FontWeight.bold,
                                                  color: context.textColor,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: verticalPadding * 0.2,
                                            ),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                '@HaseebTariq45',
                                                style: TextStyle(
                                                  fontSize:
                                                      subtitleFontSize * 0.8,
                                                  color:
                                                      context
                                                          .secondaryTextColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: iconSize,
                                        color:
                                            context.isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey,
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'About This App',
                            style: TextStyle(
                              fontSize: sectionTitleSize,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                        ),
                        SizedBox(height: verticalPadding * 0.8),
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    context.isDarkMode
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
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'BloodLine',
                                  style: TextStyle(
                                    fontSize: subtitleFontSize + 2,
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                  ),
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
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Features:',
                                  style: TextStyle(
                                    fontSize: subtitleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                  ),
                                ),
                              ),
                              SizedBox(height: verticalPadding * 0.4),
                              _FeatureItem(
                                text:
                                    'Create and manage blood donation requests',
                                iconSize: iconSize,
                                fontSize: bodyTextSize,
                              ),
                              _FeatureItem(
                                text: 'Connect with blood donors nearby',
                                iconSize: iconSize,
                                fontSize: bodyTextSize,
                              ),
                              _FeatureItem(
                                text:
                                    'Manage your donor profile and availability',
                                iconSize: iconSize,
                                fontSize: bodyTextSize,
                              ),
                              _FeatureItem(
                                text:
                                    'Receive notifications for blood donation requests',
                                iconSize: iconSize,
                                fontSize: bodyTextSize,
                              ),
                              _FeatureItem(
                                text: 'Track your donation history',
                                iconSize: iconSize,
                                fontSize: bodyTextSize,
                              ),
                              _FeatureItem(
                                text: 'Find nearby blood banks',
                                iconSize: iconSize,
                                fontSize: bodyTextSize,
                              ),
                              _FeatureItem(
                                text: 'Access emergency contacts',
                                iconSize: iconSize,
                                fontSize: bodyTextSize,
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
    required BoxConstraints constraints,
  }) {
    final double iconSize = constraints.maxWidth * 0.05;
    final double fontSize = constraints.maxWidth * 0.03;
    final bool isSmallScreen = constraints.maxWidth < 360;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(constraints.maxWidth * 0.02),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: iconSize),
            SizedBox(height: constraints.maxHeight * 0.01),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? color,
                ),
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.01,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: AppConstants.successColor,
            size: iconSize,
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
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
