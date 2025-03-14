import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';
import '../utils/theme_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late String _bloodType;
  late bool _isAvailableToDonate;
  bool _isEditing = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _userId;
  String? _phoneNumber;
  String? _address;
  String? _lastDonationDate;
  String _healthStatus = 'Unknown';
  Color _healthStatusColor = Colors.green;
  String? _nextDonationDate;

  // Health Questionnaire Data
  String? _height;
  String? _weight;
  String? _gender;
  bool _hasTattoo = false;
  bool _hasPiercing = false;
  bool _hasTraveled = false;
  bool _hasSurgery = false;
  bool _hasTransfusion = false;
  bool _hasPregnancy = false;
  bool _hasDisease = false;
  bool _hasMedication = false;
  bool _hasAllergies = false;
  String? _medications;
  String? _allergies;

  // List of available blood types
  final List<String> _bloodTypes = [
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
    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUser;

    _nameController = TextEditingController(text: currentUser.name);
    _emailController = TextEditingController(text: currentUser.email);
    _phoneController = TextEditingController(text: currentUser.phoneNumber);
    _addressController = TextEditingController(text: currentUser.address);
    _bloodType = currentUser.bloodType;
    _isAvailableToDonate = currentUser.isAvailableToDonate;
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userId = user.uid;
        
        // Load user profile data
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          
          // Update controllers with null safety
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _addressController.text = data['address'] ?? '';
          
          // Update other fields with null safety
          _bloodType = data['bloodType'] ?? 'Unknown';
          _phoneNumber = data['phoneNumber'];
          _address = data['address'];
          _isAvailableToDonate = data['isAvailableToDonate'] ?? true;
          
          // Handle lastDonationDate with better null safety
          if (data['lastDonationDate'] != null) {
            try {
              if (data['lastDonationDate'] is Timestamp) {
                _lastDonationDate = (data['lastDonationDate'] as Timestamp).toDate().millisecondsSinceEpoch.toString();
              } else if (data['lastDonationDate'] is int) {
              _lastDonationDate = data['lastDonationDate'].toString();
              } else if (data['lastDonationDate'] is String) {
              _lastDonationDate = data['lastDonationDate'];
              }
            } catch (e) {
              print('Error parsing lastDonationDate: $e');
              _lastDonationDate = null;
            }
          }
        }

        // Load health questionnaire data with null safety
        final healthDoc = await FirebaseFirestore.instance
            .collection('health_questionnaires')
            .doc(_userId)
            .get();

        if (healthDoc.exists) {
          final healthData = healthDoc.data()!;
          setState(() {
            _height = healthData['height']?.toString() ?? '';
            _weight = healthData['weight']?.toString() ?? '';
            _gender = healthData['gender'] ?? '';
          _hasTattoo = healthData['hasTattoo'] ?? false;
          _hasPiercing = healthData['hasPiercing'] ?? false;
          _hasTraveled = healthData['hasTraveled'] ?? false;
          _hasSurgery = healthData['hasSurgery'] ?? false;
          _hasTransfusion = healthData['hasTransfusion'] ?? false;
          _hasPregnancy = healthData['hasPregnancy'] ?? false;
          _hasDisease = healthData['hasDisease'] ?? false;
          _hasMedication = healthData['hasMedication'] ?? false;
          _hasAllergies = healthData['hasAllergies'] ?? false;
            _medications = healthData['medications']?.toString() ?? '';
            _allergies = healthData['allergies']?.toString() ?? '';
          });
        }

        _updateHealthStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile data: $e'),
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

  void _updateHealthStatus() {
    if (_hasDisease || _hasMedication || _hasAllergies) {
      _healthStatus = 'Needs Review';
      _healthStatusColor = Colors.orange;
    } else if (_hasTattoo || _hasPiercing || _hasTraveled || _hasSurgery || _hasTransfusion || _hasPregnancy) {
      _healthStatus = 'Temporary Deferral';
      _healthStatusColor = Colors.red;
    } else {
      _healthStatus = 'Good';
      _healthStatusColor = Colors.green;
    }

    if (_lastDonationDate != null && _lastDonationDate!.isNotEmpty) {
      try {
      DateTime lastDonation;
      
        // Handle different types of lastDonationDate
        if (int.tryParse(_lastDonationDate!) != null) {
          // If it's a timestamp (milliseconds since epoch)
          lastDonation = DateTime.fromMillisecondsSinceEpoch(int.parse(_lastDonationDate!));
      } else {
          // If it's a date string
          lastDonation = DateTime.parse(_lastDonationDate!);
      }
      
      final nextDonation = lastDonation.add(const Duration(days: 56));
      _nextDonationDate = nextDonation.toString().split(' ')[0];
      } catch (e) {
        print('Error calculating next donation date: $e');
        _nextDonationDate = null;
      }
    } else {
      _nextDonationDate = null;
    }
  }

  // Toggle edit mode and play animation
  void _toggleEdit() {
    setState(() {
      _isEditing = true;
    });

    // Subtle animation when entering edit mode
    _animationController.reset();
    _animationController.forward();

    // Show edit mode indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile is now in edit mode'),
        backgroundColor: AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // Handle profile save - currently just UI with no save logic
  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUser = appProvider.currentUser;

      final updatedUser = currentUser.copyWith(
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        bloodType: _bloodType,
        isAvailableToDonate: _isAvailableToDonate,
      );

      // Simulate network delay
      Future.delayed(const Duration(milliseconds: 800), () {
        // Note: In a real implementation, we would save the data to a database or API here
        // For now, we just update the local state
        appProvider.updateUserProfile(updatedUser);

        setState(() {
          _isLoading = false;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Profile updated successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
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
    }
  }

  // Reset form values to current user data
  void _resetFormValues() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUser;

    setState(() {
      _nameController.text = currentUser.name;
      _emailController.text = currentUser.email;
      _phoneController.text = currentUser.phoneNumber;
      _addressController.text = currentUser.address;
      _bloodType = currentUser.bloodType;
      _isAvailableToDonate = currentUser.isAvailableToDonate;
    });
  }

  // Show confirmation dialog before logout
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout from your account?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle logout
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              appProvider.logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'LOGOUT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUser = appProvider.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
        title: _isEditing ? 'Edit Profile' : 'My Profile',
          actions: [
            IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Colors.white,
            ),
            tooltip: 'Settings',
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
          opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _loadUserData,
                color: AppConstants.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                      // Profile Header with Avatar and Blood Type
                      Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppConstants.primaryColor,
                              AppConstants.primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                              boxShadow: [
                                BoxShadow(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                                  blurRadius: 10,
                              spreadRadius: 2,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                            child: Column(
                              children: [
                            // Avatar with Edit Button
                                Stack(
                              alignment: Alignment.center,
                                  children: [
                                // Outer decorative circle
                                    Container(
                                  width: 150,
                                  height: 150,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                // Avatar
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                    image: currentUser.imageUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(currentUser.imageUrl),
                                            fit: BoxFit.cover,
                                                )
                                                : null,
                                  ),
                                  child: currentUser.imageUrl.isEmpty
                                                ? Icon(
                                                  Icons.person,
                                          color: AppConstants.primaryColor,
                                          size: 80,
                                                )
                                                : null,
                                      ),
                                // Blood type badge
                                      Positioned(
                                  top: 0,
                                        right: 0,
                                        child: Container(
                                    padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                      color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 5,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                  child: Text(
                                      _bloodType,
                                    style: TextStyle(
                                        color: AppConstants.primaryColor,
                                      fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                    ),
                                  ),
                                ),
                                ),
                                // Edit button
                                if (_isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 20,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 5,
                                                spreadRadius: 1,
                                          ),
                                        ],
                                                ),
                                                child: Icon(
                                        Icons.camera_alt,
                                        color: AppConstants.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // User Name
                            Text(
                              currentUser.name,
                              style: const TextStyle(
                                                    color: Colors.white,
                                fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Donation Status
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                  Icon(
                                                  currentUser.isEligibleToDonate
                                                      ? Icons.check_circle
                                        : Icons.timelapse,
                                                  color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    currentUser.isEligibleToDonate
                                                        ? 'Eligible to Donate'
                                        : '${currentUser.daysUntilNextDonation} days until eligible',
                                    style: const TextStyle(
                                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                      
                      // Quick Stats
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            _buildStatCard(
                              icon: Icons.calendar_today,
                              title: 'Last Donation',
                              value: _lastDonationDate != null && _lastDonationDate!.isNotEmpty
                                  ? _formatDate(_lastDonationDate!)
                                  : 'Never',
                            ),
                            _buildStatCard(
                              icon: Icons.health_and_safety,
                              title: 'Health Status',
                              value: _healthStatus,
                              color: _healthStatusColor,
                            ),
                              ],
                            ),
                          ),
                      
                      // Profile Form
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              // Section Divider
                              _buildSectionHeader('Personal Information'),
                              
                              // Personal Info Fields
                            _buildFormField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              readOnly: !_isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            _buildFormField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: !_isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            _buildFormField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              readOnly: !_isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                            ),
                            _buildFormField(
                              controller: _addressController,
                              label: 'Address',
                              icon: Icons.location_on_outlined,
                              readOnly: !_isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your address';
                                }
                                return null;
                              },
                            ),
                              
                              // Blood Type Section
                            if (_isEditing) ...[
                                _buildSectionHeader('Blood Type'),
                              _buildBloodTypeGrid(),
                              ],
                              
                              // Health Information
                              _buildSectionHeader('Health Information'),
                            _buildHealthStatusCard(),
                              
                              const SizedBox(height: 30),
                              
                              // Action Buttons
                            if (_isEditing)
                                _buildActionButton(
                                          onPressed: _saveProfile,
                                  icon: Icons.save,
                                  label: 'SAVE PROFILE',
                                  isLoading: _isLoading,
                                  color: AppConstants.primaryColor,
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        onPressed: _toggleEdit,
                                        icon: Icons.edit,
                                        label: 'EDIT PROFILE',
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildActionButton(
                                        onPressed: () async {
                                          await Navigator.pushNamed(context, '/health-questionnaire');
                                          // Refresh data when returning from health questionnaire
                                          _loadUserData();
                                        },
                                        icon: Icons.medical_information,
                                        label: 'HEALTH DETAILS',
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                                
                              // Logout button (only shown when not editing)
                            if (!_isEditing) ...[
                              const SizedBox(height: 20),
                                _buildActionButton(
                                  onPressed: _showLogoutConfirmation,
                                  icon: Icons.logout,
                                  label: 'LOGOUT',
                                  color: Colors.redAccent,
                                ),
                              ],
                                
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Helper method to format date strings
  String _formatDate(String dateString) {
    try {
      DateTime date;
      
      if (int.tryParse(dateString) != null) {
        date = DateTime.fromMillisecondsSinceEpoch(int.parse(dateString));
      } else {
        date = DateTime.parse(dateString);
      }
      
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Stats card widget
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    Color? color,
  }) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                color: color ?? AppConstants.primaryColor,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                                          style: TextStyle(
                  color: color ?? AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
            ],
                                      ),
                                    ),
                              ),
    );
  }

  // Section header widget
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ],
      ),
    );
  }

  // Action button widget
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isLoading = false,
    Color? color,
  }) {
    final buttonColor = color ?? AppConstants.primaryColor;
    final textColor = Colors.white; // Ensuring text is always white for better contrast
    
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 4,
        disabledBackgroundColor: buttonColor.withOpacity(0.6), // Better disabled state
        disabledForegroundColor: textColor.withOpacity(0.6),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: textColor,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor),
                const SizedBox(width: 8),
                Text(
                  label,
              style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: textColor,
                  ),
              ),
            ],
          ),
    );
  }

  // Build a grid of blood type options
  Widget _buildBloodTypeGrid() {
    return Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: (MediaQuery.of(context).size.width ~/ 100).toInt(), // Adjusts number of columns based on width
                childAspectRatio: 1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
              ),
              itemCount: _bloodTypes.length,
              itemBuilder: (context, index) {
                final bloodType = _bloodTypes[index];
                final isSelected = _bloodType == bloodType;

                // Individual blood type card
                return GestureDetector(
                  onTap: () {
                    // Update selected blood type when tapped
                    setState(() {
                      _bloodType = bloodType;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                color: isSelected 
                              ? AppConstants.primaryColor
                  : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                  color: isSelected 
                                ? AppConstants.primaryColor
                    : Colors.grey.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                    color: isSelected 
                                  ? AppConstants.primaryColor.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Blood type display
                  Text(
                            bloodType,
                            style: TextStyle(
                      color: isSelected 
                        ? Colors.white 
                        : AppConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                      fontSize: 18,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 5),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
          ),
    );
  }

  // Build form field with custom styling
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppConstants.primaryColor;
    final labelColor = readOnly ? Colors.grey : primaryColor;
    
    return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
            color: isDarkMode 
                          ? Colors.black.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.07),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: label,
                floatingLabelStyle: TextStyle(
            color: labelColor,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
              color: readOnly
                  ? Colors.grey.withOpacity(0.1)
                  : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
              color: readOnly ? Colors.grey : primaryColor,
                    size: 20,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
              color: isDarkMode
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
              color: primaryColor.withOpacity(0.7),
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: Colors.red.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
              color: Colors.red.withOpacity(0.7),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
          fillColor: Theme.of(context).cardColor,
                filled: true,
              ),
              readOnly: readOnly,
              validator: validator,
              style: TextStyle(
                fontSize: 16,
          color: readOnly ? Colors.grey : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
    );
  }

  Widget _buildHealthStatusCard() {
    // Handle null values for height, weight, and gender
    final displayHeight = (_height == null || _height!.isEmpty || _height == 'null') 
        ? 'Not specified' 
        : "$_height cm";
        
    final displayWeight = (_weight == null || _weight!.isEmpty || _weight == 'null') 
        ? 'Not specified' 
        : "$_weight kg";
        
    final displayGender = (_gender == null || _gender!.isEmpty) 
        ? 'Not specified' 
        : _gender!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health Status Indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _healthStatusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _healthStatusColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _healthStatus == 'Good' ? Icons.check_circle : 
                      _healthStatus == 'Needs Review' ? Icons.warning : Icons.error,
                      color: _healthStatusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: $_healthStatus',
                          style: TextStyle(
                            color: _healthStatusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (_nextDonationDate != null)
                          Text(
                            'Next Eligible Donation: $_nextDonationDate',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Health Details
            const SizedBox(height: 20),
            
            // Basic Health Info
            _buildHealthInfoRow(
              icon: Icons.height,
              title: 'Height',
              value: displayHeight,
            ),
            _buildHealthInfoRow(
              icon: Icons.monitor_weight,
              title: 'Weight',
              value: displayWeight,
            ),
            _buildHealthInfoRow(
              icon: Icons.person,
              title: 'Gender',
              value: displayGender,
            ),
            
            // Divider
            Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.grey.withOpacity(0.3)),
            ),
            
            // Health Conditions
            Text(
              'Health Conditions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            // Conditions Grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildConditionChip('Tattoo', _hasTattoo),
                _buildConditionChip('Piercing', _hasPiercing),
                _buildConditionChip('Travel', _hasTraveled),
                _buildConditionChip('Surgery', _hasSurgery),
                _buildConditionChip('Transfusion', _hasTransfusion),
                _buildConditionChip('Pregnancy', _hasPregnancy),
                _buildConditionChip('Disease', _hasDisease),
                _buildConditionChip('Medication', _hasMedication),
                _buildConditionChip('Allergies', _hasAllergies),
              ],
            ),
            
            // Additional Info
            if (_hasMedication && _medications != null && _medications!.isNotEmpty) 
              _buildNoteSection('Medications', _medications!),
              
            if (_hasAllergies && _allergies != null && _allergies!.isNotEmpty) 
              _buildNoteSection('Allergies', _allergies!),
          ],
        ),
      ),
    );
  }

  // Health info row with icon
  Widget _buildHealthInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  // Condition chip (Yes/No indicators)
  Widget _buildConditionChip(String label, bool value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value 
            ? Colors.red.withOpacity(0.1) 
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.circle : Icons.check_circle,
            size: 16,
            color: value ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: value ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
  
  // For displaying multi-line notes
  Widget _buildNoteSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
