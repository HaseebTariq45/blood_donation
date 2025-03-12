import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_button.dart';
import '../utils/theme_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate login delay
      Future.delayed(const Duration(seconds: 1), () {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        appProvider.login(_emailController.text, _passwordController.text);
        
        setState(() {
          _isLoading = false;
        });
        
        Navigator.of(context).pushReplacementNamed('/home');
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
    final double logoSize = screenWidth * 0.25;
    final double logoIconSize = logoSize * 0.5;
    final double headerFontSize = isSmallScreen ? 20 : 24;
    final double titleFontSize = isSmallScreen ? 24 : 28;
    final double subtitleFontSize = isSmallScreen ? 12 : 14;
    
    // Calculate padding based on screen size
    final double horizontalPadding = screenWidth * 0.06;
    final double verticalSpacing = screenHeight * 0.025;
    
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
                        child: Column(
                          children: [
                            Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppConstants.primaryColor.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: logoIconSize,
                              ),
                            ),
                            SizedBox(height: verticalSpacing),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'BLOOD DONATION',
                                style: TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontSize: headerFontSize,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.06),
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
                              Container(
                                decoration: BoxDecoration(
                                  color: context.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.isDarkMode ? 
                                        Colors.black12 : 
                                        Colors.grey.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: TextStyle(
                                      color: context.secondaryTextColor,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: context.isDarkMode ? 
                                        AppConstants.primaryColor.withOpacity(0.8) : 
                                        AppConstants.primaryColor,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.isDarkMode ? 
                                          Colors.grey.withOpacity(0.2) : 
                                          Colors.grey.withOpacity(0.1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppConstants.primaryColor.withOpacity(0.5),
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.red.withOpacity(0.5),
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.red.withOpacity(0.5),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: context.cardColor,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 12 : 16,
                                      horizontal: isSmallScreen ? 12 : 16,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
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
                              ),
                              SizedBox(height: verticalSpacing * 0.8),
                              // Password Field
                              Container(
                                decoration: BoxDecoration(
                                  color: context.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.isDarkMode ? 
                                        Colors.black12 : 
                                        Colors.grey.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                      color: context.secondaryTextColor,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: context.isDarkMode ? 
                                        AppConstants.primaryColor.withOpacity(0.8) : 
                                        AppConstants.primaryColor,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: context.secondaryTextColor,
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.isDarkMode ? 
                                          Colors.grey.withOpacity(0.2) : 
                                          Colors.grey.withOpacity(0.1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppConstants.primaryColor.withOpacity(0.5),
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.red.withOpacity(0.5),
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.red.withOpacity(0.5),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: context.cardColor,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 12 : 16,
                                      horizontal: isSmallScreen ? 12 : 16,
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(height: verticalSpacing * 0.6),
                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // Navigate to forgot password screen
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 8 : 12,
                                      vertical: isSmallScreen ? 4 : 8,
                                    ),
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: context.isDarkMode ? 
                                        AppConstants.primaryColor.withOpacity(0.9) : 
                                        AppConstants.primaryColor,
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: verticalSpacing * 1.2),
                              // Login Button
                              CustomButton(
                                text: 'LOGIN',
                                onPressed: _login,
                                isLoading: _isLoading,
                              ),
                              SizedBox(height: verticalSpacing * 1.2),
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