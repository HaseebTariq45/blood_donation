import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';
import '../utils/theme_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
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
  
  // List of available blood types
  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
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
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUser;
    
    _nameController = TextEditingController(text: currentUser.name);
    _emailController = TextEditingController(text: currentUser.email);
    _phoneController = TextEditingController(text: currentUser.phone);
    _addressController = TextEditingController(text: currentUser.address);
    _bloodType = currentUser.bloodType;
    _isAvailableToDonate = currentUser.isAvailableToDonate;
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
        phone: _phoneController.text,
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
            content: const Text('Profile updated successfully'),
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
      _phoneController.text = currentUser.phone;
      _addressController.text = currentUser.address;
      _bloodType = currentUser.bloodType;
      _isAvailableToDonate = currentUser.isAvailableToDonate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUser = appProvider.currentUser;
    
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: CustomAppBar(
          title: 'My Profile',
          showProfilePicture: false,
          actions: [
            // Settings icon
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: IconButton(
                key: ValueKey<bool>(_isEditing),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                tooltip: _isEditing ? 'Cancel Editing' : 'Edit Profile',
                onPressed: () {
                  if (_isEditing) {
                    // Show confirmation dialog if there are unsaved changes
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: Theme.of(dialogContext).cardColor,
                        title: Text(
                          'Discard Changes?',
                          style: TextStyle(color: Theme.of(dialogContext).textTheme.titleLarge?.color),
                        ),
                        content: Text(
                          'Any unsaved changes will be lost. Do you want to continue?',
                          style: TextStyle(color: Theme.of(dialogContext).textTheme.bodyMedium?.color),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('KEEP EDITING'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              // Reset to original values and exit edit mode
                              _resetFormValues();
                              setState(() {
                                _isEditing = false;
                              });
                            },
                            child: const Text('DISCARD'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    _toggleEdit();
                  }
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _isEditing ? FloatingActionButton(
          onPressed: _saveProfile,
          backgroundColor: AppConstants.primaryColor,
          child: _isLoading 
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save),
          tooltip: 'Save Profile',
        ) : null,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Builder(
                      builder: (context) => Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: context.isDarkMode 
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          constraints.maxWidth * 0.05,
                          constraints.maxHeight * 0.05,
                          constraints.maxWidth * 0.05,
                          constraints.maxHeight * 0.1,
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: context.isDarkMode
                                            ? Colors.black.withOpacity(0.3)
                                            : Colors.grey.withOpacity(0.2),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: constraints.maxWidth * 0.15,
                                    backgroundColor: context.isDarkMode 
                                        ? const Color(0xFF2E2E2E) 
                                        : AppConstants.accentColor,
                                    backgroundImage: currentUser.imageUrl.isNotEmpty
                                        ? NetworkImage(currentUser.imageUrl)
                                        : null,
                                    child: currentUser.imageUrl.isEmpty
                                        ? Icon(
                                            Icons.person,
                                            color: AppConstants.primaryColor,
                                            size: constraints.maxWidth * 0.15,
                                          )
                                        : null,
                                  ),
                                ),
                                if (_isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(constraints.maxWidth * 0.02),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: context.cardColor,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppConstants.primaryColor.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            FittedBox(
                              child: Text(
                                _isEditing ? 'Edit Profile' : currentUser.name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                              ),
                            ),
                            if (!_isEditing) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: MediaQuery.of(context).size.width * 0.03,
                                        vertical: MediaQuery.of(context).size.height * 0.01,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryColor,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppConstants.primaryColor.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.bloodtype,
                                              color: Colors.white,
                                              size: MediaQuery.of(context).size.width * 0.035,
                                            ),
                                          ),
                                          SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                                          FittedBox(
                                            child: Text(
                                              currentUser.bloodType,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: MediaQuery.of(context).size.width * 0.04,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                                  Flexible(
                                    flex: 2,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: MediaQuery.of(context).size.width * 0.03,
                                        vertical: MediaQuery.of(context).size.height * 0.01,
                                      ),
                                      decoration: BoxDecoration(
                                        color: currentUser.isEligibleToDonate
                                            ? AppConstants.successColor
                                            : Colors.orange,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (currentUser.isEligibleToDonate
                                                    ? AppConstants.successColor
                                                    : Colors.orange)
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              currentUser.isEligibleToDonate
                                                  ? Icons.check_circle
                                                  : Icons.timer,
                                              color: Colors.white,
                                              size: MediaQuery.of(context).size.width * 0.035,
                                            ),
                                          ),
                                          SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                                          Flexible(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                currentUser.isEligibleToDonate
                                                    ? 'Eligible to Donate'
                                                    : '${currentUser.daysUntilNextDonation} days to donate',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: MediaQuery.of(context).size.width * 0.035,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(constraints.maxWidth * 0.05),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: constraints.maxWidth * 0.01, bottom: constraints.maxHeight * 0.02),
                              child: Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                              ),
                            ),
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
                            const SizedBox(height: 20),
                            if (_isEditing) ...[
                              Builder(
                                builder: (context) => Padding(
                                  padding: EdgeInsets.only(left: constraints.maxWidth * 0.01, bottom: constraints.maxHeight * 0.02),
                                  child: Text(
                                    'Blood Type',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.textColor,
                                    ),
                                  ),
                                ),
                              ),
                              _buildBloodTypeGrid(),
                            ] else
                              _buildInfoField(
                                label: 'Blood Type',
                                value: currentUser.bloodType,
                                icon: Icons.bloodtype_outlined,
                                color: AppConstants.primaryColor,
                              ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: EdgeInsets.only(left: constraints.maxWidth * 0.01, bottom: constraints.maxHeight * 0.02),
                              child: Text(
                                'Donation Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                              ),
                            ),
                            Builder(
                              builder: (context) => Container(
                                padding: EdgeInsets.all(constraints.maxWidth * 0.05),
                                decoration: BoxDecoration(
                                  color: context.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.isDarkMode 
                                          ? Colors.black.withOpacity(0.1) 
                                          : Colors.grey.withOpacity(0.07),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  border: _isAvailableToDonate
                                      ? Border.all(
                                          color: AppConstants.successColor.withOpacity(0.5),
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(constraints.maxWidth * 0.03),
                                      decoration: BoxDecoration(
                                        color: _isAvailableToDonate
                                            ? AppConstants.successColor.withOpacity(0.1)
                                            : AppConstants.primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.volunteer_activism,
                                        color: _isAvailableToDonate
                                            ? AppConstants.successColor
                                            : AppConstants.primaryColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Available to Donate',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: _isAvailableToDonate
                                                  ? AppConstants.successColor
                                                  : context.textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Let others know if you are available for blood donation requests',
                                            style: TextStyle(
                                              color: context.secondaryTextColor,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: _isAvailableToDonate,
                                      onChanged: (value) {
                                        setState(() {
                                          _isAvailableToDonate = value;
                                        });
                                        final appProvider = Provider.of<AppProvider>(context, listen: false);
                                        final currentUser = appProvider.currentUser;
                                        final updatedUser = currentUser.copyWith(
                                          isAvailableToDonate: value,
                                        );
                                        appProvider.updateUserProfile(updatedUser);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              value 
                                                  ? 'You are now available for donation requests' 
                                                  : 'You are now marked as unavailable for donation',
                                            ),
                                            backgroundColor: value 
                                                ? AppConstants.successColor 
                                                : AppConstants.primaryColor,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            margin: const EdgeInsets.all(10),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      activeColor: AppConstants.successColor,
                                      activeTrackColor: AppConstants.successColor.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),
                            if (_isEditing)
                              SizedBox(
                                width: double.infinity,
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : ElevatedButton.icon(
                                        onPressed: _saveProfile,
                                        icon: const Icon(Icons.save_rounded),
                                        label: const Text(
                                          'SAVE DETAILS',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppConstants.primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.02),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                        ),
                                      ),
                              ),
                            if (!_isEditing) ...[
                              const SizedBox(height: 20),
                              Builder(
                                builder: (context) => SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _toggleEdit,
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text(
                                      'EDIT DETAILS',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.cardColor,
                                      foregroundColor: AppConstants.primaryColor,
                                      padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.02),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: AppConstants.primaryColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (!_isEditing)
                              Builder(
                                builder: (context) => SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _showLogoutConfirmation();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.red.withOpacity(0.7), width: 1.5),
                                      padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.02),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      foregroundColor: Colors.red,
                                      backgroundColor: context.cardColor,
                                    ),
                                    child: const Text(
                                      'LOGOUT',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  // Show confirmation dialog before logout
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).cardColor,
        title: Text(
          'Logout',
          style: TextStyle(color: Theme.of(dialogContext).textTheme.titleLarge?.color),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Theme.of(dialogContext).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Perform logout action
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              appProvider.logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('LOGOUT'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // Build a grid of blood type options
  Widget _buildBloodTypeGrid() {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (MediaQuery.of(context).size.width ~/ 100).toInt(), // Adjusts number of columns based on width
            childAspectRatio: 1,
            crossAxisSpacing: MediaQuery.of(context).size.width * 0.02,
            mainAxisSpacing: MediaQuery.of(context).size.height * 0.02,
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
                      : context.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected 
                        ? AppConstants.primaryColor 
                        : context.isDarkMode
                            ? Colors.grey.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                          ? AppConstants.primaryColor.withOpacity(0.3) 
                          : context.isDarkMode
                              ? Colors.black.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.05),
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
                    FittedBox(
                      child: Text(
                        bloodType,
                        style: TextStyle(
                          color: isSelected ? Colors.white : context.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                        ),
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
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode
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
              color: readOnly ? context.secondaryTextColor : AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: readOnly 
                    ? context.isDarkMode
                        ? Colors.grey.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1)
                    : AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: readOnly ? Colors.grey : AppConstants.primaryColor,
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
                color: context.isDarkMode
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: AppConstants.primaryColor.withOpacity(0.5),
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
                color: Colors.red.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            fillColor: context.cardColor,
            filled: true,
          ),
          readOnly: readOnly,
          validator: validator,
          style: TextStyle(
            fontSize: 16,
            color: readOnly ? context.secondaryTextColor : context.textColor,
          ),
        ),
      ),
    );
  }

  // Build info field for display mode
  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode
                  ? Colors.black.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.07),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: color,
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