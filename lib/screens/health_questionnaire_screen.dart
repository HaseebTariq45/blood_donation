import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/theme_helper.dart';

class HealthQuestionnaireScreen extends StatefulWidget {
  const HealthQuestionnaireScreen({super.key});

  @override
  State<HealthQuestionnaireScreen> createState() => _HealthQuestionnaireScreenState();
}

class _HealthQuestionnaireScreenState extends State<HealthQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _lastDonationController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();

  // Form values
  String _bloodType = 'A+';
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

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _lastDonationController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Health Questionnaire',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _heightController,
                  label: 'Height (cm)',
                  keyboardType: TextInputType.number,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your weight';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'Blood Type',
                  value: _bloodType,
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                  onChanged: (value) {
                    setState(() {
                      _bloodType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'Gender',
                  value: _gender,
                  items: ['Male', 'Female', 'Other'],
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Donation History'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _lastDonationController,
                  label: 'Last Donation Date',
                  readOnly: true,
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
                const SizedBox(height: 24),
                _buildSectionTitle('Health Status'),
                const SizedBox(height: 16),
                _buildSwitchField(
                  label: 'Recent Tattoo',
                  value: _hasTattoo,
                  onChanged: (value) {
                    setState(() {
                      _hasTattoo = value;
                    });
                  },
                ),
                _buildSwitchField(
                  label: 'Recent Piercing',
                  value: _hasPiercing,
                  onChanged: (value) {
                    setState(() {
                      _hasPiercing = value;
                    });
                  },
                ),
                _buildSwitchField(
                  label: 'Recent Travel',
                  value: _hasTraveled,
                  onChanged: (value) {
                    setState(() {
                      _hasTraveled = value;
                    });
                  },
                ),
                _buildSwitchField(
                  label: 'Recent Surgery',
                  value: _hasSurgery,
                  onChanged: (value) {
                    setState(() {
                      _hasSurgery = value;
                    });
                  },
                ),
                _buildSwitchField(
                  label: 'Recent Blood Transfusion',
                  value: _hasTransfusion,
                  onChanged: (value) {
                    setState(() {
                      _hasTransfusion = value;
                    });
                  },
                ),
                _buildSwitchField(
                  label: 'Recent Pregnancy',
                  value: _hasPregnancy,
                  onChanged: (value) {
                    setState(() {
                      _hasPregnancy = value;
                    });
                  },
                ),
                _buildSwitchField(
                  label: 'Chronic Disease',
                  value: _hasDisease,
                  onChanged: (value) {
                    setState(() {
                      _hasDisease = value;
                    });
                  },
                ),
                _buildSwitchField(
                  label: 'Current Medications',
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
                    label: 'List of Medications',
                    maxLines: 3,
                  ),
                ],
                _buildSwitchField(
                  label: 'Allergies',
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
                    label: 'List of Allergies',
                    maxLines: 3,
                  ),
                ],
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
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Health Information'),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppConstants.primaryColor,
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      validator: validator,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
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
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
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
      ),
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      activeColor: AppConstants.primaryColor,
    );
  }

  Future<void> _saveHealthInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement saving health information to Firebase
      await Future.delayed(const Duration(seconds: 2)); // Simulated delay

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health information saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
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
} 