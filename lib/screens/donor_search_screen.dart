import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
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
      backgroundColor: const Color(0xFFF8F9FA),
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
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
                  child: Text(
                    'Search for donors',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppConstants.darkTextColor,
                    ),
                  ),
                ),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search donors by name or location',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppConstants.primaryColor.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.grey,
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
                // Filter Options
                Row(
                  children: [
                    // Blood Type Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            hint: Text(
                              'Blood Group',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppConstants.primaryColor.withOpacity(0.7),
                            ),
                            value: _selectedBloodType,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'All Types',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
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
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Location Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            hint: Text(
                              'Location',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppConstants.primaryColor.withOpacity(0.7),
                            ),
                            value: _selectedLocation,
                            isExpanded: true,
                            items: _locations.map((location) {
                              return DropdownMenuItem<String>(
                                value: location,
                                child: Row(
                                  children: [
                                    Icon(
                                      location == 'Any Location' ? Icons.place_outlined : Icons.place,
                                      size: 16,
                                      color: location == 'Any Location' 
                                          ? Colors.grey[400]
                                          : AppConstants.primaryColor.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      location,
                                      style: TextStyle(
                                        fontWeight: location == 'Any Location' ? FontWeight.normal : FontWeight.w500,
                                        fontSize: 14,
                                        color: location == 'Any Location' ? Colors.grey[600] : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLocation = value;
                              });
                              _updateFilteredDonors();
                            },
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Available Toggle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _onlyAvailable = !_onlyAvailable;
                    });
                    _updateFilteredDonors();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: _onlyAvailable
                          ? Border.all(color: AppConstants.primaryColor, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _onlyAvailable
                                ? AppConstants.primaryColor
                                : Colors.grey[200],
                          ),
                          child: _onlyAvailable
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Donors Only',
                              style: TextStyle(
                                color: _onlyAvailable
                                    ? AppConstants.primaryColor
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Show donors who are ready to donate',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          Icons.person_outline,
                          color: _onlyAvailable
                              ? AppConstants.primaryColor
                              : Colors.grey[400],
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppConstants.darkTextColor,
                  ),
                ),
                if (_filteredDonors.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.sort, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Sort by',
                        style: TextStyle(
                          color: Colors.grey[600],
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 70,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No donors found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Try adjusting your filters or search with different keywords',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
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
      ),
    );
  }

  Widget _buildDonorCard(UserModel donor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
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
                                  color: Colors.grey.withOpacity(0.2),
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
                                  ? NetworkImage(donor.imageUrl)
                                  : null,
                              child: donor.imageUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: AppConstants.primaryColor,
                                      size: 32,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: donor.isAvailableToDonate
                                    ? AppConstants.successColor
                                    : Colors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (donor.isAvailableToDonate
                                            ? AppConstants.successColor
                                            : Colors.orange)
                                        .withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
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
                            const SizedBox(height: 8),
                            // Availability Status with Label
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
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
                          ],
                        ),
                      ),
                      // Blood Type Badge with enhanced visual
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor.withOpacity(0.2),
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
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
                  const SizedBox(height: 16),
                  // Contact Buttons with Visual Enhancements
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildContactButton(
                          text: 'Call Now',
                          icon: Icons.call_rounded,
                          color: const Color(0xFF4CAF50),
                          onPressed: () {
                            // Implement call functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Calling ${donor.name}'),
                                backgroundColor: AppConstants.successColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(10),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildContactButton(
                          text: 'Message',
                          icon: Icons.chat_rounded,
                          color: AppConstants.primaryColor,
                          outlined: false,
                          onPressed: () {
                            // Implement message functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Messaging ${donor.name}'),
                                backgroundColor: AppConstants.primaryColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(10),
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
          ),
        ),
      ),
    );
  }
  
  Widget _buildContactButton({
    required String text,
    required IconData icon,
    required Color color,
    bool outlined = true,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withOpacity(0.1),
        child: Ink(
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(12),
            border: outlined
                ? Border.all(color: color, width: 1.5)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: outlined ? color : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: outlined ? color : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 