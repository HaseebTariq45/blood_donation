import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/blood_type_badge.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';
import '../utils/theme_helper.dart';

class DonorSearchScreen extends StatefulWidget {
  const DonorSearchScreen({Key? key}) : super(key: key);

  @override
  State<DonorSearchScreen> createState() => _DonorSearchScreenState();
}

class _DonorSearchScreenState extends State<DonorSearchScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String? _selectedBloodType;
  String? _selectedLocation;
  bool _onlyAvailable = false;
  List<UserModel> _filteredDonors = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  
  // Sample locations - in a real app, this would come from a location database
  final List<String> _locations = [
    'Any Location',
    'Main St, City',
    'Downtown',
    'Uptown',
    'West Side',
    'East Side',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFilteredDonors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
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
        bool matchesSearch = true;
        if (searchQuery.isNotEmpty) {
          matchesSearch = donor.name.toLowerCase().contains(searchQuery) ||
              donor.address.toLowerCase().contains(searchQuery);
        }
        
        bool matchesLocation = true;
        if (_selectedLocation != null && _selectedLocation != 'Any Location') {
          matchesLocation = donor.address.contains(_selectedLocation!);
        }
        
        return matchesSearch && matchesLocation;
      }).toList();
    });
    
    // Animate when list changes
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: const CustomAppBar(
        title: 'Find Blood Donors',
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                  child: Text(
                    'Search for donors',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: context.textColor,
                    ),
                  ),
                ),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: context.textColor),
                    decoration: InputDecoration(
                      hintText: 'Search donors by name or location',
                      hintStyle: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppConstants.primaryColor.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: context.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: context.secondaryTextColor,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _updateFilteredDonors();
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => _updateFilteredDonors(),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
                  child: Text(
                    'Filter options',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppConstants.darkTextColor,
                    ),
                  ),
                ),
                // Filter Section
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Blood Type Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Blood Type',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: context.textColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: context.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBloodType,
                                isExpanded: true,
                                hint: Text(
                                  'All Blood Types',
                                  style: TextStyle(
                                    color: context.secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: context.isDarkMode 
                                    ? AppConstants.primaryColor.withOpacity(0.7) 
                                    : Colors.grey[400],
                                ),
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 14,
                                ),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text(
                                      'All Blood Types',
                                      style: TextStyle(color: context.textColor),
                                    ),
                                  ),
                                  ..._bloodTypes.map((type) {
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 18,
                                            height: 18,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppConstants.primaryColor,
                                            ),
                                            child: Center(
                                              child: Text(
                                                type,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            type,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: context.textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedBloodType = value;
                                  });
                                  _updateFilteredDonors();
                                },
                                dropdownColor: context.cardColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Location Dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: context.textColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: context.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedLocation,
                                isExpanded: true,
                                hint: Text(
                                  'Any Location',
                                  style: TextStyle(
                                    color: context.secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: context.isDarkMode 
                                    ? AppConstants.primaryColor.withOpacity(0.7) 
                                    : Colors.grey[400],
                                ),
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 14,
                                ),
                                items: _locations.map((location) {
                                  return DropdownMenuItem<String>(
                                    value: location == 'Any Location' ? null : location,
                                    child: Text(
                                      location,
                                      style: TextStyle(color: context.textColor),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedLocation = value;
                                  });
                                  _updateFilteredDonors();
                                },
                                dropdownColor: context.cardColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Available Toggle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _onlyAvailable = !_onlyAvailable;
                    });
                    _updateFilteredDonors();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _onlyAvailable 
                          ? AppConstants.primaryColor.withOpacity(0.1)
                          : context.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _onlyAvailable 
                            ? AppConstants.primaryColor
                            : context.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Show only available donors',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: _onlyAvailable 
                                ? AppConstants.primaryColor
                                : context.textColor,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.person_outline,
                          color: _onlyAvailable
                              ? AppConstants.primaryColor
                              : context.secondaryTextColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${_filteredDonors.length} donors',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: context.textColor,
                  ),
                ),
                if (_filteredDonors.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.sort, 
                        size: 16, 
                        color: context.secondaryTextColor
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sort by',
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 14,
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
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingM,
                        vertical: AppConstants.paddingS,
                      ),
                      itemCount: _filteredDonors.length,
                      itemBuilder: (context, index) {
                        final donor = _filteredDonors[index];
                        // Add staggered animation delay based on index
                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: 1.0,
                          curve: Curves.easeInOut,
                          child: AnimatedPadding(
                            duration: const Duration(milliseconds: 500),
                            padding: EdgeInsets.only(
                              top: 0,
                              bottom: 16,
                              left: 0,
                              right: 0,
                            ),
                            child: _buildDonorCard(donor),
                          ),
                        );
                      },
                    ),
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
            Icons.bloodtype_outlined,
            size: 80,
            color: context.isDarkMode ? Colors.grey[600] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No donors found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try changing your filters or search for different criteria',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedBloodType = null;
                _selectedLocation = null;
                _onlyAvailable = false;
              });
              _updateFilteredDonors();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Reset Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorCard(UserModel donor) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.07),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // View donor details
            },
            splashColor: AppConstants.primaryColor.withOpacity(0.05),
            highlightColor: AppConstants.primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Donor Image with Availability Indicator
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: AppConstants.accentColor,
                              backgroundImage: donor.imageUrl.isNotEmpty
                                  ? AssetImage(donor.imageUrl)
                                  : null,
                              child: donor.imageUrl.isEmpty
                                  ? Text(
                                      donor.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.2),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                donor.isAvailableToDonate
                                    ? Icons.check_circle
                                    : Icons.access_time_rounded,
                                color: donor.isAvailableToDonate
                                    ? AppConstants.successColor
                                    : Colors.orange,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Donor Information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              donor.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: context.textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              donor.address,
                              style: TextStyle(
                                color: context.secondaryTextColor,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, 
                                  size: 14, 
                                  color: context.secondaryTextColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Last donation: ${donor.lastDonationDate.day}/${donor.lastDonationDate.month}/${donor.lastDonationDate.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Availability Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: donor.isAvailableToDonate
                                    ? AppConstants.successColor.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: donor.isAvailableToDonate
                                      ? AppConstants.successColor.withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    donor.isAvailableToDonate
                                        ? Icons.check_circle_outline
                                        : Icons.schedule,
                                    size: 14,
                                    color: donor.isAvailableToDonate
                                        ? AppConstants.successColor
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    donor.isAvailableToDonate ? 'Available' : 'Busy',
                                    style: TextStyle(
                                      color: donor.isAvailableToDonate
                                          ? AppConstants.successColor
                                          : Colors.orange,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Blood Type Badge with enhanced visual
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.isDarkMode ? Colors.black12 : AppConstants.primaryColor.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: BloodTypeBadge(
                          bloodType: donor.bloodType,
                          size: 45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, thickness: 1, color: context.isDarkMode ? Colors.grey[800] : const Color(0xFFF5F5F5)),
                  const SizedBox(height: 16),
                  // Contact Buttons with Visual Enhancements
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            // Contact the donor
                          },
                          icon: const Icon(
                            Icons.phone_outlined,
                            size: 16,
                          ),
                          label: const Text('Call'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppConstants.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            // Message the donor
                          },
                          icon: const Icon(
                            Icons.message_outlined,
                            size: 16,
                          ),
                          label: const Text('Message'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppConstants.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 