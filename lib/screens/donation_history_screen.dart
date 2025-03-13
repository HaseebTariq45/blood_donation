import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/blood_type_badge.dart';
import '../models/donation_model.dart';
import '../utils/theme_helper.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  List<DonationModel> _filteredDonations = [];
  String _filterStatus = 'All';
  final List<String> _statusFilters = ['All', 'Completed', 'Pending', 'Cancelled'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initial load of donations
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.loadUserDonations();
      
      _filterDonations();
    } catch (e) {
      debugPrint('Error loading donations: $e');
      // Handle error, maybe show a snackbar
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterDonations() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      if (_filterStatus == 'All') {
        _filteredDonations = List.from(appProvider.userDonations);
      } else {
        _filteredDonations = appProvider.userDonations
            .where((donation) => donation.status == _filterStatus)
            .toList();
      }
    });
  }

  void _applyFilter(String status) {
    setState(() {
      _filterStatus = status;
      _filterDonations();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _cancelDonation(String donationId) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await appProvider.cancelDonation(donationId);
      
      // Close the loading dialog
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Update filtered list
        _filterDonations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel donation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: const CustomAppBar(
        title: 'Donation History',
      ),
      body: RefreshIndicator(
        onRefresh: _loadDonations,
        child: Column(
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
                              : context.textColor,
                          fontWeight: _filterStatus == status
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
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
                // Stream builder to get real-time donations
                return StreamBuilder<List<DonationModel>>(
                  stream: appProvider.getUserDonationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    // Use snapshot data if available, otherwise fall back to appProvider
                    final donations = snapshot.hasData 
                        ? snapshot.data! 
                        : appProvider.userDonations;
                    
                    final totalDonations = donations.length;
                    final completedDonations = donations
                        .where((d) => d.status == 'Completed')
                        .length;
                    
                    // Update filtered donations if we got new data
                    if (snapshot.hasData && snapshot.data != appProvider.userDonations) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _filterDonations();
                      });
                    }
                    
                    return Column(
                      children: [
                        Padding(
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
                        ),
                        
                        // Only show chart if we have enough donations
                        if (donations.length > 1)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Donation History',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 180,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _buildDonationChart(donations),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),

            // Donations list
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredDonations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _filteredDonations.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final donation = _filteredDonations[index];
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 16),
                          color: context.cardColor,
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
                                        color: context.secondaryTextColor,
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
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: context.textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            donation.address,
                                            style: TextStyle(
                                              color: context.secondaryTextColor,
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
                                    Expanded(
                                      child: Text(
                                        '1 Unit (450ml)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: context.textColor,
                                        ),
                                      ),
                                    ),
                                    if (donation.status == 'Pending')
                                      TextButton.icon(
                                        onPressed: () => _cancelDonation(donation.id),
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
                                              color: context.isDarkMode ? Colors.green[400] : Colors.green[700],
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/blood_banks');
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/empty_donation.png',
              height: 180,
              width: 180,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.water_drop_outlined,
                    size: 80,
                    color: AppConstants.primaryColor.withOpacity(0.7),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'No Donations Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start your journey of helping others by donating blood. Every drop counts!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: context.secondaryTextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.primaryColor, Color(0xFFEA4335)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed('/blood_banks');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.volunteer_activism,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Donate Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode ? color.withOpacity(0.15) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.black12 : color.withOpacity(0.1),
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
                    color: context.secondaryTextColor,
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

  Widget _buildDonationChart(List<DonationModel> donations) {
    // Sort donations by date (oldest first)
    final sortedDonations = List<DonationModel>.from(donations)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    if (sortedDonations.isEmpty) return const SizedBox();
    
    // Group donations by month for the bar chart
    final Map<String, int> donationsByMonth = {};
    
    for (final donation in sortedDonations) {
      final month = DateFormat('MMM yyyy').format(donation.date);
      donationsByMonth[month] = (donationsByMonth[month] ?? 0) + 1;
    }
    
    // Convert to list of FlSpot for the chart
    final List<BarChartGroupData> barGroups = [];
    final months = donationsByMonth.keys.toList();
    
    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      final count = donationsByMonth[month] ?? 0;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: AppConstants.primaryColor,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: donationsByMonth.values.fold(0, (max, value) => value > max ? value : max) + 1,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= months.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    months[value.toInt()],
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
              reservedSize: 24,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: barGroups,
      ),
    );
  }
} 