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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'About Us',
        showBackButton: true,
        showProfilePicture: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // App Logo and Name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                    height: 100,
                    width: 100,
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
                        size: 60,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Blood Donation App',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Developer Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Developer Card
                  Container(
                    padding: const EdgeInsets.all(20),
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
                                radius: 40,
                                backgroundColor: AppConstants.primaryColor,
                                child: const Text(
                                  'HT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Haseeb Tariq',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: context.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mobile App Developer',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: context.secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () async {
                                      await _launchEmail(context, 'haseebawang4545@gmail.com');
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 16,
                                          color: AppConstants.primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'haseebawang4545@gmail.com',
                                            style: TextStyle(
                                              fontSize: 14,
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
                        
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Social Media Links
                        Text(
                          'Connect with me',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Social Links Grid
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _buildSocialButton(
                              context: context,
                              title: 'Instagram',
                              icon: Icons.photo_camera,
                              color: const Color(0xFFE1306C),
                              onTap: () => _launchSocialMedia(context, 'https://instagram.com/haseeb_awan45', 'haseeb_awan45', 'instagram'),
                            ),
                            _buildSocialButton(
                              context: context,
                              title: 'Twitter',
                              icon: Icons.alternate_email,
                              color: const Color(0xFF1DA1F2),
                              onTap: () => _launchSocialMedia(context, 'https://twitter.com/haseeb_awan45', 'haseeb_awan45', 'twitter'),
                            ),
                            _buildSocialButton(
                              context: context,
                              title: 'GitHub',
                              icon: Icons.code,
                              color: const Color(0xFF333333),
                              onTap: () => _launchSocialMedia(context, 'https://github.com/HaseebTariq45', 'HaseebTariq45', 'github'),
                            ),
                            _buildSocialButton(
                              context: context,
                              title: 'Snapchat',
                              icon: Icons.whatshot,
                              color: const Color(0xFFFFFC00),
                              textColor: Colors.black,
                              onTap: () => _launchSocialMedia(context, 'https://snapchat.com/add/haseeb_awan45', 'haseeb_awan45', 'snapchat'),
                            ),
                            _buildSocialButton(
                              context: context,
                              title: 'Threads',
                              icon: Icons.stream,
                              color: const Color(0xFF000000),
                              onTap: () => _launchSocialMedia(context, 'https://threads.net/@haseeb_awan45', 'haseeb_awan45', 'threads'),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // GitHub Project
                        InkWell(
                          onTap: () => _launchSocialMedia(context, 'https://github.com/HaseebTariq45', 'HaseebTariq45', 'github'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
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
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF333333),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.code,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'View Project on GitHub',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: context.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '@HaseebTariq45',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: context.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: context.isDarkMode ? Colors.grey[400] : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // App Information
                  Text(
                    'About This App',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
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
                          'Blood Donation App',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This application helps connect blood donors with patients in need of blood donations. It provides a platform for requesting blood donations, finding donors, and managing your donor profile.',
                          style: TextStyle(
                            fontSize: 15,
                            color: context.secondaryTextColor,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Features:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _FeatureItem(text: 'Create and manage blood donation requests'),
                        _FeatureItem(text: 'Connect with blood donors nearby'),
                        _FeatureItem(text: 'Manage your donor profile and availability'),
                        _FeatureItem(text: 'Receive notifications for blood donation requests'),
                        _FeatureItem(text: 'Track your donation history'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
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
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
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
  
  const _FeatureItem({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppConstants.successColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
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