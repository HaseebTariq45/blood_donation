import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
              // Add logic to handle the response
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You have responded to ${request.requesterName}\'s request'),
                  backgroundColor: AppConstants.successColor,
                ),
              );
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
    final appProvider = Provider.of<AppProvider>(context);
    final allBloodRequests = appProvider.bloodRequests;
    
    // Filter blood requests based on selected filter
    final filteredRequests = _selectedFilter == 'All'
        ? allBloodRequests
        : allBloodRequests.where((req) => req.urgency == _selectedFilter).toList();
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).appBarTheme.backgroundColor 
            : AppConstants.primaryColor,
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
          
          // Stats summary
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.bloodtype,
                    title: 'Total',
                    value: allBloodRequests.length.toString(),
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.priority_high,
                    title: 'Urgent',
                    value: allBloodRequests
                        .where((req) => req.urgency == 'Urgent')
                        .length
                        .toString(),
                    color: AppConstants.errorColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Blood requests list
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
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
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: color,
                ),
              ),
            ],
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
    return Builder(
      builder: (context) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: context.isDarkMode
                ? null
                : LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.white,
                      request.urgency == 'Urgent' ? Colors.red.shade50 : Colors.blue.shade50,
                    ],
                  ),
            color: context.isDarkMode
                ? (request.urgency == 'Urgent' 
                    ? Colors.red.shade900.withOpacity(0.2) 
                    : Colors.blue.shade900.withOpacity(0.1))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: (request.urgency == 'Urgent' 
                                ? Colors.red 
                                : AppConstants.primaryColor).withOpacity(0.3),
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
                                  request.bloodType,
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
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: AppConstants.lightTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${request.requestDate.day}/${request.requestDate.month}/${request.requestDate.year}',
                                style: const TextStyle(
                                  fontSize: 12,
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Option to call the requester
                        // This would typically launch a phone call
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
} 