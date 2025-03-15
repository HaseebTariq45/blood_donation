import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/home_menu_card.dart';
import '../widgets/blood_type_badge.dart';
import '../utils/theme_helper.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUser = appProvider.currentUser;

    // Debug logging for user data
    debugPrint('Home Screen - Current User: ${currentUser.toString()}');

    // Check if this is a dummy user
    final bool isDummyUser = currentUser.id == 'user123';
    if (isDummyUser) {
      debugPrint(
        'WARNING: Home screen showing DUMMY USER - not logged in properly!',
      );
    }

    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;

    // Calculate responsive sizes
    final double titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final double headerFontSize = isSmallScreen ? 20.0 : 24.0;
    final double sectionTitleFontSize = isSmallScreen ? 18.0 : 20.0;
    final double bodyTextFontSize = isSmallScreen ? 12.0 : 14.0;
    final double iconSize = isSmallScreen ? 20.0 : 24.0;
    final double smallIconSize = isSmallScreen ? 12.0 : 14.0;
    final double badgeSize = isSmallScreen ? 40.0 : 45.0;

    // Calculate padding based on screen size
    final double horizontalPadding = screenWidth * 0.05;
    final double verticalPadding = screenHeight * 0.02;
    final EdgeInsets standardPadding = EdgeInsets.all(horizontalPadding);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.appBarColor,
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                color: AppConstants.primaryColor,
                size: iconSize,
              ),
              SizedBox(width: horizontalPadding * 0.4),
              Text(
                'BloodLine',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  foreground:
                      Paint()
                        ..shader = LinearGradient(
                          colors: [
                            AppConstants.primaryColor,
                            AppConstants.primaryColor.withOpacity(0.8),
                          ],
                        ).createShader(
                          const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                        ),
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          // Notifications Icon
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications, size: isSmallScreen ? 22 : 24),
                if (appProvider.hasUnreadNotifications)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 10 : 12,
                        minHeight: isSmallScreen ? 10 : 12,
                      ),
                      child: const Text(
                        '',
                        style: TextStyle(color: Colors.white, fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          // Profile Picture
          Padding(
            padding: EdgeInsets.only(right: horizontalPadding),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: Hero(
                tag: 'profile',
                child: CircleAvatar(
                  radius: isSmallScreen ? 14 : 16,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      currentUser.imageUrl.isNotEmpty &&
                              !appProvider.profileImageLoadError
                          ? NetworkImage(currentUser.imageUrl, scale: 1.0)
                          : null,
                  onBackgroundImageError:
                      currentUser.imageUrl.isNotEmpty &&
                              !appProvider.profileImageLoadError
                          ? (exception, stackTrace) {
                            debugPrint(
                              'Failed to load profile image: $exception',
                            );
                            appProvider.setProfileImageLoadError(true);
                          }
                          : null,
                  child:
                      currentUser.imageUrl.isEmpty ||
                              appProvider.profileImageLoadError
                          ? Icon(
                            Icons.person,
                            color: AppConstants.primaryColor,
                            size: isSmallScreen ? 14 : 16,
                          )
                          : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: standardPadding,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppConstants.primaryColor,
                          AppConstants.primaryColor.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello,',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: bodyTextFontSize + 2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${currentUser.name.split(' ')[0]}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: headerFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            BloodTypeBadge(
                              bloodType: currentUser.bloodType,
                              size: badgeSize * 1.15,
                              onTap:
                                  () => _showBloodTypeInfo(
                                    context,
                                    currentUser.bloodType,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalPadding * 0.6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white70,
                              size: smallIconSize,
                            ),
                            SizedBox(width: horizontalPadding * 0.4),
                            Expanded(
                              child: Text(
                                currentUser.daysUntilNextDonation > 0
                                    ? 'Next donation in ${currentUser.daysUntilNextDonation} days'
                                    : 'You are eligible to donate today!',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: bodyTextFontSize,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalPadding * 0.8),
                        // Eligibility Status
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: verticalPadding * 0.4,
                            horizontal: horizontalPadding * 0.8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                currentUser.isEligibleToDonate
                                    ? AppConstants.successColor
                                    : Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                currentUser.isEligibleToDonate
                                    ? Icons.check_circle
                                    : Icons.access_time,
                                color: Colors.white,
                                size: smallIconSize,
                              ),
                              SizedBox(width: horizontalPadding * 0.4),
                              Text(
                                currentUser.isEligibleToDonate
                                    ? 'Eligible to Donate'
                                    : 'Not Eligible Yet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: bodyTextFontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Main Menu Grid
                  Padding(
                    padding: standardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Services',
                              style: TextStyle(
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Optional: Add a subtle info icon to guide users
                            IconButton(
                              icon: Icon(
                                Icons.info_outline,
                                color: Colors.grey[400],
                                size: isSmallScreen ? 16 : 18,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Tap on any card to access the service',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: verticalPadding * 0.8),
                        // First row of cards (2 cards)
                        Row(
                          children: [
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Find Blood Donors',
                                icon: Icons.person_search,
                                onTap: () {
                                  Navigator.pushNamed(context, '/donor_search');
                                },
                                index: 0,
                              ),
                            ),
                            SizedBox(width: horizontalPadding),
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Request Blood',
                                icon: Icons.bloodtype,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/blood_request',
                                  );
                                },
                                index: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalPadding),

                        // Second row of cards (2 cards)
                        Row(
                          children: [
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Blood Requests',
                                icon: Icons.format_list_bulleted,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/blood_requests_list',
                                  );
                                },
                                index: 2,
                              ),
                            ),
                            SizedBox(width: horizontalPadding),
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Nearby Blood Banks',
                                icon: Icons.location_on,
                                onTap: () {
                                  Navigator.pushNamed(context, '/blood_banks');
                                },
                                index: 3,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalPadding),

                        // Third row (2 cards)
                        Row(
                          children: [
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Donation History',
                                icon: Icons.history,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/donation_history',
                                  );
                                },
                                index: 4,
                              ),
                            ),
                            SizedBox(width: horizontalPadding),
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Health Tips',
                                icon: Icons.health_and_safety,
                                onTap: () {
                                  Navigator.pushNamed(context, '/health_tips');
                                },
                                index: 5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalPadding),

                        // Fourth row (1 card)
                        Row(
                          children: [
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Emergency Contacts',
                                icon: Icons.emergency,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/emergency_contacts',
                                  );
                                },
                                index: 6,
                              ),
                            ),
                          ],
                        ),
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

  String _getTimeAgo(DateTime requestDate) {
    final now = DateTime.now();
    final difference = now.difference(requestDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Blood type compatibility helper methods
  Widget _buildBloodTypeInfoRow(String label, List<String> types) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: types.map((type) => _buildBloodTypeChip(type)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodTypeChip(String bloodType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.5)),
      ),
      child: Text(
        bloodType,
        style: TextStyle(
          color: AppConstants.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<String> _getCompatibleRecipients(String bloodType) {
    // Who can receive from this blood type
    switch (bloodType) {
      case 'O-':
        return ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'];
      case 'O+':
        return ['O+', 'A+', 'B+', 'AB+'];
      case 'A-':
        return ['A-', 'A+', 'AB-', 'AB+'];
      case 'A+':
        return ['A+', 'AB+'];
      case 'B-':
        return ['B-', 'B+', 'AB-', 'AB+'];
      case 'B+':
        return ['B+', 'AB+'];
      case 'AB-':
        return ['AB-', 'AB+'];
      case 'AB+':
        return ['AB+'];
      default:
        return [];
    }
  }

  List<String> _getCompatibleDonors(String bloodType) {
    // Who can donate to this blood type
    switch (bloodType) {
      case 'O-':
        return ['O-'];
      case 'O+':
        return ['O-', 'O+'];
      case 'A-':
        return ['O-', 'A-'];
      case 'A+':
        return ['O-', 'O+', 'A-', 'A+'];
      case 'B-':
        return ['O-', 'B-'];
      case 'B+':
        return ['O-', 'O+', 'B-', 'B+'];
      case 'AB-':
        return ['O-', 'A-', 'B-', 'AB-'];
      case 'AB+':
        return ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'];
      default:
        return [];
    }
  }

  String _getBloodTypeDescription(String bloodType) {
    switch (bloodType) {
      case 'O-':
        return 'You are a universal donor! Your blood can be given to anyone, making you extremely valuable in emergency situations. However, you can only receive O- blood.';
      case 'O+':
        return 'As the most common blood type, your donations are always in high demand. You can donate to all positive blood types but can only receive O+ and O- blood.';
      case 'A-':
        return 'Your blood is relatively rare and can be donated to both A and AB blood types. You can receive from A- and O- donors only.';
      case 'A+':
        return 'With the second most common blood type, your donations are always needed. You can donate to A+ and AB+ recipients and can receive from A+, A-, O+, and O- donors.';
      case 'B-':
        return 'Your blood type is uncommon and can be donated to both B and AB blood types. You can receive from B- and O- donors only.';
      case 'B+':
        return 'Your blood type is less common and can be donated to B+ and AB+ recipients. You can receive from B+, B-, O+, and O- donors.';
      case 'AB-':
        return 'You have a rare blood type and can donate to AB- and AB+ recipients. You are a universal recipient for negative blood types.';
      case 'AB+':
        return 'As a universal recipient, you can receive blood from anyone! However, you can only donate to other AB+ individuals.';
      default:
        return 'Information not available for this blood type.';
    }
  }

  void _showBloodTypeInfo(BuildContext context, String bloodType) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Theme.of(context).cardColor,
            title: Row(
              children: [
                Icon(Icons.bloodtype, color: AppConstants.primaryColor),
                SizedBox(width: 10),
                Text('Blood Type Information'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bloodType,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                SizedBox(height: 20),
                _buildBloodTypeInfoRow(
                  'Can donate to:',
                  _getCompatibleRecipients(bloodType),
                ),
                SizedBox(height: 10),
                _buildBloodTypeInfoRow(
                  'Can receive from:',
                  _getCompatibleDonors(bloodType),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getBloodTypeDescription(bloodType),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }
}
