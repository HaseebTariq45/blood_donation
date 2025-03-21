import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/theme_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/services.dart'; // For haptic feedback
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

// Custom CheckMark painter for animating the checkmark
class CheckMarkPainter extends CustomPainter {
  final double animation;
  final Color color;
  final double strokeWidth;

  CheckMarkPainter({required this.animation, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Calculate the check mark points based on size
    final double startX = size.width * 0.2;
    final double midY = size.height * 0.65;
    final double midX = size.width * 0.45;
    final double endX = size.width * 0.8;
    final double endY = size.height * 0.35;
    
    // First part of the check mark (shorter line)
    if (animation < 0.5) {
      final pct = animation * 2;
      path.moveTo(startX, midY);
      path.lineTo(startX + (midX - startX) * pct, midY - (midY - endY) * pct);
    } else {
      path.moveTo(startX, midY);
      path.lineTo(midX, endY);
      
      // Second part of the check mark (longer line)
      final pct = (animation - 0.5) * 2;
      path.lineTo(midX + (endX - midX) * pct, endY + (midY - endY) * pct);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckMarkPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class HealthQuestionnaireScreen extends StatefulWidget {
  final bool isPostSignup;
  
  const HealthQuestionnaireScreen({
    super.key,
    this.isPostSignup = false,
  });

  @override
  State<HealthQuestionnaireScreen> createState() => _HealthQuestionnaireScreenState();
}

class _HealthQuestionnaireScreenState extends State<HealthQuestionnaireScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  
  // Animation controllers for dialogs
  late AnimationController _successAnimationController;
  late Animation<double> _successAnimation;
  late AnimationController _errorAnimationController;
  late Animation<double> _errorAnimation;

  // Form controllers
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _lastDonationController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();

  // Form values
  String _gender = 'Male';
  bool _hasTattoo = false;
  bool _hasPiercing = false;
  bool _hasTraveled = false;
  bool _hasSurgery = false;
  bool _hasTransfusion = false;
  bool _hasPregnancy = false;
  bool _hasDisease = false;
  bool _hasMedication = false;
  bool _hasAllergies = false;

  // Health status indicators
  String _healthStatus = 'Good';
  Color _healthStatusColor = Colors.green;
  String _nextDonationDate = '';

  @override
  void initState() {
    super.initState();
    _loadHealthInfo();
    
    // Initialize animation controllers
    _successAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _successAnimation = CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.easeInOut,
    );
    
    _errorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _errorAnimation = CurvedAnimation(
      parent: _errorAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _heightController.dispose();
    _weightController.dispose();
    _lastDonationController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _successAnimationController.dispose();
    _errorAnimationController.dispose();
    super.dispose();
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

    // Calculate next donation date
    if (_lastDonationController.text.isNotEmpty) {
      try {
        final lastDonation = DateTime.parse(_lastDonationController.text);
        // Standard waiting period is 56 days (8 weeks) between whole blood donations
        final nextDonation = lastDonation.add(const Duration(days: 56));
        _nextDonationDate = nextDonation.toString().split(' ')[0];
        debugPrint('Calculated next donation date: $_nextDonationDate');
      } catch (e) {
        debugPrint('Error calculating next donation date: $e');
        _nextDonationDate = '';
      }
    } else {
      _nextDonationDate = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Health Questionnaire',
        showBackButton: !widget.isPostSignup,
        actions: [
          if (_hasUnsavedChanges)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Tooltip(
                message: 'You have unsaved changes',
                child: Icon(
                  Icons.save_alt,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isPostSignup)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.primaryColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please complete your health questionnaire to continue. This information is important for blood donation eligibility.',
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                _buildHealthStatusIndicator(),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Basic Information',
                  icon: Icons.person_outline,
                  child: Column(
                    children: [
                      _buildCustomField(
                        controller: _heightController,
                        label: 'Height (cm)',
                        icon: Icons.height,
                        hint: 'Enter your height',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildCustomField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        icon: Icons.monitor_weight_outlined,
                        hint: 'Enter your weight',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        label: 'Gender',
                        value: _gender,
                        items: ['Male', 'Female', 'Other'],
                        icon: Icons.person,
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                            _hasUnsavedChanges = true;
                          });
                          _startAutoSaveTimer();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Donation History',
                  icon: Icons.history,
                  child: Column(
                    children: [
                      _buildCustomField(
                        controller: _lastDonationController,
                        label: 'Last Donation Date',
                        icon: Icons.calendar_today,
                        isDate: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a date';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Health Status',
                  icon: Icons.health_and_safety,
                  child: Column(
                    children: [
                      _buildSwitchField(
                        title: 'Recent Tattoo',
                        subtitle: 'Tattoo within the last 6 months',
                        value: _hasTattoo,
                        onChanged: (value) {
                          setState(() {
                            _hasTattoo = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        title: 'Recent Piercing',
                        subtitle: 'Piercing within the last 6 months',
                        value: _hasPiercing,
                        onChanged: (value) {
                          setState(() {
                            _hasPiercing = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        title: 'Recent Travel',
                        subtitle: 'Traveled outside the country in the last 6 months',
                        value: _hasTraveled,
                        onChanged: (value) {
                          setState(() {
                            _hasTraveled = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        title: 'Recent Surgery',
                        subtitle: 'Surgery within the last 6 months',
                        value: _hasSurgery,
                        onChanged: (value) {
                          setState(() {
                            _hasSurgery = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        title: 'Recent Blood Transfusion',
                        subtitle: 'Blood transfusion within the last 6 months',
                        value: _hasTransfusion,
                        onChanged: (value) {
                          setState(() {
                            _hasTransfusion = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        title: 'Recent Pregnancy',
                        subtitle: 'Pregnant or planning to become pregnant',
                        value: _hasPregnancy,
                        onChanged: (value) {
                          setState(() {
                            _hasPregnancy = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        title: 'Chronic Disease',
                        subtitle: 'Any chronic disease or condition',
                        value: _hasDisease,
                        onChanged: (value) {
                          setState(() {
                            _hasDisease = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        title: 'Current Medications',
                        subtitle: 'Taking any medications',
                        value: _hasMedication,
                        onChanged: (value) {
                          setState(() {
                            _hasMedication = value;
                          });
                        },
                      ),
                      if (_hasMedication) ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _medicationsController,
                          label: 'List your medications',
                          prefixIcon: Icons.medication,
                          keyboardType: TextInputType.text,
                          maxLines: 3,
                          validator: (value) {
                            if (_hasMedication && (value == null || value.isEmpty)) {
                              return 'Please specify your medications';
                            }
                            return null;
                          },
                        ),
                      ],
                      _buildSwitchField(
                        title: 'Allergies',
                        subtitle: 'Allergies to any substances',
                        value: _hasAllergies,
                        onChanged: (value) {
                          setState(() {
                            _hasAllergies = value;
                          });
                        },
                      ),
                      if (_hasAllergies) ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _allergiesController,
                          label: 'List your allergies',
                          prefixIcon: Icons.warning_amber,
                          keyboardType: TextInputType.text,
                          maxLines: 3,
                          validator: (value) {
                            if (_hasAllergies && (value == null || value.isEmpty)) {
                              return 'Please specify your allergies';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveHealthInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
                      shadowColor: Theme.of(context).brightness == Brightness.dark 
                        ? AppConstants.primaryColor.withOpacity(0.5) 
                        : Colors.black.withOpacity(0.2),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.isPostSignup ? 'Complete Profile' : 'Save Health Information',
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppConstants.primaryColor.withOpacity(0.2)
                  : AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppConstants.primaryColor.withOpacity(0.3)
                        : AppConstants.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode 
                        ? Colors.white 
                        : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isDate = false,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: isDate,
      onTap: isDate ? () => _selectDate(controller) : null,
      validator: validator,
      onChanged: (_) {
        setState(() {
          _hasUnsavedChanges = true;
        });
        _startAutoSaveTimer();
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: AppConstants.primaryColor,
          size: 22,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDarkMode 
            ? Colors.grey[800] 
            : Colors.grey[50],
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(
        fontSize: 16,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty
          ? DateTime.parse(controller.text)
          : now.subtract(const Duration(days: 60)), // Default to 60 days ago
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppConstants.primaryColor,
                ),
            dialogBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        controller.text = "${picked.toIso8601String().split('T')[0]}";
        _updateHealthStatus();
        _hasUnsavedChanges = true;
      });
      _startAutoSaveTimer();
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int? maxLines,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
      validator: validator,
      onChanged: (_) {
        setState(() {
          _hasUnsavedChanges = true;
        });
        _startAutoSaveTimer();
      },
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          prefixIcon,
          color: AppConstants.primaryColor,
          size: 22,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        icon: const Icon(Icons.arrow_drop_down, color: AppConstants.primaryColor),
        iconSize: 24,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: AppConstants.primaryColor) : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          border: InputBorder.none,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _hasUnsavedChanges = true;
          });
          onChanged(newValue);
        },
      ),
    );
  }

  Widget _buildSwitchField({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? (value ? AppConstants.primaryColor.withOpacity(0.2) : Colors.grey[800])
            : (value ? AppConstants.primaryColor.withOpacity(0.1) : Colors.grey[50]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value 
              ? AppConstants.primaryColor
              : (isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
          width: value ? 1.5 : 1.0,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        value: value,
        onChanged: (newValue) {
          // Add haptic feedback
          HapticFeedback.lightImpact();
          onChanged(newValue);
          _updateHealthStatus();
        },
        activeColor: AppConstants.primaryColor,
        activeTrackColor: AppConstants.primaryColor.withOpacity(0.4),
        inactiveThumbColor: isDarkMode ? Colors.grey[400] : Colors.grey[50],
        inactiveTrackColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: false,
        controlAffinity: ListTileControlAffinity.trailing,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildHealthStatusIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? _healthStatusColor.withOpacity(0.15)
            : _healthStatusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _healthStatusColor.withOpacity(isDarkMode ? 0.5 : 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _healthStatusColor.withOpacity(isDarkMode ? 0.2 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _healthStatusColor.withOpacity(isDarkMode ? 0.25 : 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? _healthStatusColor.withOpacity(0.3)
                        : _healthStatusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getHealthStatusIcon(),
                    color: _healthStatusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Donation Eligibility',
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Status Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Current Status: ',
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black87.withOpacity(0.7),
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _healthStatus,
                      style: TextStyle(
                        color: _healthStatusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_nextDonationDate.isNotEmpty) ...[
                  Text(
                    'Next donation possible after:',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black87.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _nextDonationDate,
                    style: TextStyle(
                      color: _healthStatusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getHealthStatusIcon() {
    switch (_healthStatus) {
      case 'Good':
        return Icons.check_circle;
      case 'Needs Review':
        return Icons.info;
      case 'Temporary Deferral':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  Future<void> _loadHealthInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Load health questionnaire data
        final doc = await FirebaseFirestore.instance
            .collection('health_questionnaires')
            .doc(userId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          _heightController.text = data['height'] ?? '';
          _weightController.text = data['weight'] ?? '';
          _lastDonationController.text = data['lastDonationDate'] ?? '';
          _gender = data['gender'] ?? 'Male';
          _hasTattoo = data['hasTattoo'] ?? false;
          _hasPiercing = data['hasPiercing'] ?? false;
          _hasTraveled = data['hasTraveled'] ?? false;
          _hasSurgery = data['hasSurgery'] ?? false;
          _hasTransfusion = data['hasTransfusion'] ?? false;
          _hasPregnancy = data['hasPregnancy'] ?? false;
          _hasDisease = data['hasDisease'] ?? false;
          _hasMedication = data['hasMedication'] ?? false;
          _hasAllergies = data['hasAllergies'] ?? false;
          _medicationsController.text = data['medications'] ?? '';
          _allergiesController.text = data['allergies'] ?? '';
        }
        
        // If lastDonationDate is empty, try to get it from the user profile
        if (_lastDonationController.text.isEmpty) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
                
            if (userDoc.exists && userDoc.data() != null) {
              final userData = userDoc.data()!;
              
              if (userData['lastDonationDate'] != null) {
                DateTime lastDonation;
                
                if (userData['lastDonationDate'] is Timestamp) {
                  lastDonation = (userData['lastDonationDate'] as Timestamp).toDate();
                } else if (userData['lastDonationDate'] is int) {
                  lastDonation = DateTime.fromMillisecondsSinceEpoch(userData['lastDonationDate']);
                } else if (userData['lastDonationDate'] is String) {
                  lastDonation = DateTime.parse(userData['lastDonationDate']);
                } else {
                  throw Exception('Unsupported lastDonationDate format');
                }
                
                // Format as YYYY-MM-DD
                _lastDonationController.text = lastDonation.toString().split(' ')[0];
                debugPrint('Loaded lastDonationDate from user profile: ${_lastDonationController.text}');
              }
            }
          } catch (e) {
            debugPrint('Error loading lastDonationDate from user profile: $e');
            // Continue even if this fails
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading health information: $e'),
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

  Future<void> _saveHealthInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Save to health_questionnaires collection
        await FirebaseFirestore.instance
            .collection('health_questionnaires')
            .doc(userId)
            .set({
          'height': _heightController.text,
          'weight': _weightController.text,
          'lastDonationDate': _lastDonationController.text,
          'gender': _gender,
          'hasTattoo': _hasTattoo,
          'hasPiercing': _hasPiercing,
          'hasTraveled': _hasTraveled,
          'hasSurgery': _hasSurgery,
          'hasTransfusion': _hasTransfusion,
          'hasPregnancy': _hasPregnancy,
          'hasDisease': _hasDisease,
          'hasMedication': _hasMedication,
          'hasAllergies': _hasAllergies,
          'medications': _medicationsController.text,
          'allergies': _allergiesController.text,
        });

        // Update lastDonationDate in users collection if it has been set
        if (_lastDonationController.text.isNotEmpty) {
          try {
            // Convert string date to timestamp
            final lastDonationDate = DateTime.parse(_lastDonationController.text);
            
            // Update the user document
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({
              'lastDonationDate': lastDonationDate.millisecondsSinceEpoch,
            });
            
            // Also update the user model in the app provider
            final appProvider = Provider.of<AppProvider>(context, listen: false);
            final currentUser = appProvider.currentUser;
            final updatedUser = currentUser.copyWith(
              lastDonationDate: lastDonationDate,
            );
            await appProvider.updateUserProfile(updatedUser);
            
            debugPrint('Updated lastDonationDate in users collection: ${lastDonationDate.toIso8601String()}');
          } catch (e) {
            debugPrint('Error updating lastDonationDate in users collection: $e');
            // Continue with the rest of the function even if this update fails
          }
        }

        if (mounted) {
          // Provide haptic feedback when data is saved
          HapticFeedback.mediumImpact();
          
          // Clear the unsaved changes flag
          setState(() {
            _hasUnsavedChanges = false;
          });
          
          // Show a visually appealing success popup instead of a simple snackbar
          _showSaveSuccessDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        // Vibrate with error pattern for failure
        HapticFeedback.vibrate();
        
        // Show a visually appealing error popup
        _showErrorDialog('Error saving health information: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Custom visually appealing success dialog
  void _showSaveSuccessDialog() {
    // Reset and start the animation
    _successAnimationController.reset();
    _successAnimationController.forward();
    
    // Refresh app provider data
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.refreshUserData();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Container(); // Not used
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _successAnimationController,
                        builder: (context, child) {
                          return Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Growing circle animation
                                Transform.scale(
                                  scale: _successAnimation.value,
                                  child: Container(
                                    width: 75,
                                    height: 75,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                // Check mark animation
                                CustomPaint(
                                  size: const Size(40, 40),
                                  painter: CheckMarkPainter(
                                    animation: _successAnimation.value,
                                    color: Colors.green,
                                    strokeWidth: 4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _successAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _successAnimation.value,
                            child: Text(
                              'Success!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.headlineMedium?.color,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      // Animated text with fade and slide
                      AnimatedBuilder(
                        animation: _successAnimationController,
                        builder: (context, child) {
                          // Determine if we should show this element based on animation progress
                          final showElement = _successAnimation.value >= 0.3; // Show after 30% of animation
                          final elementAnimation = showElement 
                            ? (_successAnimation.value - 0.3) / 0.7 // Normalize to 0-1 for the remaining 70%
                            : 0.0;
                          
                          return Opacity(
                            opacity: elementAnimation,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - elementAnimation)),
                              child: Text(
                                'Your health information has been saved successfully.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 25),
                      // Animated button with fade
                      AnimatedBuilder(
                        animation: _successAnimationController,
                        builder: (context, child) {
                          // Determine if we should show this element based on animation progress
                          final showElement = _successAnimation.value >= 0.5; // Show after 50% of animation
                          final elementAnimation = showElement 
                            ? (_successAnimation.value - 0.5) / 0.5 // Normalize to 0-1 for the remaining 50%
                            : 0.0;
                          
                          return Opacity(
                            opacity: elementAnimation,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                if (widget.isPostSignup) {
                                  Navigator.pushReplacementNamed(context, '/home');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'OK',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Error dialog for save failures
  void _showErrorDialog(String errorMessage) {
    // Reset and start the animation
    _errorAnimationController.reset();
    _errorAnimationController.forward();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Container(); // Not used
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _errorAnimationController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Transform.rotate(
                              angle: (1.0 - _errorAnimation.value) * 0.2,
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 60,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _errorAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _errorAnimation.value,
                            child: Text(
                              'Error!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.headlineMedium?.color,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      AnimatedBuilder(
                        animation: _errorAnimationController,
                        builder: (context, child) {
                          final showElement = _errorAnimation.value >= 0.3;
                          final elementAnimation = showElement 
                            ? (_errorAnimation.value - 0.3) / 0.7
                            : 0.0;
                          
                          return Opacity(
                            opacity: elementAnimation,
                            child: Text(
                              'Something went wrong while saving your data.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: _errorAnimationController,
                        builder: (context, child) {
                          final showElement = _errorAnimation.value >= 0.4;
                          final elementAnimation = showElement 
                            ? (_errorAnimation.value - 0.4) / 0.6
                            : 0.0;
                          
                          return Opacity(
                            opacity: elementAnimation,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                errorMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      AnimatedBuilder(
                        animation: _errorAnimationController,
                        builder: (context, child) {
                          final showElement = _errorAnimation.value >= 0.5;
                          final elementAnimation = showElement 
                            ? (_errorAnimation.value - 0.5) / 0.5
                            : 0.0;
                          
                          return Opacity(
                            opacity: elementAnimation,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[300],
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _saveHealthInfo(); // Try again
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Try Again',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Handle auto-save functionality
  void _startAutoSaveTimer() {
    // Cancel any existing timer first
    _autoSaveTimer?.cancel();
    
    // Start new timer with 2 second delay
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      // Only proceed if there are unsaved changes
      if (_hasUnsavedChanges) {
        _updateHealthStatus(); // Update health status before saving
        _saveHealthInfo();
      }
    });
  }
} 