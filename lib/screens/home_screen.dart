import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/home_menu_card.dart';
import '../widgets/blood_type_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUser = appProvider.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).appBarTheme.backgroundColor 
            : AppConstants.primaryColor,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 24),
            SizedBox(width: 8),
            Text(
              'BLOOD DONATION',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Notifications Icon
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (appProvider.hasUnreadNotifications) // Add notification indicator
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: const Text(
                        '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
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
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: Hero(
                tag: 'profile',
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  backgroundImage: currentUser.imageUrl.isNotEmpty && !appProvider.profileImageLoadError
                      ? NetworkImage(
                          currentUser.imageUrl,
                          scale: 1.0,
                        )
                      : null,
                  onBackgroundImageError: currentUser.imageUrl.isNotEmpty && !appProvider.profileImageLoadError
                      ? (exception, stackTrace) {
                          debugPrint('Failed to load profile image: $exception');
                          appProvider.setProfileImageLoadError(true);
                        }
                      : null,
                  child: currentUser.imageUrl.isEmpty || appProvider.profileImageLoadError
                      ? const Icon(
                          Icons.person,
                          color: AppConstants.primaryColor,
                          size: 16,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingL),
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
                      Text(
                        'Hello, ${currentUser.name.split(' ')[0]}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      BloodTypeBadge(bloodType: currentUser.bloodType),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentUser.daysUntilNextDonation > 0
                            ? 'Next donation in ${currentUser.daysUntilNextDonation} days'
                            : 'You are eligible to donate today!',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Eligibility Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: currentUser.isEligibleToDonate
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
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentUser.isEligibleToDonate
                              ? 'Eligible to Donate'
                              : 'Not Eligible Yet',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
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
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Services',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Optional: Add a subtle info icon to guide users
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tap on any card to access the service'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.1,
                    children: [
                      HomeMenuCard(
                        title: 'Find Blood Donors',
                        icon: Icons.person_search,
                        onTap: () {
                          Navigator.pushNamed(context, '/donor_search');
                        },
                        index: 0,
                      ),
                      HomeMenuCard(
                        title: 'Request Blood',
                        icon: Icons.bloodtype,
                        onTap: () {
                          Navigator.pushNamed(context, '/blood_request');
                        },
                        index: 1,
                      ),
                      HomeMenuCard(
                        title: 'Nearby Blood Banks',
                        icon: Icons.location_on,
                        onTap: () {
                          Navigator.pushNamed(context, '/blood_banks');
                        },
                        index: 2,
                      ),
                      HomeMenuCard(
                        title: 'Donation History',
                        icon: Icons.history,
                        onTap: () {
                          Navigator.pushNamed(context, '/donation_history');
                        },
                        index: 3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Recent Requests
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingL,
                0,
                AppConstants.paddingL,
                AppConstants.paddingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Urgent Blood Requests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // View all requests
                          Navigator.pushNamed(context, '/blood_requests_list');
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Recent blood requests list
                  if (appProvider.bloodRequests.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: appProvider.bloodRequests
                          .where((req) => req.isUrgent && req.status == 'Pending')
                          .take(3)
                          .length,
                      itemBuilder: (context, index) {
                        final urgentRequests = appProvider.bloodRequests
                            .where((req) => req.isUrgent && req.status == 'Pending')
                            .toList();
                        if (index < urgentRequests.length) {
                          final request = urgentRequests[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusM),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/blood_requests_list');
                              },
                              borderRadius: BorderRadius.circular(AppConstants.radiusM),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                  gradient: LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [
                                      Colors.white,
                                      Colors.red.shade50,
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.red.withOpacity(0.3),
                                                  blurRadius: 10,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            child: BloodTypeBadge(
                                              bloodType: request.bloodType,
                                              size: 50,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Urgent: ${request.requesterName}',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppConstants.errorColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(16),
                                                        border: Border.all(
                                                          color: AppConstants.errorColor.withOpacity(0.5),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        request.bloodType,
                                                        style: const TextStyle(
                                                          color: AppConstants.errorColor,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  request.location.split(',').first,
                                                  style: const TextStyle(
                                                    color: AppConstants.lightTextColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.location_on,
                                                      size: 14,
                                                      color: AppConstants.lightTextColor,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        request.location.contains(',') 
                                                            ? request.location.split(',').skip(1).join(',').trim() 
                                                            : request.location,
                                                        style: const TextStyle(
                                                          color: AppConstants.lightTextColor,
                                                          fontSize: 12,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(height: 1),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              request.notes,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          ElevatedButton(
                                            onPressed: () {
                                              // Handle donation response
                                              Navigator.pushNamed(context, '/blood_requests_list');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppConstants.primaryColor,
                                              foregroundColor: Colors.white,
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                              ),
                                            ),
                                            child: const Text('Respond'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingL),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bloodtype_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No urgent blood requests at the moment',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 