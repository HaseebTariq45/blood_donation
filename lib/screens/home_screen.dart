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
              Icon(Icons.favorite, size: iconSize),
              SizedBox(width: horizontalPadding * 0.4),
              Text(
                'BloodLine',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
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
                if (appProvider
                    .hasUnreadNotifications) // Add notification indicator
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
                              child: Text(
                                'Hello, ${currentUser.name.split(' ')[0]}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: headerFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            BloodTypeBadge(bloodType: currentUser.bloodType),
                          ],
                        ),
                        SizedBox(height: verticalPadding * 0.4),
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
                                  Navigator.pushNamed(
                                    context,
                                    '/health_tips',
                                  );
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
}
