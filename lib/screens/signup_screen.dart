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
  bool _isLoading = false;
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

  void _register() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate network delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        // BACKEND IMPLEMENTATION NOTE:
        // Here you would make an API call to register the user with the following data:
        // - name: _nameController.text
        // - email: _emailController.text
        // - phone: _phoneController.text
        // - address: _addressController.text
        // - password: _passwordController.text
        // - bloodType: _bloodType
        // - isAvailableToDonate: _isAvailableToDonate
        
        // For now, we just create a local user object and update the app state
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        
        // Create a new user with a unique ID (in real app, this would come from backend)
        final newUser = UserModel(
          id: 'user${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          bloodType: _bloodType,
          isAvailableToDonate: _isAvailableToDonate,
          // In a real app, the lastDonationDate would be collected or set to a default
          // Here we're setting it to 91 days ago so the user is eligible to donate
          lastDonationDate: DateTime.now().subtract(const Duration(days: 91)),
        );
        
        // Update app state with the new user
        appProvider.registerUser(newUser, _passwordController.text);
        
        setState(() {
          _isLoading = false;
        });
        
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
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 12 : 15),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_add_rounded,
                                    color: AppConstants.primaryColor,
                                    size: headerIconSize,
                                  ),
                                ),
                                SizedBox(height: verticalPadding),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Join the BloodLine Community',
                                    style: TextStyle(
                                      fontSize: headerFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: context.textColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: verticalPadding * 0.5),
                                Text(
                                  'Fill in your details to create your account',
                                  style: TextStyle(
                                    fontSize: subtitleFontSize,
                                    color: context.secondaryTextColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: verticalPadding * 1.5),
                      
                      // Personal Information
                      Padding(
                        padding: EdgeInsets.only(left: 4, bottom: verticalPadding),
                        child: Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: sectionTitleFontSize,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                      ),
                      
                      // Name Field
                      _buildFormField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        fontSize: formFontSize,
                        isSmallScreen: isSmallScreen,
                        verticalPadding: verticalPadding,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      
                      // Email Field
                      _buildFormField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        fontSize: formFontSize,
                        isSmallScreen: isSmallScreen,
                        verticalPadding: verticalPadding,
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
                      
                      // Phone Field
                      _buildFormField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        fontSize: formFontSize,
                        isSmallScreen: isSmallScreen,
                        verticalPadding: verticalPadding,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      
                      // Address Field
                      _buildFormField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on_outlined,
                        fontSize: formFontSize,
                        isSmallScreen: isSmallScreen,
                        verticalPadding: verticalPadding,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: verticalPadding * 1.5),
                      
                      // Blood Information
                      Padding(
                        padding: EdgeInsets.only(left: 4, bottom: verticalPadding * 0.8),
                        child: Text(
                          'Blood Information',
                          style: TextStyle(
                            fontSize: sectionTitleFontSize,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                      ),
                      
                      // Blood Type Selection
                      Padding(
                        padding: EdgeInsets.only(left: 4, bottom: verticalPadding * 0.5),
                        child: Text(
                          'Blood Type',
                          style: TextStyle(
                            fontSize: formFontSize,
                            fontWeight: FontWeight.w500,
                            color: context.textColor,
                          ),
                        ),
                      ),
                      
                      // Blood Type Grid
                      _buildBloodTypeGrid(
                        fontSize: bloodTypeFontSize, 
                        checkSize: bloodTypeCheckSize, 
                        isSmallScreen: isSmallScreen
                      ),
                      
                      SizedBox(height: verticalPadding * 1.2),
                      
                      // Availability Toggle
                      Builder(
                        builder: (context) => Container(
                          padding: EdgeInsets.all(horizontalPadding),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: context.isDarkMode
                                    ? Colors.black.withOpacity(0.15)
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
                                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
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
                                  size: isSmallScreen ? 20 : 24,
                                ),
                              ),
                              SizedBox(width: horizontalPadding * 0.8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Available to Donate',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: isSmallScreen ? 14 : 16,
                                        color: _isAvailableToDonate
                                            ? AppConstants.successColor
                                            : context.textColor,
                                      ),
                                    ),
                                    SizedBox(height: verticalPadding * 0.2),
                                    Text(
                                      'Let others know if you are available for blood donation requests',
                                      style: TextStyle(
                                        color: context.secondaryTextColor,
                                        fontSize: subtitleFontSize,
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
                                },
                                activeColor: AppConstants.successColor,
                                activeTrackColor: AppConstants.successColor.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: verticalPadding * 1.5),
                      
                      // Account Security
                      Padding(
                        padding: EdgeInsets.only(left: 4, bottom: verticalPadding),
                        child: Text(
                          'Account Security',
                          style: TextStyle(
                            fontSize: sectionTitleFontSize,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                      ),
                      
                      // Password Field
                      _buildPasswordField(
                        controller: _passwordController,
                        label: 'Password',
                        obscureText: _obscurePassword,
                        fontSize: formFontSize,
                        isSmallScreen: isSmallScreen,
                        verticalPadding: verticalPadding,
                        toggleVisibility: () {
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
                      ),
                      
                      // Confirm Password Field
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        obscureText: _obscureConfirmPassword,
                        fontSize: formFontSize,
                        isSmallScreen: isSmallScreen,
                        verticalPadding: verticalPadding,
                        toggleVisibility: () {
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
                      ),
                      
                      SizedBox(height: verticalPadding * 1.5),
                      
                      // Terms and Conditions Checkbox
                      Container(
                        margin: EdgeInsets.only(bottom: verticalPadding * 1.5),
                        child: Row(
                          children: [
                            // This is just a UI element for demonstration
                            // In a real app, you'd add the checkbox state
                            Container(
                              width: isSmallScreen ? 18 : 20,
                              height: isSmallScreen ? 18 : 20,
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: isSmallScreen ? 14 : 16,
                              ),
                            ),
                            SizedBox(width: horizontalPadding * 0.5),
                            Expanded(
                              child: Builder(
                                builder: (context) => RichText(
                                  text: TextSpan(
                                    text: 'I agree to the ',
                                    style: TextStyle(
                                      color: context.secondaryTextColor,
                                      fontSize: subtitleFontSize,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: TextStyle(
                                          color: AppConstants.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' and ',
                                      ),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: AppConstants.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        child: _isLoading
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
                      
                      SizedBox(height: verticalPadding),
                      
                      // Login Link
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: context.secondaryTextColor,
                                fontSize: subtitleFontSize,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed('/login');
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 4 : 8,
                                  vertical: isSmallScreen ? 2 : 4,
                                ),
                              ),
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: context.isDarkMode ? 
                                    AppConstants.primaryColor.withOpacity(0.9) : 
                                    AppConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: subtitleFontSize,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: verticalPadding * 1.5),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
  
  // Build a grid of blood type options
  Widget _buildBloodTypeGrid({
    required double fontSize,
    required double checkSize,
    required bool isSmallScreen
  }) {
    return Builder(
      builder: (context) => Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 15 : 20),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1,
            crossAxisSpacing: isSmallScreen ? 8 : 10,
            mainAxisSpacing: isSmallScreen ? 8 : 10,
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
                    Text(
                      bloodType,
                      style: TextStyle(
                        color: isSelected 
                            ? Colors.white 
                            : context.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                    ),
                    if (isSelected) ...[
                      SizedBox(height: isSmallScreen ? 3 : 5),
                      Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: checkSize,
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
    required double fontSize,
    required bool isSmallScreen,
    required double verticalPadding,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
            contentPadding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 14 : 16,
              horizontal: isSmallScreen ? 14 : 16,
            ),
            fillColor: context.cardColor,
            filled: true,
          ),
          validator: validator,
          style: TextStyle(
            fontSize: fontSize,
            color: context.textColor,
          ),
        ),
      ),
    );
  }

  // Build password field with custom styling
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required Function() toggleVisibility,
    required double fontSize,
    required bool isSmallScreen,
    required double verticalPadding,
    String? Function(String?)? validator,
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
          obscureText: obscureText,
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
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: context.secondaryTextColor,
                size: isSmallScreen ? 18 : 20,
              ),
              onPressed: toggleVisibility,
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
            contentPadding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 14 : 16,
              horizontal: isSmallScreen ? 14 : 16,
            ),
            fillColor: context.cardColor,
            filled: true,
          ),
          validator: validator,
          style: TextStyle(
            fontSize: fontSize,
            color: context.textColor,
          ),
        ),
      ),
    );
  }
} 