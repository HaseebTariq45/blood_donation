import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/blood_request_model.dart';
import '../providers/app_provider.dart';
import '../models/notification_model.dart';
import '../widgets/blood_type_badge.dart';
import '../utils/theme_helper.dart';

class BloodRequestsListScreen extends StatefulWidget {
  const BloodRequestsListScreen({super.key});

  @override
  State<BloodRequestsListScreen> createState() =>
      _BloodRequestsListScreenState();
}

class _BloodRequestsListScreenState extends State<BloodRequestsListScreen>
    with TickerProviderStateMixin {
  final String _selectedFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  final List<String> _tabs = ['All', 'Urgent', 'Normal', 'My Requests'];
  final List<IconData> _tabIcons = [
    Icons.format_list_bulleted,
    Icons.priority_high,
    Icons.schedule,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();
    // Initialize tab controller
    _tabController = TabController(length: 4, vsync: this);

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Handle initial tab selection from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      print("Route arguments: $args");
      if (args != null && args.containsKey('initialTab')) {
        final tabIndex = args['initialTab'] as int;
        print("Selecting tab index: $tabIndex");
        if (tabIndex >= 0 && tabIndex < _tabController.length) {
          _tabController.animateTo(tabIndex);
        } else {
          print(
            "Tab index out of range: $tabIndex (controller length: ${_tabController.length})",
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Show dialog to respond to a blood request
  void _showResponseDialog(BloodRequestModel request) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Respond to Request'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Do you want to respond to ${request.requesterName}\'s blood request?',
                ),
                const SizedBox(height: 16),
                Text(
                  'Responding will share your contact information with the requester.',
                  style: TextStyle(
                    color:
                        dialogContext.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  // Get current user info from provider
                  final appProvider = Provider.of<AppProvider>(
                    context,
                    listen: false,
                  );
                  final currentUser = appProvider.currentUser;

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) =>
                            const Center(child: CircularProgressIndicator()),
                  );

                  // Update the request status in Firestore
                  FirebaseFirestore.instance
                      .collection('blood_requests')
                      .doc(request.id)
                      .update({
                        'status': 'In Progress',
                        'responderId': currentUser.id,
                        'responderName': currentUser.name,
                        'responderPhone': currentUser.phoneNumber,
                        'responseDate': DateTime.now().toIso8601String(),
                      })
                      .then((_) async {
                        // Send notification to requester
                        final appProvider = Provider.of<AppProvider>(
                          context,
                          listen: false,
                        );

                        try {
                          // Create notification model
                          final notification = NotificationModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            userId: request.requesterId,
                            title: 'Response to Your Blood Request',
                            body: '${currentUser.name} has responded to your blood request',
                            type: 'blood_request_response',
                            read: false,
                            createdAt: DateTime.now().toIso8601String(),
                            metadata: {
                              'requestId': request.id,
                              'responderName': currentUser.name,
                              'responderPhone': currentUser.phoneNumber,
                              'bloodType': currentUser.bloodType,
                              'responderId': currentUser.id,
                            },
                          );

                          // Add notification using app provider
                          await appProvider.sendNotification(notification);

                          debugPrint('Blood request response notification sent successfully');
                        } catch (e) {
                          debugPrint('Error sending notification: $e');
                        }

                        // Close loading indicator
                        if (mounted) {
                          Navigator.pop(context);
                        }

                        // Show success message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'You have responded to ${request.requesterName}\'s request',
                              ),
                              backgroundColor: AppConstants.successColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.all(10),
                              action: SnackBarAction(
                                label: 'DISMISS',
                                textColor: Colors.white,
                                onPressed: () {},
                              ),
                            ),
                          );
                        }
                      })
                      .catchError((error) {
                        // Close loading indicator
                        if (mounted) {
                          Navigator.pop(context);
                        }

                        // Show error message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to respond to request: $error',
                              ),
                              backgroundColor: AppConstants.errorColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.all(10),
                              action: SnackBarAction(
                                label: 'DISMISS',
                                textColor: Colors.white,
                                onPressed: () {},
                              ),
                            ),
                          );
                        }
                      });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                ),
                child: const Text('RESPOND'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.appBarColor,
        elevation: 0,
        title: const Text(
          'Blood Requests',
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              // Refresh the page
              setState(() {});
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Redesigned TabBar with better text visibility
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.appBarColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: AppConstants.primaryColor,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    tabs: [
                      _buildTab(Icons.format_list_bulleted, 'All'),
                      _buildTab(Icons.priority_high, 'Urgent'),
                      _buildTab(Icons.schedule, 'Normal'),
                      _buildTab(Icons.person, 'My'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // TabBarView with improved animations
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList('All'),
                _buildRequestsList('Urgent'),
                _buildRequestsList('Normal'),
                _buildRequestsList('My'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/blood_request');
        },
        backgroundColor: AppConstants.primaryColor,
        elevation: 4,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'New Request',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  // Helper method to build consistent tab items with better visibility
  Widget _buildTab(IconData icon, String label) {
    return Tab(
      height: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(String filter) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .orderBy('requestDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: AppConstants.errorColor.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // Convert Firestore documents to BloodRequestModel objects
        final bloodRequests =
            snapshot.data!.docs.map((doc) {
              return BloodRequestModel.fromMap(
                doc.data() as Map<String, dynamic>,
              );
            }).toList();

        // Filter requests based on tab
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final filteredRequests =
            bloodRequests.where((request) {
              if (filter == 'My') {
                return request.requesterId == appProvider.currentUser.id;
              } else if (filter == 'Urgent') {
                return request.urgency == 'Urgent';
              } else if (filter == 'Normal') {
                return request.urgency == 'Normal';
              }
              return true; // 'All' tab
            }).toList();

        if (filteredRequests.isEmpty) {
          return _buildEmptyState();
        }

        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredRequests.length,
                itemBuilder: (context, index) {
                  final request = filteredRequests[index];
                  // Apply staggered animation effect
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: 1.0,
                    curve: Curves.easeInOut,
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 500),
                      padding: EdgeInsets.only(
                        top: index == 0 ? 0 : 8,
                        bottom: 8,
                      ),
                      child: _buildRequestCard(request),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder:
          (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bloodtype_outlined,
                  size: 80,
                  color:
                      context.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Blood Requests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        context.isDarkMode
                            ? Colors.grey[300]
                            : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _getEmptyStateMessage(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          context.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/blood_request');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create a Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String _getEmptyStateMessage() {
    if (_tabController.index == 3) {
      // My Requests tab
      return 'You have not created any blood requests yet.';
    } else if (_tabController.index == 1) {
      // Urgent tab
      return 'There are no Urgent blood requests at the moment.';
    } else if (_tabController.index == 2) {
      // Normal tab
      return 'There are no Normal blood requests at the moment.';
    } else {
      return 'There are no active blood requests at the moment.';
    }
  }

  Widget _buildRequestCard(BloodRequestModel request) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final isCurrentUserRequest =
        request.requesterId == appProvider.currentUser.id;
    final bool canRespond =
        !isCurrentUserRequest && request.status == 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: request.urgency == 'Urgent'
              ? AppConstants.errorColor.withOpacity(0.2)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.white,
              request.urgency == 'Urgent'
                  ? Colors.red.shade50
                  : Colors.blue.shade50,
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showRequestDetailsDialog(request),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enhanced blood type indicator
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              request.bloodType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      request.urgency == 'Urgent'
                                          ? 'Urgent: ${request.requesterName}'
                                          : request.requesterName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          request.urgency == 'Urgent'
                                              ? AppConstants.errorColor.withOpacity(
                                                0.15,
                                              )
                                              : AppConstants.primaryColor.withOpacity(
                                                0.15,
                                              ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            request.urgency == 'Urgent'
                                                ? AppConstants.errorColor.withOpacity(
                                                  0.5,
                                                )
                                                : AppConstants.primaryColor
                                                    .withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          request.urgency == 'Urgent'
                                              ? Icons.warning_amber_rounded
                                              : Icons.info_outline,
                                          size: 14,
                                          color: request.urgency == 'Urgent'
                                              ? AppConstants.errorColor
                                              : AppConstants.primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          request.urgency,
                                          style: TextStyle(
                                            color:
                                                request.urgency == 'Urgent'
                                                    ? AppConstants.errorColor
                                                    : AppConstants.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: AppConstants.lightTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      request.location,
                                      style: TextStyle(
                                        color: AppConstants.lightTextColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: AppConstants.lightTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    request.formattedDate,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppConstants.lightTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: AppConstants.lightTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    request.contactNumber,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppConstants.lightTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Notes section with improved styling
                    if (request.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes,
                            size: 18,
                            color: AppConstants.darkTextColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              request.notes,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppConstants.darkTextColor,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Status indicator with enhanced design
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(request.status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(request.status).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(request.status),
                                size: 16,
                                color: _getStatusColor(request.status),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                request.status,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(request.status),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Improved action buttons
                        TextButton.icon(
                          onPressed: () {
                            // Option to call the requester
                            _launchCall(request.contactNumber);
                          },
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('Call'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppConstants.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (canRespond)
                          ElevatedButton.icon(
                            onPressed: () {
                              // Handle donation response
                              _showResponseDialog(request);
                            },
                            icon: const Icon(Icons.volunteer_activism, size: 16),
                            label: const Text('Respond'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                        else if (isCurrentUserRequest)
                          ElevatedButton.icon(
                            onPressed: () {
                              // Show request details or allow editing
                              _showRequestDetailsDialog(request);
                            },
                            icon: const Icon(Icons.info_outline, size: 16),
                            label: const Text('Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: null, // Disabled button
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(request.status),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Get color based on request status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Fulfilled':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get icon based on request status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_empty;
      case 'In Progress':
        return Icons.pending_actions;
      case 'Fulfilled':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  // Launch phone call
  void _launchCall(String phoneNumber) {
    // Implement phone call functionality
    // This would typically use url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber'),
        backgroundColor: AppConstants.primaryColor,
      ),
    );
  }

  // Show request details dialog with enhanced UI
  void _showRequestDetailsDialog(BloodRequestModel request) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.bloodtype_outlined,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text('Request Details'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          request.bloodType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildDetailRow('Requester', request.requesterName),
                  _buildDetailRow('Blood Type', request.bloodType),
                  _buildDetailRow('Location', request.location),
                  _buildDetailRow('Date', request.formattedDate),
                  _buildDetailRow('Status', request.status, 
                    statusColor: _getStatusColor(request.status),
                    icon: _getStatusIcon(request.status),
                  ),
                  _buildDetailRow('Urgency', request.urgency,
                    statusColor: request.urgency == 'Urgent' 
                        ? AppConstants.errorColor 
                        : AppConstants.primaryColor,
                    icon: request.urgency == 'Urgent'
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline,
                  ),
                  if (request.notes.isNotEmpty)
                    _buildDetailRow('Notes', request.notes),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
              if (request.status == 'Pending' && 
                  request.requesterId == appProvider.currentUser.id)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCancelRequestDialog(request);
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  label: const Text('CANCEL REQUEST'),
                ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            backgroundColor: context.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          ),
    );
  }

  // Build detail row for request details dialog with enhanced styling
  Widget _buildDetailRow(String label, String value, {Color? statusColor, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          if (statusColor != null && icon != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: statusColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  // Show dialog to cancel a request with enhanced UI
  void _showCancelRequestDialog(BloodRequestModel request) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Request'),
            content: const Text(
              'Are you sure you want to cancel this blood request?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('NO'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);

                  // Update the request status in Firestore
                  FirebaseFirestore.instance
                      .collection('blood_requests')
                      .doc(request.id)
                      .update({
                        'status': 'Cancelled',
                        'cancelledDate': DateTime.now().toIso8601String(),
                      })
                      .then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Request cancelled successfully',
                            ),
                            backgroundColor: AppConstants.successColor,
                          ),
                        );
                      })
                      .catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to cancel request: $error'),
                            backgroundColor: AppConstants.errorColor,
                          ),
                        );
                      });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('YES, CANCEL'),
              ),
            ],
          ),
    );
  }
}
