import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_button.dart';
import '../utils/theme_helper.dart';
import '../firebase/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // Get the email from the controller
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      // Special case for test email
      if (email == 'haseeb@gmail.com') {
        // Use special test login path
        final authService = FirebaseAuthService();
        final testSuccess = await authService.testLogin(email, password);
        
        if (testSuccess && mounted) {
          // Update provider to reflect login
          await appProvider.refreshUserData();
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Test login failed. Please check logs for details.'),
              backgroundColor: AppConstants.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
        return;
      }
      
      // Regular login path
      final success = await appProvider.login(email, password);
      
      if (success && mounted) {
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

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your email address first'),
          backgroundColor: AppConstants.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
      return;
    }
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final success = await appProvider.resetPassword(_emailController.text.trim());
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset email sent. Please check your inbox.'),
          backgroundColor: AppConstants.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    } else if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final bool isAuthenticating = appProvider.isAuthenticating;
    
    // Get screen size for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;
    
    // Responsive sizes
    final double horizontalPadding = screenWidth * 0.05;
    final double verticalSpacing = screenHeight * 0.025;
    final double titleFontSize = isSmallScreen ? 24.0 : 28.0;
    final double subtitleFontSize = isSmallScreen ? 14.0 : 16.0;
    final double buttonHeight = isSmallScreen ? 50.0 : 56.0;
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      // Use SafeArea to avoid system UI overlays
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalSpacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.05),
                    // Logo and Header
                    Center(
                      child: FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          width: screenWidth * 0.28,
                          height: screenWidth * 0.28,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.primaryColor.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 5,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: screenWidth * 0.14,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    // Login Form
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: Builder(
                        builder: (context) => Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                              ),
                              SizedBox(height: verticalSpacing * 0.3),
                              Text(
                                'Please sign in to continue',
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  color: context.secondaryTextColor,
                                ),
                              ),
                              SizedBox(height: verticalSpacing * 1.2),
                              // Email Field
                              Builder(
                                builder: (context) => Container(
                                  margin: EdgeInsets.only(bottom: verticalSpacing * 0.8),
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
                                    controller: _emailController,
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
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      floatingLabelStyle: TextStyle(
                                        color: AppConstants.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isSmallScreen ? 14 : 16,
                                      ),
                                      prefixIcon: Container(
                                        margin: EdgeInsets.all(isSmallScreen ? 8 : 12),
                                        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                        decoration: BoxDecoration(
                                          color: AppConstants.primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.email_outlined,
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
                                  ),
                                ),
                              ),
                              
                              // Password Field
                              Builder(
                                builder: (context) => Container(
                                  margin: EdgeInsets.only(bottom: verticalSpacing * 0.5),
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
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      floatingLabelStyle: TextStyle(
                                        color: AppConstants.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isSmallScreen ? 14 : 16,
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
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.grey,
                                          size: isSmallScreen ? 18 : 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
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
                                  ),
                                ),
                              ),
                              
                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _resetPassword,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: AppConstants.primaryColor,
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: verticalSpacing),
                              
                              // Login Button
                              SizedBox(
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
                                        text: 'LOGIN',
                                        onPressed: _login,
                                        fontSize: isSmallScreen ? 14 : 16,
                                        height: buttonHeight,
                                      ),
                              ),
                              
                              SizedBox(height: verticalSpacing * 1.5),
                              
                              // Register Link
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: context.secondaryTextColor,
                                        fontSize: isSmallScreen ? 12 : 14,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Navigate to register screen
                                        Navigator.of(context).pushNamed('/signup');
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 4 : 8,
                                          vertical: isSmallScreen ? 2 : 4,
                                        ),
                                      ),
                                      child: Text(
                                        'Register Now',
                                        style: TextStyle(
                                          color: context.isDarkMode ? 
                                            AppConstants.primaryColor.withOpacity(0.9) : 
                                            AppConstants.primaryColor,
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                    ),
                                  ],
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
            );
          },
        ),
      ),
    );
  }
} 