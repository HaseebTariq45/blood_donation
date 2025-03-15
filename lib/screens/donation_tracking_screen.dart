import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../models/blood_request_model.dart';
import '../models/donation_model.dart';
import '../utils/theme_helper.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/request_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/donation_card.dart';
import '../widgets/contact_info_modal.dart';

class DonationTrackingScreen extends StatefulWidget {
  const DonationTrackingScreen({super.key});

  @override
  State<DonationTrackingScreen> createState() => _DonationTrackingScreenState();
}

class _DonationTrackingScreenState extends State<DonationTrackingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _mainTabController;
  late TabController _donationsTabController;
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Add filter options
  String? _selectedBloodType;
  final List<String> _bloodTypes = [
    'All Types',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _mainTabController = TabController(length: 2, vsync: this);
    _donationsTabController = TabController(length: 3, vsync: this);
    _loadData();

    // Listen for search changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Add listeners for tab animations
    _mainTabController.addListener(_handleTabAnimation);
    _tabController.addListener(_handleTabAnimation);
    _donationsTabController.addListener(_handleTabAnimation);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabAnimation);
    _mainTabController.removeListener(_handleTabAnimation);
    _donationsTabController.removeListener(_handleTabAnimation);
    _tabController.dispose();
    _mainTabController.dispose();
    _donationsTabController.dispose();
    super.dispose();
  }

  // Handle tab controller animations
  void _handleTabAnimation() {
    // This forces a repaint when the tab animation occurs
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUserId = appProvider.currentUser.id;

      // Log information for debugging
      debugPrint(
        'DonationTrackingScreen - _loadData() - Loading data for user ID: $currentUserId',
      );

      // Verify if user ID is valid
      if (currentUserId.isEmpty || currentUserId == 'user123') {
        debugPrint('DonationTrackingScreen - Invalid user ID: $currentUserId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot load donation data: User not properly authenticated',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Verify Firestore collections exist
      try {
        // Check blood_requests collection for pending requests
        final pendingRequestsQuery =
            await FirebaseFirestore.instance
                .collection('blood_requests')
                .where('requesterId', isEqualTo: currentUserId)
                .where('status', isEqualTo: 'Pending')
                .limit(1)
                .get();

        debugPrint(
          'DonationTrackingScreen - pending blood_requests check - Query returned ${pendingRequestsQuery.docs.length} documents',
        );

        // Check blood_requests collection for in-progress requests
        final inProgressRequestsQuery =
            await FirebaseFirestore.instance
                .collection('blood_requests')
                .where('requesterId', isEqualTo: currentUserId)
                .where('status', whereIn: ['Accepted', 'In Progress'])
                .limit(1)
                .get();

        debugPrint(
          'DonationTrackingScreen - in-progress blood_requests check - Query returned ${inProgressRequestsQuery.docs.length} documents',
        );

        // Check blood_requests collection for completed requests
        final completedRequestsQuery =
            await FirebaseFirestore.instance
                .collection('blood_requests')
                .where('requesterId', isEqualTo: currentUserId)
                .where('status', isEqualTo: 'Fulfilled')
                .limit(1)
                .get();

        debugPrint(
          'DonationTrackingScreen - completed blood_requests check - Query returned ${completedRequestsQuery.docs.length} documents',
        );

        // Check donations collection
        final donationsQuery =
            await FirebaseFirestore.instance
                .collection('donations')
                .where('recipientId', isEqualTo: currentUserId)
                .limit(1)
                .get();

        debugPrint(
          'DonationTrackingScreen - donations collection check - Query returned ${donationsQuery.docs.length} documents',
        );

        // Also check if user is a donor
        final donorQuery =
            await FirebaseFirestore.instance
                .collection('donations')
                .where('donorId', isEqualTo: currentUserId)
                .limit(1)
                .get();

        debugPrint(
          'DonationTrackingScreen - donor check - Query returned ${donorQuery.docs.length} documents',
        );
      } catch (e) {
        debugPrint('DonationTrackingScreen - Error checking collections: $e');
      }

      // Data will be loaded via StreamBuilder in the widget tree
      debugPrint('DonationTrackingScreen - Initial data check completed');
    } catch (e) {
      debugPrint(
        'DonationTrackingScreen - Error loading donation tracking data: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method to build info rows for request details
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$title:',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Format date to readable string
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return dateStr;
    }
  }

  // Contact recipient or donor
  Future<void> _contactRecipient(String phoneNumber) async {
    if (phoneNumber == 'N/A' || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact information unavailable'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cancel a blood request
  Future<void> _cancelRequest(String requestId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Cancel Request'),
              content: const Text(
                'Are you sure you want to cancel this request?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      // Update the request status in Firestore
      await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(requestId)
          .update({
            'status': 'Cancelled',
            'cancellationDate': DateTime.now().toIso8601String(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show completion dialog
  Future<void> _showCompletionDialog(BloodRequestModel request) async {
    final TextEditingController notesController = TextEditingController();

    try {
      final completed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Mark as Completed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Confirm that the donation has been completed.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Completion'),
                ),
              ],
            ),
      );

      if (completed != true) return;

      // Update the request status in Firestore
      await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(request.id)
          .update({
            'status': 'Fulfilled',
            'completionDate': DateTime.now().toIso8601String(),
            'completionNotes': notesController.text,
          });

      // Add to completed donations collection
      final donationId =
          FirebaseFirestore.instance.collection('donations').doc().id;
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .set({
            'id': donationId,
            'requestId': request.id,
            'donorId': request.responderId ?? '',
            'donorName': request.responderName ?? 'Unknown',
            'recipientId': request.requesterId,
            'recipientName': request.requesterName,
            'bloodType': request.bloodType,
            'location': request.location,
            'date': DateTime.now().toIso8601String(),
            'status': 'Completed',
            'notes': notesController.text,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error completing donation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete donation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cancel a donation
  Future<void> _cancelDonation(String donationId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Cancel Donation'),
              content: const Text(
                'Are you sure you want to cancel this donation? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No, Keep It'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Yes, Cancel'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      setState(() {
        _isLoading = true;
      });

      // Get the donation data first
      final donationDoc =
          await FirebaseFirestore.instance
              .collection('donations')
              .doc(donationId)
              .get();

      if (!donationDoc.exists) {
        throw Exception('Donation not found');
      }

      final donationData = donationDoc.data() as Map<String, dynamic>;

      // Check if this donation is linked to a request
      if (donationData.containsKey('requestId') &&
          donationData['requestId'] != null) {
        final requestId = donationData['requestId'];

        // Update the request status back to pending
        await FirebaseFirestore.instance
            .collection('blood_requests')
            .doc(requestId)
            .update({
              'status': 'Pending',
              'responderId': null,
              'responderName': null,
              'responderPhone': null,
              'responseDate': null,
            });
      }

      // Update the donation status
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
            'status': 'Cancelled',
            'cancellationDate': DateTime.now().toIso8601String(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling donation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel donation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Donation Tracking', showBackButton: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDonationDialog(context),
        child: const Icon(Icons.add),
        backgroundColor: AppConstants.primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Dashboard summary section
                  _buildDashboardSummary(),

                  // Search and filter in a row to save space
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Row(
                      children: [
                        // Search field
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: const TextStyle(fontSize: 14),
                              prefixIcon: const Icon(Icons.search, size: 18),
                              suffixIcon:
                                  _searchQuery.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                      )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Blood type filter dropdown
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).cardColor,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBloodType ?? 'All Types',
                                isExpanded: true,
                                hint: const Text(
                                  'Blood Type',
                                  style: TextStyle(fontSize: 14),
                                ),
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  size: 18,
                                ),
                                items:
                                    _bloodTypes.map((String type) {
                                      return DropdownMenuItem<String>(
                                        value: type,
                                        child: Row(
                                          children: [
                                            _buildBloodTypeCircle(type),
                                            const SizedBox(width: 4),
                                            Text(
                                              type,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedBloodType =
                                        newValue == 'All Types'
                                            ? null
                                            : newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Custom tab bar with enhanced styling
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _mainTabController,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppConstants.primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.primaryColor.withOpacity(
                                  0.4,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor:
                              Theme.of(context).textTheme.bodyLarge?.color,
                          dividerColor: Colors.transparent,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overlayColor:
                              MaterialStateProperty.resolveWith<Color?>((
                                Set<MaterialState> states,
                              ) {
                                if (states.contains(MaterialState.pressed)) {
                                  return Colors.transparent;
                                }
                                return null;
                              }),
                          splashFactory: NoSplash.splashFactory,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: [
                            Tab(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.pending_actions, size: 18),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'My Requests',
                                        style: TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Tab(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.volunteer_activism, size: 18),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'My Donations',
                                        style: TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Tab content with animation
                  Expanded(
                    child: TabBarView(
                      controller: _mainTabController,
                      physics: const BouncingScrollPhysics(),
                      children: [_buildMyRequestsTab(), _buildMyDonationsTab()],
                    ),
                  ),
                ],
              ),
    );
  }

  // New dashboard summary widget with statistics
  Widget _buildDashboardSummary() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('requesterId', isEqualTo: currentUserId)
              .snapshots(),
      builder: (context, snapshot) {
        int pendingCount = 0;
        int inProgressCount = 0;
        int completedCount = 0;

        if (snapshot.hasData) {
          final requests = snapshot.data?.docs ?? [];
          for (var doc in requests) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String;

            if (status == 'Pending') {
              pendingCount++;
            } else if (status == 'Accepted' || status == 'In Progress') {
              inProgressCount++;
            } else if (status == 'Fulfilled') {
              completedCount++;
            }
          }
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppConstants.primaryColor.withOpacity(0.9),
                AppConstants.primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Title section
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.insights,
                      color: Colors.white.withOpacity(0.9),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Summary',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Stat cards in a row
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      context,
                      'Pending',
                      pendingCount.toString(),
                      Icons.hourglass_empty,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      context,
                      'Active',
                      inProgressCount.toString(),
                      Icons.pending_actions,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      context,
                      'Done',
                      completedCount.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Stat card for dashboard
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Blood type circle badge for dropdown
  Widget _buildBloodTypeCircle(String bloodType) {
    Color circleColor;
    if (bloodType == 'All Types') {
      circleColor = Colors.grey;
    } else if (bloodType.contains('A')) {
      circleColor = Colors.blue;
    } else if (bloodType.contains('B')) {
      circleColor = Colors.red;
    } else if (bloodType.contains('AB')) {
      circleColor = Colors.purple;
    } else {
      circleColor = Colors.green;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor.withOpacity(0.2),
        border: Border.all(color: circleColor, width: 1.5),
      ),
      child: Center(
        child: Text(
          bloodType == 'All Types' ? 'All' : bloodType,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: circleColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    return Column(
      children: [
        // Sub-tab bar for My Requests with enhanced styling
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppConstants.primaryColor,
                unselectedLabelColor: Colors.grey.shade600,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pending_actions, size: 16),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'Pending',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_top, size: 16),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'In Progress',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'Completed',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildPendingTab(),
              _buildInProgressTab(),
              _buildCompletedTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyDonationsTab() {
    return Column(
      children: [
        // Sub-tab bar for My Donations with enhanced styling
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: TabBar(
                controller: _donationsTabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppConstants.primaryColor,
                unselectedLabelColor: Colors.grey.shade600,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pending_actions, size: 16),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'Pending',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available, size: 16),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'Scheduled',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 16),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'History',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _donationsTabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildPendingDonationsTab(),
              _buildAcceptedDonationsTab(),
              _buildDonationHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  // Custom pull-to-refresh animation builder
  Widget _buildCustomRefreshIndicator({
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: Colors.white,
      color: AppConstants.primaryColor,
      strokeWidth: 3,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: child,
    );
  }

  Widget _buildPendingTab() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;
    debugPrint(
      'DonationTrackingScreen - Building pending tab for user ID: $currentUserId',
    );

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('requesterId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'Pending')
              .orderBy('requestDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        // Debug connection state
        debugPrint(
          'DonationTrackingScreen - Pending requests - Connection state: ${snapshot.connectionState}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - Pending requests - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data?.docs ?? [];

        // Apply blood type filter if needed
        var filteredRequests = requests;
        if (_selectedBloodType != null) {
          filteredRequests =
              requests.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['bloodType'] == _selectedBloodType;
              }).toList();
        }

        // Apply search filter if needed
        filteredRequests =
            _searchQuery.isEmpty
                ? filteredRequests
                : filteredRequests.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchableFields = [
                    data['bloodType']?.toString().toLowerCase() ?? '',
                    data['location']?.toString().toLowerCase() ?? '',
                    data['requesterName']?.toString().toLowerCase() ?? '',
                  ];
                  return searchableFields.any(
                    (field) => field.contains(_searchQuery.toLowerCase()),
                  );
                }).toList();

        debugPrint(
          'DonationTrackingScreen - Pending requests - Loaded ${filteredRequests.length} requests (filtered from ${requests.length} total)',
        );

        if (filteredRequests.isEmpty) {
          return EmptyStateFactory.noPendingRequests(
            onAction: () => Navigator.of(context).pushNamed('/request'),
          );
        }

        return _buildCustomRefreshIndicator(
          onRefresh: () async {
            // Refresh data
            setState(() {}); // Trigger rebuild
            return Future.delayed(const Duration(milliseconds: 1500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final requestData =
                  filteredRequests[index].data() as Map<String, dynamic>;
              final request = BloodRequestModel.fromMap(requestData);

              return RequestCard(
                request: request,
                showActions: true,
                onCancel: () {
                  _cancelRequest(request.id);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInProgressTab() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;
    debugPrint(
      'DonationTrackingScreen - Building in-progress tab for user ID: $currentUserId',
    );

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('requesterId', isEqualTo: currentUserId)
              .where('status', whereIn: ['Accepted', 'In Progress'])
              .orderBy('responseDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        // Debug connection state
        debugPrint(
          'DonationTrackingScreen - In progress requests - Connection state: ${snapshot.connectionState}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - In progress requests - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data?.docs ?? [];

        // Apply search filter if needed
        final filteredRequests =
            _searchQuery.isEmpty
                ? requests
                : requests.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchableFields = [
                    data['bloodType']?.toString().toLowerCase() ?? '',
                    data['location']?.toString().toLowerCase() ?? '',
                    data['responderName']?.toString().toLowerCase() ?? '',
                    data['requesterName']?.toString().toLowerCase() ?? '',
                  ];
                  return searchableFields.any(
                    (field) => field.contains(_searchQuery.toLowerCase()),
                  );
                }).toList();

        debugPrint(
          'DonationTrackingScreen - In progress requests - Loaded ${filteredRequests.length} requests (filtered from ${requests.length} total)',
        );

        if (filteredRequests.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.hourglass_top,
            title:
                _searchQuery.isNotEmpty
                    ? 'No matching requests'
                    : 'No active donations',
            message:
                _searchQuery.isNotEmpty
                    ? 'Try changing your search criteria'
                    : 'You don\'t have any donations in progress.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh data
            setState(() {}); // Trigger rebuild
            return Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final requestData =
                  filteredRequests[index].data() as Map<String, dynamic>;
              final request = BloodRequestModel.fromMap(requestData);

              // Get responder info from the request data
              final responderName = requestData['responderName'] ?? 'Unknown';
              final responderPhone = requestData['responderPhone'] ?? 'N/A';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request.bloodType,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Donation in Progress',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: context.textColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.person,
                        title: 'Donor',
                        value: responderName,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.phone,
                        title: 'Contact',
                        value: responderPhone,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        title: 'Response Date',
                        value: _formatDate(requestData['responseDate'] ?? ''),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  () => _contactRecipient(responderPhone),
                              icon: const Icon(Icons.phone, size: 16),
                              label: const Text('Contact'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppConstants.primaryColor,
                                side: BorderSide(
                                  color: AppConstants.primaryColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showCompletionDialog(request),
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Mark as Completed'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;
    debugPrint(
      'DonationTrackingScreen - Building completed tab for user ID: $currentUserId',
    );

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('requesterId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'Fulfilled')
              .orderBy('completionDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        // Debug connection state
        debugPrint(
          'DonationTrackingScreen - Completed requests - Connection state: ${snapshot.connectionState}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - Completed requests - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data?.docs ?? [];

        // Apply search filter if needed
        final filteredRequests =
            _searchQuery.isEmpty
                ? requests
                : requests.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchableFields = [
                    data['bloodType']?.toString().toLowerCase() ?? '',
                    data['location']?.toString().toLowerCase() ?? '',
                    data['responderName']?.toString().toLowerCase() ?? '',
                    data['requesterName']?.toString().toLowerCase() ?? '',
                  ];
                  return searchableFields.any(
                    (field) => field.contains(_searchQuery.toLowerCase()),
                  );
                }).toList();

        debugPrint(
          'DonationTrackingScreen - Completed requests - Loaded ${filteredRequests.length} requests (filtered from ${requests.length} total)',
        );

        if (filteredRequests.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.history,
            title:
                _searchQuery.isNotEmpty
                    ? 'No matching requests'
                    : 'No completed requests',
            message:
                _searchQuery.isNotEmpty
                    ? 'Try changing your search criteria'
                    : 'You haven\'t completed any blood donation requests yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh data
            setState(() {}); // Trigger rebuild
            return Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final requestData =
                  filteredRequests[index].data() as Map<String, dynamic>;
              final request = BloodRequestModel.fromMap(requestData);

              // Get responder info from the request data
              final responderName = requestData['responderName'] ?? 'Unknown';
              final responderPhone = requestData['responderPhone'] ?? 'N/A';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request.bloodType,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Completed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: context.textColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Completed',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.person,
                        title: 'Donor',
                        value: responderName,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.phone,
                        title: 'Contact',
                        value: responderPhone,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        title: 'Completion Date',
                        value: _formatDate(requestData['completionDate'] ?? ''),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  () => _contactRecipient(responderPhone),
                              icon: const Icon(Icons.phone, size: 16),
                              label: const Text('Contact'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppConstants.primaryColor,
                                side: BorderSide(
                                  color: AppConstants.primaryColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAcceptedDonationsTab() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;
    debugPrint(
      'DonationTrackingScreen - Building accepted donations tab for user ID: $currentUserId',
    );

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('responderId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'Accepted')
              .orderBy('responseDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        // Debug connection state
        debugPrint(
          'DonationTrackingScreen - Accepted donations - Connection state: ${snapshot.connectionState}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - Accepted donations - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data?.docs ?? [];

        // Apply search filter if needed
        final filteredRequests =
            _searchQuery.isEmpty
                ? requests
                : requests.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchableFields = [
                    data['bloodType']?.toString().toLowerCase() ?? '',
                    data['location']?.toString().toLowerCase() ?? '',
                    data['requesterName']?.toString().toLowerCase() ?? '',
                    data['hospitalName']?.toString().toLowerCase() ?? '',
                  ];
                  return searchableFields.any(
                    (field) => field.contains(_searchQuery.toLowerCase()),
                  );
                }).toList();

        debugPrint(
          'DonationTrackingScreen - Accepted donations - Loaded ${filteredRequests.length} requests (filtered from ${requests.length} total)',
        );

        if (filteredRequests.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.check_circle,
            title:
                _searchQuery.isNotEmpty
                    ? 'No matching donations'
                    : 'No accepted donations',
            message:
                _searchQuery.isNotEmpty
                    ? 'Try changing your search criteria'
                    : 'You haven\'t accepted any donation requests yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh data
            setState(() {}); // Trigger rebuild
            return Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final requestData =
                  filteredRequests[index].data() as Map<String, dynamic>;
              final request = BloodRequestModel.fromMap(requestData);

              // Create a donation model from the request data
              final donation = DonationModel(
                id: request.id,
                donorId: currentUserId,
                donorName: requestData['responderName'] ?? 'You',
                recipientId: request.requesterId,
                recipientName: request.requesterName,
                recipientPhone: requestData['requesterPhone'] ?? 'N/A',
                bloodType: request.bloodType,
                date:
                    DateTime.tryParse(requestData['responseDate'] ?? '') ??
                    DateTime.now(),
                centerName: requestData['hospitalName'] ?? request.location,
                address: request.location,
                status: 'Scheduled',
              );

              return DonationCard(
                donation: donation,
                showActions: true,
                actionLabel: 'Mark Complete',
                onAction: () {
                  _showCompletionDialog(request);
                },
                onContactRecipient: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder:
                        (context) => ContactInfoModal(
                          name: request.requesterName,
                          phone: requestData['requesterPhone'] ?? 'N/A',
                          title: 'Contact Recipient',
                        ),
                  );
                },
                onCancel: () {
                  _cancelRequest(request.id);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDonationHistoryTab() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;
    debugPrint(
      'DonationTrackingScreen - Building donation history tab for user ID: $currentUserId',
    );

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('donations')
              .where('donorId', isEqualTo: currentUserId)
              .orderBy('date', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        // Debug connection state
        debugPrint(
          'DonationTrackingScreen - Donation history - Connection state: ${snapshot.connectionState}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - Donation history - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final donations = snapshot.data?.docs ?? [];

        // Apply search filter if needed
        final filteredDonations =
            _searchQuery.isEmpty
                ? donations
                : donations.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchableFields = [
                    data['bloodType']?.toString().toLowerCase() ?? '',
                    data['centerName']?.toString().toLowerCase() ?? '',
                    data['recipientName']?.toString().toLowerCase() ?? '',
                    data['address']?.toString().toLowerCase() ?? '',
                  ];
                  return searchableFields.any(
                    (field) => field.contains(_searchQuery.toLowerCase()),
                  );
                }).toList();

        debugPrint(
          'DonationTrackingScreen - Donation history - Loaded ${filteredDonations.length} donations (filtered from ${donations.length} total)',
        );

        if (filteredDonations.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.history,
            title:
                _searchQuery.isNotEmpty
                    ? 'No matching donations'
                    : 'No donation history',
            message:
                _searchQuery.isNotEmpty
                    ? 'Try changing your search criteria'
                    : 'You haven\'t made any blood donations yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh data
            setState(() {}); // Trigger rebuild
            return Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDonations.length,
            itemBuilder: (context, index) {
              final donationData =
                  filteredDonations[index].data() as Map<String, dynamic>;
              final donation = DonationModel.fromJson(donationData);

              return DonationCard(
                donation: donation,
                showActions:
                    donation.status != 'Completed' &&
                    donation.status != 'Cancelled',
                actionLabel:
                    donation.status == 'Pending' ? 'Schedule' : 'Mark Complete',
                onAction: () {
                  if (donation.status == 'Pending') {
                    _scheduleDonation(donation);
                  } else if (donation.status == 'Scheduled') {
                    _showCompletionDialog(
                      BloodRequestModel(
                        id: donation.id,
                        requesterId: donation.recipientId,
                        requesterName: donation.recipientName,
                        bloodType: donation.bloodType,
                        location: donation.address,
                        requestDate: DateTime.now(),
                        contactNumber: donation.recipientPhone ?? 'N/A',
                        urgency: 'Normal',
                        status: 'Scheduled',
                      ),
                    );
                  }
                },
                onContactRecipient:
                    donation.recipientPhone != null &&
                            donation.recipientPhone!.isNotEmpty
                        ? () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder:
                                (context) => ContactInfoModal(
                                  name: donation.recipientName,
                                  phone: donation.recipientPhone ?? 'N/A',
                                  title: 'Contact Recipient',
                                ),
                          );
                        }
                        : null,
                onCancel:
                    donation.status != 'Completed' &&
                            donation.status != 'Cancelled'
                        ? () {
                          _cancelDonation(donation.id);
                        }
                        : null,
              );
            },
          ),
        );
      },
    );
  }

  // Implement the missing pending donations tab
  Widget _buildPendingDonationsTab() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;
    debugPrint(
      'DonationTrackingScreen - Building pending donations tab for user ID: $currentUserId',
    );

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('donations')
              .where('donorId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'Pending')
              .orderBy('date', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - Pending donations - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final donations = snapshot.data?.docs ?? [];

        // Apply search filter if needed
        final filteredDonations =
            _searchQuery.isEmpty
                ? donations
                : donations.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchableFields = [
                    data['bloodType']?.toString().toLowerCase() ?? '',
                    data['centerName']?.toString().toLowerCase() ?? '',
                    data['recipientName']?.toString().toLowerCase() ?? '',
                    data['address']?.toString().toLowerCase() ?? '',
                  ];
                  return searchableFields.any(
                    (field) => field.contains(_searchQuery.toLowerCase()),
                  );
                }).toList();

        debugPrint(
          'DonationTrackingScreen - Pending donations - Loaded ${filteredDonations.length} donations (filtered from ${donations.length} total)',
        );

        if (filteredDonations.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.pending_actions,
            title:
                _searchQuery.isNotEmpty
                    ? 'No matching donations'
                    : 'No pending donations',
            message:
                _searchQuery.isNotEmpty
                    ? 'Try changing your search criteria'
                    : 'You don\'t have any pending blood donations yet.',
          );
        }

        return _buildCustomRefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
            return Future.delayed(const Duration(milliseconds: 1500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDonations.length,
            itemBuilder: (context, index) {
              final donationData =
                  filteredDonations[index].data() as Map<String, dynamic>;
              final donation = DonationModel.fromJson(donationData);

              return DonationCard(
                donation: donation,
                showActions: true,
                actionLabel: 'Schedule',
                onAction: () => _scheduleDonation(donation),
                onContactRecipient:
                    donation.recipientPhone != null &&
                            donation.recipientPhone!.isNotEmpty
                        ? () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder:
                                (context) => ContactInfoModal(
                                  name: donation.recipientName,
                                  phone: donation.recipientPhone ?? 'N/A',
                                  title: 'Contact Recipient',
                                ),
                          );
                        }
                        : null,
                onCancel: () => _cancelDonation(donation.id),
              );
            },
          ),
        );
      },
    );
  }

  // Helper method to show the add donation dialog
  void _showAddDonationDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController centerController = TextEditingController();
    final TextEditingController addressController = TextEditingController();

    String selectedBloodType = 'A+';
    DateTime selectedDate = DateTime.now();

    dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Record Donation'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add a record for donations made at centers outside the app',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    // Blood type dropdown
                    DropdownButtonFormField<String>(
                      value: selectedBloodType,
                      decoration: const InputDecoration(
                        labelText: 'Blood Type',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          _bloodTypes.where((type) => type != 'All Types').map((
                            String type,
                          ) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          selectedBloodType = newValue;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select blood type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Date picker
                    TextFormField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Donation Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null && picked != selectedDate) {
                              selectedDate = picked;
                              dateController.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedDate);
                            }
                          },
                        ),
                      ),
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Donation center name
                    TextFormField(
                      controller: centerController,
                      decoration: const InputDecoration(
                        labelText: 'Donation Center Name',
                        hintText: 'e.g. City Blood Bank',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter donation center name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Address
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'Enter center address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _addDonationRecord(
                      bloodType: selectedBloodType,
                      date: selectedDate,
                      centerName: centerController.text,
                      address: addressController.text,
                    );
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  // Add donation record method
  Future<void> _addDonationRecord({
    required String bloodType,
    required DateTime date,
    required String centerName,
    required String address,
  }) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUser = appProvider.currentUser;

      // Create donation model
      final donation = DonationModel(
        id: 'donation_${DateTime.now().millisecondsSinceEpoch}',
        donorId: currentUser.id,
        donorName: currentUser.name,
        bloodType: bloodType,
        date: date,
        centerName: centerName,
        address: address,
        status: 'Completed',
      );

      // Add to Firestore
      await FirebaseFirestore.instance
          .collection('donations')
          .add(donation.toJson());

      // Update user's last donation date
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .update({'lastDonationDate': date.millisecondsSinceEpoch});

      // Refresh user data in the provider
      await appProvider.refreshUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation record added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding donation record: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add donation record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to schedule a donation
  void _scheduleDonation(DonationModel donation) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final TextEditingController hospitalController = TextEditingController(
      text: donation.centerName,
    );
    final TextEditingController addressController = TextEditingController(
      text: donation.address,
    );

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();

    dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    timeController.text = selectedTime.format(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Schedule Donation'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule your donation appointment',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    // Date picker
                    TextFormField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Donation Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 30),
                              ),
                            );
                            if (picked != null && picked != selectedDate) {
                              selectedDate = picked;
                              dateController.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedDate);
                            }
                          },
                        ),
                      ),
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Time picker
                    TextFormField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: 'Donation Time',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null && picked != selectedTime) {
                              selectedTime = picked;
                              timeController.text = selectedTime.format(
                                context,
                              );
                            }
                          },
                        ),
                      ),
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a time';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Hospital name
                    TextFormField(
                      controller: hospitalController,
                      decoration: const InputDecoration(
                        labelText: 'Hospital/Center Name',
                        hintText: 'e.g. City Blood Bank',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter hospital name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Address
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'Enter hospital address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop();

                    // Combine date and time
                    final scheduledDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    try {
                      setState(() {
                        _isLoading = true;
                      });

                      // Update donation in Firestore
                      await FirebaseFirestore.instance
                          .collection('donations')
                          .doc(donation.id)
                          .update({
                            'status': 'Scheduled',
                            'scheduledDate':
                                scheduledDateTime.toIso8601String(),
                            'centerName': hospitalController.text,
                            'address': addressController.text,
                          });

                      // If this is linked to a request, update the request too
                      if (donation.recipientId.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('blood_requests')
                            .doc(donation.id)
                            .update({
                              'status': 'Scheduled',
                              'scheduledDate':
                                  scheduledDateTime.toIso8601String(),
                              'hospitalName': hospitalController.text,
                              'location': addressController.text,
                            });

                        // Send notification to recipient
                        final notificationData = {
                          'userId': donation.recipientId,
                          'title': 'Donation Scheduled',
                          'body':
                              'Your blood donation has been scheduled for ${DateFormat('MMM dd, yyyy').format(scheduledDateTime)} at ${selectedTime.format(context)}',
                          'type': 'donation_scheduled',
                          'read': false,
                          'createdAt': DateTime.now().toIso8601String(),
                          'metadata': {
                            'donationId': donation.id,
                            'scheduledDate':
                                scheduledDateTime.toIso8601String(),
                            'hospitalName': hospitalController.text,
                          },
                        };

                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .add(notificationData);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Donation scheduled successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error scheduling donation: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to schedule donation: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Schedule'),
              ),
            ],
          ),
    );
  }
}
