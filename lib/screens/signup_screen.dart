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
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Account',
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 30,
                      horizontal: 20,
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
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: AppConstants.primaryColor,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 15),
                          Text(
                          'Join the Blood Donation Community',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                              color: context.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                          Text(
                          'Fill in your details to create your account',
                          style: TextStyle(
                            fontSize: 14,
                              color: context.secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Personal Information
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 20),
                  child: Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 30),
                
                // Blood Information
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Text(
                    'Blood Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ),
                
                // Blood Type Selection
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Blood Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.textColor,
                    ),
                  ),
                ),
                
                // Blood Type Grid
                _buildBloodTypeGrid(),
                
                const SizedBox(height: 24),
                
                // Availability Toggle
                Builder(
                  builder: (context) => Container(
                  padding: const EdgeInsets.all(20),
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
                        padding: const EdgeInsets.all(12),
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
                        },
                        activeColor: AppConstants.successColor,
                        activeTrackColor: AppConstants.successColor.withOpacity(0.3),
                      ),
                    ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Account Security
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 20),
                  child: Text(
                    'Account Security',
                    style: TextStyle(
                      fontSize: 18,
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
                
                const SizedBox(height: 30),
                
                // Terms and Conditions Checkbox
                Container(
                  margin: const EdgeInsets.only(bottom: 30),
                  child: Row(
                    children: [
                      // This is just a UI element for demonstration
                      // In a real app, you'd add the checkbox state
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Builder(
                          builder: (context) => RichText(
                            text: TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(
                                color: context.secondaryTextColor,
                              fontSize: 14,
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
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                ),
                
                const SizedBox(height: 20),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: context.secondaryTextColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: context.isDarkMode ? 
                            AppConstants.primaryColor.withOpacity(0.9) : 
                            AppConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
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
      ),
    );
  }
  
  // Build form field with custom styling
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
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
            color: AppConstants.primaryColor,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppConstants.primaryColor,
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
        validator: validator,
          style: TextStyle(
          fontSize: 16,
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
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: label,
            floatingLabelStyle: TextStyle(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.lock_outline,
                color: AppConstants.primaryColor,
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: context.secondaryTextColor,
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
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            fillColor: context.cardColor,
            filled: true,
          ),
          validator: validator,
          style: TextStyle(
            fontSize: 16,
            color: context.textColor,
          ),
        ),
      ),
    );
  }
} 