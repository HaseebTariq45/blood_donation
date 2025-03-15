import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/cities_data.dart';
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
  late String _city;
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
    _city = currentUser.city.isNotEmpty ? currentUser.city : 'Karachi';
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
        final userDoc =
            await FirebaseFirestore.instance
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
          _city = data['city'] ?? 'Karachi';
          _phoneNumber = data['phoneNumber'];
          _address = data['address'];
          _isAvailableToDonate = data['isAvailableToDonate'] ?? true;

          // Handle lastDonationDate with better null safety
          if (data['lastDonationDate'] != null) {
            try {
              if (data['lastDonationDate'] is Timestamp) {
                _lastDonationDate =
                    (data['lastDonationDate'] as Timestamp)
                        .toDate()
                        .millisecondsSinceEpoch
                        .toString();
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
        final healthDoc =
            await FirebaseFirestore.instance
                .collection('health_questionnaires')
                .doc(_userId)
                .get();

        if (healthDoc.exists) {
          final data = healthDoc.data()!;

          setState(() {
            _height = data['height']?.toString();
            _weight = data['weight']?.toString();
            _gender = data['gender'];
            _hasTattoo = data['hasTattoo'] ?? false;
            _hasPiercing = data['hasPiercing'] ?? false;
            _hasTraveled = data['hasTraveled'] ?? false;
            _hasSurgery = data['hasSurgery'] ?? false;
            _hasTransfusion = data['hasTransfusion'] ?? false;
            _hasPregnancy = data['hasPregnancy'] ?? false;
            _hasDisease = data['hasDisease'] ?? false;
            _hasMedication = data['hasMedication'] ?? false;
            _hasAllergies = data['hasAllergies'] ?? false;
            _medications = data['medications'];
            _allergies = data['allergies'];

            // Determine health status
            _determineHealthStatus();
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Determine health status based on questionnaire data
  void _determineHealthStatus() {
    bool hasRiskFactors =
        _hasTattoo ||
        _hasPiercing ||
        _hasTraveled ||
        _hasSurgery ||
        _hasTransfusion ||
        _hasPregnancy ||
        _hasDisease ||
        _hasMedication ||
        _hasAllergies;

    if (hasRiskFactors) {
      if (_hasTattoo || _hasPiercing) {
        _healthStatus = 'Possible Temp. Delay';
        _healthStatusColor = Colors.orange;
      } else if (_hasDisease || _hasTransfusion) {
        _healthStatus = 'Possible Permanent Deferral';
        _healthStatusColor = Colors.red.shade700;
      } else {
        _healthStatus = 'Needs Review';
        _healthStatusColor = Colors.blue.shade600;
      }
    } else {
      _healthStatus = 'Eligible';
      _healthStatusColor = Colors.green;
    }
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Cancel editing - reset values
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final currentUser = appProvider.currentUser;

        _nameController.text = currentUser.name;
        _phoneController.text = currentUser.phoneNumber;
        _addressController.text = currentUser.address;
        _bloodType = currentUser.bloodType;
        _city = currentUser.city;
        _isAvailableToDonate = currentUser.isAvailableToDonate;
      }
      _isEditing = !_isEditing;
    });
  }

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
        city: _city,
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

  // City Dropdown
  Widget _buildCityDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'City',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: _city,
              onChanged:
                  _isEditing
                      ? (newValue) {
                        setState(() {
                          _city = newValue!;
                        });
                      }
                      : null,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                hintText: 'Select city',
                hintStyle: TextStyle(color: Theme.of(context).hintColor),
              ),
              items:
                  PakistanCities.cities.map((String city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 16,
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color:
                    _isEditing
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).disabledColor,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your city';
                }
                return null;
              },
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
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body:
          _isLoading
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
                        // Profile Header with Avatar
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
                                color: AppConstants.primaryColor.withOpacity(
                                  0.3,
                                ),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            children: [
                              Stack(
                                children: [
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
                                      image:
                                          currentUser.imageUrl.isNotEmpty
                                              ? DecorationImage(
                                                image: NetworkImage(
                                                  currentUser.imageUrl,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                              : null,
                                    ),
                                    child:
                                        currentUser.imageUrl.isEmpty
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
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 5,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        currentUser.bloodType,
                                        style: TextStyle(
                                          color: AppConstants.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
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
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      currentUser.isAvailableToDonate
                                          ? Colors.green
                                          : Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  currentUser.isAvailableToDonate
                                      ? 'Available to Donate'
                                      : 'Not Available to Donate',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Main content body
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child:
                              _isEditing
                                  ? _buildEditForm()
                                  : _buildProfileInfo(currentUser),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      floatingActionButton:
          !_isEditing
              ? FloatingActionButton(
                onPressed: _toggleEdit,
                backgroundColor: AppConstants.primaryColor,
                child: const Icon(Icons.edit, color: Colors.white),
              )
              : null,
    );
  }

  // Build formatted text input
  Widget _buildTextInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isRequired = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        style: TextStyle(
          color:
              readOnly
                  ? Colors.grey
                  : Theme.of(context).textTheme.bodyMedium?.color,
        ),
        validator:
            isRequired
                ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your $label';
                  }
                  return null;
                }
                : null,
      ),
    );
  }

  // Build blood type selector
  Widget _buildBloodTypeSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blood Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: _bloodType,
              onChanged:
                  _isEditing
                      ? (newValue) {
                        setState(() {
                          _bloodType = newValue!;
                        });
                      }
                      : null,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              items:
                  _bloodTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your blood type';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  // Profile Edit Form
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextInput(
            'Name',
            _nameController,
            Icons.person_outline,
            isRequired: true,
          ),
          _buildTextInput(
            'Email',
            _emailController,
            Icons.email_outlined,
            readOnly: true,
          ),
          _buildTextInput(
            'Phone',
            _phoneController,
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            isRequired: true,
          ),
          _buildTextInput(
            'Address',
            _addressController,
            Icons.home_outlined,
            isRequired: true,
            maxLines: 3,
          ),
          _buildCityDropdown(),
          _buildBloodTypeSelector(),

          // Donation availability switch
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Available to Donate',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                Switch(
                  value: _isAvailableToDonate,
                  onChanged:
                      _isEditing
                          ? (value) {
                            setState(() {
                              _isAvailableToDonate = value;
                            });
                          }
                          : null,
                  activeColor: AppConstants.primaryColor,
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: _isLoading ? null : _toggleEdit,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(_isEditing ? 'Cancel' : 'Edit Profile'),
              ),
              if (_isEditing)
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text('Save Changes'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Build the profile info section
  Widget _buildProfileInfo(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User information section
        _buildProfileInfoSection(user),

        const SizedBox(height: 24),

        // Health information section
        _buildHealthStatusCard(),

        // Donation history section if applicable
        if (user.lastDonationDate != null) ...[
          const SizedBox(height: 24),
          _buildDonationHistoryCard(),
        ],

        // Action buttons
        const SizedBox(height: 32),
        _buildActionButtons(),
      ],
    );
  }

  // Build a custom information section
  Widget _buildProfileInfoSection(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email_outlined, 'Email', user.email),
            const Divider(),
            _buildInfoRow(Icons.phone_outlined, 'Phone', user.phoneNumber),
            const Divider(),
            _buildInfoRow(Icons.home_outlined, 'Address', user.address),
            const Divider(),
            _buildInfoRow(Icons.location_city, 'City', user.city),
            const Divider(),
            _buildInfoRow(
              Icons.bloodtype_outlined,
              'Blood Type',
              user.bloodType,
              valueColor: AppConstants.primaryColor,
              valueFontWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
    );
  }

  // Build health status card
  Widget _buildHealthStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Health status indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _healthStatusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _healthStatusColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    color: _healthStatusColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Donation Eligibility Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _healthStatus,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _healthStatusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Basic Health Info
            _buildInfoRow(Icons.height, 'Height', _height ?? 'Not provided'),
            _buildInfoRow(
              Icons.monitor_weight,
              'Weight',
              _weight ?? 'Not provided',
            ),
            _buildInfoRow(Icons.person, 'Gender', _gender ?? 'Not provided'),
          ],
        ),
      ),
    );
  }

  // Build donation history card
  Widget _buildDonationHistoryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Donation History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/donation_history');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Last donation info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Donation',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _lastDonationDate ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_nextDonationDate != null) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Next Eligible Donation Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_available,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _nextDonationDate!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build action buttons
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/donation_tracking');
          },
          icon: const Icon(Icons.bloodtype),
          label: const Text('My Donations'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/health_questionnaire');
          },
          icon: const Icon(Icons.health_and_safety),
          label: const Text('Update Health Information'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // Build info row with icon
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        valueColor ??
                        Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: valueFontWeight ?? FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
