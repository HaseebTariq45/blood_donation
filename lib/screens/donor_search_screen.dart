import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/blood_type_badge.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';

class DonorSearchScreen extends StatefulWidget {
  const DonorSearchScreen({Key? key}) : super(key: key);

  @override
  State<DonorSearchScreen> createState() => _DonorSearchScreenState();
}

class _DonorSearchScreenState extends State<DonorSearchScreen> {
  final _searchController = TextEditingController();
  String? _selectedBloodType;
  bool _onlyAvailable = false;
  List<UserModel> _filteredDonors = [];
  
  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFilteredDonors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredDonors() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final searchQuery = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredDonors = appProvider.filterDonors(
        bloodType: _selectedBloodType,
        onlyAvailable: _onlyAvailable,
      ).where((donor) {
        if (searchQuery.isEmpty) return true;
        return donor.name.toLowerCase().contains(searchQuery) ||
            donor.address.toLowerCase().contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Find Blood Donors',
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or location',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _updateFilteredDonors();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _updateFilteredDonors(),
                ),
                const SizedBox(height: 16),
                // Filter Options
                Row(
                  children: [
                    // Blood Type Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppConstants.accentColor,
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            hint: const Text('Blood Type'),
                            value: _selectedBloodType,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Types'),
                              ),
                              ..._bloodTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedBloodType = value;
                              });
                              _updateFilteredDonors();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Available Toggle
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _onlyAvailable = !_onlyAvailable;
                          });
                          _updateFilteredDonors();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _onlyAvailable
                                ? AppConstants.primaryColor.withOpacity(0.1)
                                : AppConstants.accentColor,
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                            border: _onlyAvailable
                                ? Border.all(color: AppConstants.primaryColor)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 18,
                                color: _onlyAvailable
                                    ? AppConstants.primaryColor
                                    : AppConstants.lightTextColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Available Only',
                                style: TextStyle(
                                  color: _onlyAvailable
                                      ? AppConstants.primaryColor
                                      : AppConstants.lightTextColor,
                                  fontWeight: _onlyAvailable
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Donor List
          Expanded(
            child: _filteredDonors.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    itemCount: _filteredDonors.length,
                    itemBuilder: (context, index) {
                      final donor = _filteredDonors[index];
                      return _buildDonorCard(donor);
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
            Icons.search_off,
            size: 70,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No donors found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your search criteria',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorCard(UserModel donor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Donor Image
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppConstants.accentColor,
                  backgroundImage: donor.imageUrl.isNotEmpty
                      ? NetworkImage(donor.imageUrl)
                      : null,
                  child: donor.imageUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: AppConstants.primaryColor,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Donor Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                              donor.address,
                              style: const TextStyle(
                                color: AppConstants.lightTextColor,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Availability Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: donor.isAvailableToDonate
                              ? AppConstants.successColor.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          donor.isAvailableToDonate ? 'Available' : 'Busy',
                          style: TextStyle(
                            color: donor.isAvailableToDonate
                                ? AppConstants.successColor
                                : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                BloodTypeBadge(bloodType: donor.bloodType),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Call',
                    icon: Icons.call,
                    onPressed: () {
                      // Implement call functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling ${donor.name}'),
                          backgroundColor: AppConstants.successColor,
                        ),
                      );
                    },
                    type: ButtonType.outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Message',
                    icon: Icons.chat_bubble_outline,
                    onPressed: () {
                      // Implement message functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Messaging ${donor.name}'),
                          backgroundColor: AppConstants.primaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 