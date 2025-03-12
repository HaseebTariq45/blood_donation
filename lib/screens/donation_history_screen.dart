import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/blood_type_badge.dart';
import '../models/donation_model.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  List<DonationModel> _filteredDonations = [];
  String _filterStatus = 'All';
  final List<String> _statusFilters = ['All', 'Completed', 'Pending', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    // Initialize with all donations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      setState(() {
        _filteredDonations = List.from(appProvider.userDonations);
      });
    });
  }

  void _applyFilter(String status) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      _filterStatus = status;
      if (status == 'All') {
        _filteredDonations = List.from(appProvider.userDonations);
      } else {
        _filteredDonations = appProvider.userDonations
            .where((donation) => donation.status == status)
            .toList();
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Donation History',
      ),
      body: Column(
        children: [
          // Filter chip row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _statusFilters.length,
                itemBuilder: (context, index) {
                  final status = _statusFilters[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: _filterStatus == status,
                      showCheckmark: false,
                      label: Text(status),
                      labelStyle: TextStyle(
                        color: _filterStatus == status
                            ? Colors.white
                            : AppConstants.darkTextColor,
                        fontWeight: _filterStatus == status
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      backgroundColor: Colors.grey[100],
                      selectedColor: AppConstants.primaryColor,
                      onSelected: (selected) {
                        _applyFilter(status);
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // Stats summary
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              final totalDonations = appProvider.userDonations.length;
              final completedDonations = appProvider.userDonations
                  .where((d) => d.status == 'Completed')
                  .length;
              
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard(
                        'Total Donations',
                        totalDonations.toString(),
                        Icons.history,
                        AppConstants.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Completed',
                        completedDonations.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Blood Saved (L)',
                        (completedDonations * 0.45).toStringAsFixed(1),
                        Icons.water_drop,
                        AppConstants.primaryColor,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Donations list
          Expanded(
            child: _filteredDonations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredDonations.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final donation = _filteredDonations[index];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(donation.status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      donation.status,
                                      style: TextStyle(
                                        color: _getStatusColor(donation.status),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatDate(donation.date),
                                    style: TextStyle(
                                      color: AppConstants.lightTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryColor
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        donation.bloodType,
                                        style: const TextStyle(
                                          color: AppConstants.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          donation.centerName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          donation.address,
                                          style: TextStyle(
                                            color: AppConstants.lightTextColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      '1 Unit (450ml)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (donation.status == 'Pending')
                                    TextButton.icon(
                                      onPressed: () {
                                        // Cancel donation logic
                                      },
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: AppConstants.errorColor,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: AppConstants.errorColor,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                      ),
                                    ),
                                  if (donation.status == 'Completed')
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.verified,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Verified',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No donations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your donation history will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/blood_banks');
            },
            icon: const Icon(Icons.add),
            label: const Text('Donate Now'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.blue;
      case 'Cancelled':
        return AppConstants.errorColor;
      default:
        return Colors.grey;
    }
  }
} 