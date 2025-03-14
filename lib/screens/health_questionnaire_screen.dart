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

class HealthQuestionnaireScreen extends StatefulWidget {
  final bool isPostSignup;
  
  const HealthQuestionnaireScreen({
    super.key,
    this.isPostSignup = false,
  });

  @override
  State<HealthQuestionnaireScreen> createState() => _HealthQuestionnaireScreenState();
}

class _HealthQuestionnaireScreenState extends State<HealthQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

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
    _setupAutoSave();
  }

  void _setupAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_hasUnsavedChanges) {
        _saveHealthInfo();
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _heightController.dispose();
    _weightController.dispose();
    _lastDonationController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
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
              child: Icon(
                Icons.save_alt,
                color: Colors.orange,
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Health information saved successfully'),
              backgroundColor: Colors.green,
            ),
          );

          if (widget.isPostSignup) {
            // Navigate to home screen after completing the questionnaire
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving health information: $e'),
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
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/health_questionnaire.pdf');
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
} 