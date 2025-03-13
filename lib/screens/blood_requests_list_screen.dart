import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/blood_type_badge.dart';
import '../models/blood_request_model.dart';
import '../utils/theme_helper.dart';

class BloodRequestsListScreen extends StatefulWidget {
  const BloodRequestsListScreen({Key? key}) : super(key: key);

  @override
  State<BloodRequestsListScreen> createState() => _BloodRequestsListScreenState();
}

class _BloodRequestsListScreenState extends State<BloodRequestsListScreen> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final List<String> _filters = ['All', 'Urgent', 'Normal'];

  @override
  void initState() {
    super.initState();
    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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

  // Show dialog to respond to a blood request
  void _showResponseDialog(BloodRequestModel request) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Respond to Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do you want to respond to ${request.requesterName}\'s blood request?'),
            const SizedBox(height: 16),
            Text(
              'Responding will share your contact information with the requester.',
              style: TextStyle(
                color: dialogContext.isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              final currentUser = appProvider.currentUser;
              
              // Update the request status in Firestore
              FirebaseFirestore.instance.collection('blood_requests').doc(request.id).update({
                'status': 'In Progress',
                'responderId': currentUser.id,
                'responderName': currentUser.name,
                'responderPhone': currentUser.phone,
                'responseDate': DateTime.now().toIso8601String(),
              }).then((_) {
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('You have responded to ${request.requesterName}\'s request'),
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
              }).catchError((error) {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to respond to request: $error'),
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
          // Header with filter options
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find blood donors near you',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(
                            right: filter != _filters.last ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected
                                    ? AppConstants.primaryColor
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Blood requests list from Firestore
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('blood_requests').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
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
                  final bloodRequests = snapshot.data!.docs.map((doc) {
                    return BloodRequestModel.fromMap(doc.data() as Map<String, dynamic>);
                  }).toList();
                  
                  // Filter blood requests based on selected filter
                  final filteredRequests = _selectedFilter == 'All'
                      ? bloodRequests
                      : bloodRequests.where((req) => req.urgency == _selectedFilter).toList();
                  
                  // Stats for the summary cards
                  final urgentCount = bloodRequests.where((req) => req.urgency == 'Urgent').length;
                  
                  // Display stats summary
                  return Column(
                    children: [
                      // Stats summary
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.bloodtype,
                                title: 'Total',
                                value: bloodRequests.length.toString(),
                                color: AppConstants.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.priority_high,
                                title: 'Urgent',
                                value: urgentCount.toString(),
                                color: AppConstants.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Blood requests list
                      Expanded(
                        child: filteredRequests.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredRequests.length,
                                itemBuilder: (context, index) {
                                  final request = filteredRequests[index];
                                  return _buildRequestCard(request);
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
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
  
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bloodtype_outlined,
              size: 80,
              color: context.isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Blood Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _selectedFilter == 'All'
                    ? 'There are no active blood requests at the moment.'
                    : 'There are no $_selectedFilter blood requests at the moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  
  Widget _buildRequestCard(BloodRequestModel request) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final isCurrentUserRequest = request.requesterId == appProvider.currentUser.id;
    final bool canRespond = !isCurrentUserRequest && request.status == 'Pending';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.white,
              request.urgency == 'Urgent' ? Colors.red.shade50 : Colors.blue.shade50,
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
                                request.urgency == 'Urgent' ? 'Urgent: ${request.requesterName}' : request.requesterName,
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
                                color: request.urgency == 'Urgent'
                                    ? AppConstants.errorColor.withOpacity(0.1)
                                    : AppConstants.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: request.urgency == 'Urgent'
                                      ? AppConstants.errorColor.withOpacity(0.5)
                                      : AppConstants.primaryColor.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                request.urgency,
                                style: TextStyle(
                                  color: request.urgency == 'Urgent'
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      builder: (context) => AlertDialog(
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
            if (request.notes.isNotEmpty) _buildDetailRow('Notes', request.notes),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Show dialog to cancel a request
  void _showCancelRequestDialog(BloodRequestModel request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this blood request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Update the request status in Firestore
              FirebaseFirestore.instance.collection('blood_requests').doc(request.id).update({
                'status': 'Cancelled',
                'cancelledDate': DateTime.now().toIso8601String(),
              }).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Request cancelled successfully'),
                    backgroundColor: AppConstants.successColor,
                  ),
                );
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel request: $error'),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );
  }
} 