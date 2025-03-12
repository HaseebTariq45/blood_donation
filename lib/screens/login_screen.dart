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
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              // Logo and Header
              Center(
                child: FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
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
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'BLOOD DONATION',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
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
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please sign in to continue',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 30),
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
                            ),
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: context.textColor),
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
                        const SizedBox(height: 20),
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
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: context.secondaryTextColor,
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
                            ),
                            obscureText: _obscurePassword,
                            style: TextStyle(color: context.textColor),
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
                        const SizedBox(height: 15),
                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Navigate to forgot password screen
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: context.isDarkMode ? 
                                  AppConstants.primaryColor.withOpacity(0.9) : 
                                  AppConstants.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Login Button
                        CustomButton(
                          text: 'LOGIN',
                          onPressed: _login,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 30),
                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: context.secondaryTextColor,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to register screen
                                Navigator.of(context).pushNamed('/signup');
                              },
                              child: Text(
                                'Register Now',
                                style: TextStyle(
                                  color: context.isDarkMode ? 
                                    AppConstants.primaryColor.withOpacity(0.9) : 
                                    AppConstants.primaryColor,
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
            ],
          ),
        ),
      ),
    );
  }
} 