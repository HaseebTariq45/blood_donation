import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';
import '../utils/theme_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late String _bloodType = 'A+';
  bool _isAvailableToDonate = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  
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
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validate form
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Passwords do not match!'),
            backgroundColor: AppConstants.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
        return;
      }
      
      // Create user model
      final newUser = UserModel(
        id: '', // Will be assigned by Firebase
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        bloodType: _bloodType,
        address: _addressController.text.trim(),
        isAvailableToDonate: _isAvailableToDonate,
      );
      
      // Get provider
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // Register user
      final success = await appProvider.registerUser(
        newUser, 
        _passwordController.text
      );
      
      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration successful!'),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
        
        // Navigate to login or home screen
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appProvider.authError),
            backgroundColor: AppConstants.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get app provider
    final appProvider = Provider.of<AppProvider>(context);
    final bool isAuthenticating = appProvider.isAuthenticating;
    
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;
    
    // Calculate responsive sizes
    final double headerIconSize = isSmallScreen ? 32.0 : 40.0;
    final double headerFontSize = isSmallScreen ? 16.0 : 18.0;
    final double sectionTitleFontSize = isSmallScreen ? 16.0 : 18.0;
    final double subtitleFontSize = isSmallScreen ? 12.0 : 14.0;
    final double formFontSize = isSmallScreen ? 14.0 : 16.0;
    final double buttonFontSize = isSmallScreen ? 14.0 : 16.0;
    final double bloodTypeFontSize = isSmallScreen ? 16.0 : 18.0;
    final double bloodTypeCheckSize = isSmallScreen ? 14.0 : 16.0;
    
    // Calculate padding based on screen size
    final double horizontalPadding = screenWidth * 0.05;
    final double verticalPadding = screenHeight * 0.015;
    final EdgeInsets standardPadding = EdgeInsets.all(horizontalPadding);
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor, size: isSmallScreen ? 22 : 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Account',
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        child: Builder(
                          builder: (context) => Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: verticalPadding * 2,
                              horizontal: horizontalPadding,
                            ),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: context.isDarkMode
                                      ? Colors.black.withOpacity(0.15)
                                      : Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person_add_rounded,
                                  size: headerIconSize,
                                  color: AppConstants.primaryColor,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Join our BloodLine community and help save lives',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: headerFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: context.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: verticalPadding * 2),
                      
                      // Personal Information
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                            ),
                            SizedBox(height: verticalPadding),
                            Text(
                              'Please fill in your details',
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: context.secondaryTextColor,
                              ),
                            ),
                            SizedBox(height: verticalPadding * 1.5),
                            
                            // Name Field
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.name,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                              fontSize: formFontSize,
                              isSmallScreen: isSmallScreen,
                              verticalPadding: verticalPadding,
                            ),
                            
                            // Email Field
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                              fontSize: formFontSize,
                              isSmallScreen: isSmallScreen,
                              verticalPadding: verticalPadding,
                            ),
                            
                            // Phone Field
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                              fontSize: formFontSize,
                              isSmallScreen: isSmallScreen,
                              verticalPadding: verticalPadding,
                            ),
                            
                            // Address Field
                            _buildTextField(
                              controller: _addressController,
                              label: 'Address',
                              icon: Icons.location_on_outlined,
                              keyboardType: TextInputType.streetAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your address';
                                }
                                return null;
                              },
                              fontSize: formFontSize,
                              isSmallScreen: isSmallScreen,
                              verticalPadding: verticalPadding,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: verticalPadding * 3),
                      
                      // Donation Information
                      FadeInUp(
                        duration: const Duration(milliseconds: 700),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Donation Information',
                              style: TextStyle(
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                            ),
                            SizedBox(height: verticalPadding),
                            
                            // Blood Type Selection
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(verticalPadding),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.isDarkMode
                                        ? Colors.black.withOpacity(0.15)
                                        : Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Blood Type',
                                    style: TextStyle(
                                      fontSize: bloodTypeFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: context.textColor,
                                    ),
                                  ),
                                  SizedBox(height: verticalPadding),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _bloodTypes.map((type) {
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _bloodType = type;
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: horizontalPadding * 0.6,
                                            vertical: verticalPadding * 0.8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _bloodType == type
                                                ? AppConstants.primaryColor
                                                : context.cardColor,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: _bloodType == type
                                                  ? AppConstants.primaryColor
                                                  : context.secondaryTextColor.withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                            boxShadow: _bloodType == type
                                                ? [
                                                    BoxShadow(
                                                      color: AppConstants.primaryColor.withOpacity(0.2),
                                                      spreadRadius: 1,
                                                      blurRadius: 5,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: Text(
                                            type,
                                            style: TextStyle(
                                              fontSize: bloodTypeCheckSize,
                                              color: _bloodType == type
                                                  ? Colors.white
                                                  : context.secondaryTextColor,
                                              fontWeight: _bloodType == type
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: verticalPadding * 1.5),
                            
                            // Donation Availability
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(verticalPadding),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.isDarkMode
                                        ? Colors.black.withOpacity(0.15)
                                        : Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Available to donate blood',
                                      style: TextStyle(
                                        fontSize: bloodTypeCheckSize,
                                        color: context.textColor,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _isAvailableToDonate,
                                    onChanged: (value) {
                                      setState(() {
                                        _isAvailableToDonate = value;
                                      });
                                    },
                                    activeColor: AppConstants.primaryColor,
                                    activeTrackColor: AppConstants.primaryColor.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: verticalPadding * 3),
                      
                      // Password
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security',
                              style: TextStyle(
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                            ),
                            SizedBox(height: verticalPadding),
                            Text(
                              'Choose a strong password',
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: context.secondaryTextColor,
                              ),
                            ),
                            SizedBox(height: verticalPadding * 1.5),
                            
                            // Password Field
                            _buildPasswordField(
                              controller: _passwordController,
                              label: 'Password',
                              isObscure: _obscurePassword,
                              toggleObscure: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                              fontSize: formFontSize,
                              isSmallScreen: isSmallScreen,
                              verticalPadding: verticalPadding,
                            ),
                            
                            // Confirm Password Field
                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              isObscure: _obscureConfirmPassword,
                              toggleObscure: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              fontSize: formFontSize,
                              isSmallScreen: isSmallScreen,
                              verticalPadding: verticalPadding,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: verticalPadding * 4),
                      
                      // Signup Button
                      FadeInUp(
                        duration: const Duration(milliseconds: 900),
                        child: SizedBox(
                          width: double.infinity,
                          child: isAuthenticating
                              ? Center(
                                  child: SizedBox(
                                    width: isSmallScreen ? 30 : 40,
                                    height: isSmallScreen ? 30 : 40,
                                    child: const CircularProgressIndicator(),
                                  ),
                                )
                              : CustomButton(
                                  text: 'CREATE ACCOUNT',
                                  onPressed: _register,
                                  fontSize: buttonFontSize,
                                  height: isSmallScreen ? 50 : 56,
                                ),
                        ),
                      ),
                      
                      SizedBox(height: verticalPadding),
                      
                      // Login Link
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                  color: context.secondaryTextColor,
                                  fontSize: subtitleFontSize,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Login',
                                    style: TextStyle(
                                      color: AppConstants.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: subtitleFontSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: verticalPadding * 2),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
    required double fontSize,
    required bool isSmallScreen,
    required double verticalPadding,
  }) {
    return Builder(
      builder: (context) => Container(
        margin: EdgeInsets.only(bottom: verticalPadding),
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
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? fontSize - 2 : fontSize,
            ),
            prefixIcon: Container(
              margin: EdgeInsets.all(isSmallScreen ? 8 : 12),
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppConstants.primaryColor,
                size: isSmallScreen ? 18 : 20,
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
          ),
          validator: validator,
        ),
      ),
    );
  }
  
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback toggleObscure,
    required String? Function(String?) validator,
    required double fontSize,
    required bool isSmallScreen,
    required double verticalPadding,
  }) {
    return Builder(
      builder: (context) => Container(
        margin: EdgeInsets.only(bottom: verticalPadding),
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
          obscureText: isObscure,
          decoration: InputDecoration(
            labelText: label,
            floatingLabelStyle: TextStyle(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? fontSize - 2 : fontSize,
            ),
            prefixIcon: Container(
              margin: EdgeInsets.all(isSmallScreen ? 8 : 12),
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.lock_outline,
                color: AppConstants.primaryColor,
                size: isSmallScreen ? 18 : 20,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
                size: isSmallScreen ? 18 : 20,
              ),
              onPressed: toggleObscure,
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
          ),
          validator: validator,
        ),
      ),
    );
  }
} 