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
                        'responderPhone': currentUser.phone,
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
                              'responderPhone': currentUser.phone,
                              'bloodType': currentUser.bloodType,
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
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Custom TabBar
          Container(
            decoration: BoxDecoration(
              color: context.appBarColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(50),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: AppConstants.primaryColor,
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: List.generate(_tabs.length, (index) {
                  return Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: 40,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_tabIcons[index], size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _tabs[index],
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // TabBarView
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
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: context.textColor),
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            final request = filteredRequests[index];
            return _buildRequestCard(request);
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
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
                    ),
                    child: Center(
                      child: Text(
                        request.bloodType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
                          children: [
                            Expanded(
                              child: Text(
                                request.urgency == 'Urgent'
                                    ? 'Urgent: ${request.requesterName}'
                                    : request.requesterName,
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
                                color:
                                    request.urgency == 'Urgent'
                                        ? AppConstants.errorColor.withOpacity(
                                          0.1,
                                        )
                                        : AppConstants.primaryColor.withOpacity(
                                          0.1,
                                        ),
                                borderRadius: BorderRadius.circular(16),
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
                              child: Text(
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.location,
                          style: const TextStyle(
                            color: AppConstants.lightTextColor,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppConstants.lightTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              request.formattedDate,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppConstants.lightTextColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppConstants.lightTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              request.contactNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppConstants.lightTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (request.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  request.notes,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.darkTextColor,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Status indicator
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withOpacity(0.1),
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
                      size: 14,
                      color: _getStatusColor(request.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      request.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(request.status),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // Option to call the requester
                      _launchCall(request.contactNumber);
                    },
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.primaryColor,
                      side: BorderSide(color: AppConstants.primaryColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (canRespond)
                    ElevatedButton(
                      onPressed: () {
                        // Handle donation response
                        _showResponseDialog(request);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Respond'),
                    )
                  else if (isCurrentUserRequest)
                    ElevatedButton(
                      onPressed: () {
                        // Show request details or allow editing
                        _showRequestDetailsDialog(request);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Details'),
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
                      ),
                      child: Text(request.status),
                    ),
                ],
              ),
            ],
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

  // Show request details dialog
  void _showRequestDetailsDialog(BloodRequestModel request) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Request Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Requester', request.requesterName),
                _buildDetailRow('Blood Type', request.bloodType),
                _buildDetailRow('Location', request.location),
                _buildDetailRow('Date', request.formattedDate),
                _buildDetailRow('Status', request.status),
                _buildDetailRow('Urgency', request.urgency),
                if (request.notes.isNotEmpty)
                  _buildDetailRow('Notes', request.notes),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
              if (request.status == 'Pending')
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCancelRequestDialog(request);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('CANCEL REQUEST'),
                ),
            ],
          ),
    );
  }

  // Build detail row for request details dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Show dialog to cancel a request
  void _showCancelRequestDialog(BloodRequestModel request) {
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
