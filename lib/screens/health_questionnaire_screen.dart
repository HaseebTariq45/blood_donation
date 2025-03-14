import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/theme_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart'; // For haptic feedback

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
      final lastDonation = DateTime.parse(_lastDonationController.text);
      final nextDonation = lastDonation.add(const Duration(days: 56)); // Minimum 56 days between donations
      _nextDonationDate = nextDonation.toString().split(' ')[0];
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
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportHealthData,
            tooltip: 'Export Health Data',
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
                      _buildTextField(
                        controller: _heightController,
                        label: 'Height (cm)',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.height,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.monitor_weight_outlined,
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
                        prefixIcon: Icons.people_outline,
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                          });
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
                      _buildTextField(
                        controller: _lastDonationController,
                        label: 'Last Donation Date',
                        readOnly: true,
                        prefixIcon: Icons.calendar_today,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            _lastDonationController.text = date.toString().split(' ')[0];
                          }
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
                        label: 'Recent Tattoo',
                        value: _hasTattoo,
                        icon: Icons.brush,
                        onChanged: (value) {
                          setState(() {
                            _hasTattoo = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        label: 'Recent Piercing',
                        value: _hasPiercing,
                        icon: Icons.face,
                        onChanged: (value) {
                          setState(() {
                            _hasPiercing = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        label: 'Recent Travel',
                        value: _hasTraveled,
                        icon: Icons.flight,
                        onChanged: (value) {
                          setState(() {
                            _hasTraveled = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        label: 'Recent Surgery',
                        value: _hasSurgery,
                        icon: Icons.medical_services,
                        onChanged: (value) {
                          setState(() {
                            _hasSurgery = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        label: 'Recent Blood Transfusion',
                        value: _hasTransfusion,
                        icon: Icons.bloodtype,
                        onChanged: (value) {
                          setState(() {
                            _hasTransfusion = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        label: 'Recent Pregnancy',
                        value: _hasPregnancy,
                        icon: Icons.pregnant_woman,
                        onChanged: (value) {
                          setState(() {
                            _hasPregnancy = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        label: 'Chronic Disease',
                        value: _hasDisease,
                        icon: Icons.sick,
                        onChanged: (value) {
                          setState(() {
                            _hasDisease = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        label: 'Current Medications',
                        value: _hasMedication,
                        icon: Icons.medication,
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
                          label: 'List of Medications',
                          maxLines: 3,
                          prefixIcon: Icons.medication_outlined,
                        ),
                      ],
                      _buildSwitchField(
                        label: 'Allergies',
                        value: _hasAllergies,
                        icon: Icons.warning_amber,
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
                          label: 'List of Allergies',
                          maxLines: 3,
                          prefixIcon: Icons.warning_amber_outlined,
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
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.isPostSignup ? 'Complete Profile' : 'Save Health Information',
                            style: const TextStyle(fontSize: 16),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool readOnly = false,
    int? maxLines = 1,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      validator: validator,
      onTap: onTap,
      onChanged: (value) {
        setState(() {
          _hasUnsavedChanges = true;
        });
        _updateHealthStatus();
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    IconData? prefixIcon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(label)),
          ],
        ),
        value: value,
        onChanged: (value) {
          setState(() {
            _hasUnsavedChanges = true;
          });
          onChanged(value);
          _updateHealthStatus();
        },
        activeColor: AppConstants.primaryColor,
      ),
    );
  }

  Widget _buildHealthStatusIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _healthStatusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _healthStatusColor),
        boxShadow: [
          BoxShadow(
            color: _healthStatusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
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
                  'Health Status: $_healthStatus',
                  style: TextStyle(
                    color: _healthStatusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_nextDonationDate.isNotEmpty)
                  Text(
                    'Next Eligible Donation: $_nextDonationDate',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadHealthInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
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

        if (mounted) {
          // Provide haptic feedback when data is saved
          HapticFeedback.mediumImpact();
          
          // Clear the unsaved changes flag
          setState(() {
            _hasUnsavedChanges = false;
          });
          
          // Show a visually appealing success popup instead of a simple snackbar
          _showSaveSuccessDialog();
          
          if (widget.isPostSignup) {
            // Navigate to home screen after completing the questionnaire
            Navigator.pushReplacementNamed(context, '/home');
          }
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

  Future<void> _exportHealthData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Create PDF document
      final pdf = pw.Document();
      
      // Add content to PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Health Questionnaire Data',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Basic Information',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Height: ${_heightController.text} cm'),
                pw.Text('Weight: ${_weightController.text} kg'),
                pw.Text('Gender: $_gender'),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Donation History',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Last Donation Date: ${_lastDonationController.text}'),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Health Status',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Health Status: $_healthStatus'),
                if (_nextDonationDate.isNotEmpty)
                  pw.Text('Next Eligible Donation: $_nextDonationDate'),
                pw.SizedBox(height: 10),
                pw.Text('Recent Tattoo: ${_hasTattoo ? 'Yes' : 'No'}'),
                pw.Text('Recent Piercing: ${_hasPiercing ? 'Yes' : 'No'}'),
                pw.Text('Recent Travel: ${_hasTraveled ? 'Yes' : 'No'}'),
                pw.Text('Recent Surgery: ${_hasSurgery ? 'Yes' : 'No'}'),
                pw.Text('Recent Blood Transfusion: ${_hasTransfusion ? 'Yes' : 'No'}'),
                pw.Text('Recent Pregnancy: ${_hasPregnancy ? 'Yes' : 'No'}'),
                pw.Text('Chronic Disease: ${_hasDisease ? 'Yes' : 'No'}'),
                pw.Text('Current Medications: ${_hasMedication ? 'Yes' : 'No'}'),
                if (_hasMedication && _medicationsController.text.isNotEmpty)
                  pw.Text('Medications List: ${_medicationsController.text}'),
                pw.Text('Allergies: ${_hasAllergies ? 'Yes' : 'No'}'),
                if (_hasAllergies && _allergiesController.text.isNotEmpty)
                  pw.Text('Allergies List: ${_allergiesController.text}'),
              ],
            );
          },
        ),
      );

      if (kIsWeb) {
        // For web platform
        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
          name: 'Health_Questionnaire.pdf',
        );
      } else {
        // For mobile platforms
        // Clean up old temporary files first
        await _cleanupTempFiles();
        
        // Create new PDF file
        final output = await getTemporaryDirectory();
        final fileName = 'health_questionnaire_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${output.path}/$fileName');
        
        // Save PDF with minimal compression to reduce memory usage
        await file.writeAsBytes(await pdf.save());

        // Share the PDF file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Health Questionnaire Data',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health data exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting health data: $e'),
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

  // Helper method to clean up old temporary PDF files
  Future<void> _cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      // Find and delete old health questionnaire PDF files
      for (var entity in files) {
        if (entity is File && 
            entity.path.contains('health_questionnaire') &&
            entity.path.endsWith('.pdf')) {
          try {
            await entity.delete();
          } catch (e) {
            // Ignore errors when deleting individual files
            print('Error deleting old file: $e');
          }
        }
      }
    } catch (e) {
      // Ignore errors in cleanup
      print('Error during cleanup: $e');
    }
  }
} 