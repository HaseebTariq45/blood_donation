import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../models/blood_request_model.dart';

class BloodRequestScreen extends StatefulWidget {
  const BloodRequestScreen({Key? key}) : super(key: key);

  @override
  State<BloodRequestScreen> createState() => _BloodRequestScreenState();
}

class _BloodRequestScreenState extends State<BloodRequestScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedBloodType = 'A+';
  String _selectedUrgency = 'Normal';
  bool _isLoading = false;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  
  final List<String> _urgencyTypes = ['Normal', 'Urgent'];

  @override
  void initState() {
    super.initState();
    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);
    
    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    
    // Prefill with user data if available
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (appProvider.isLoggedIn) {
      _nameController.text = appProvider.currentUser.name;
      _phoneController.text = appProvider.currentUser.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _hospitalController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Create a new blood request
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final user = appProvider.currentUser;
      
      final bloodRequest = BloodRequestModel(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        requesterId: user.id,
        requesterName: _nameController.text,
        contactNumber: _phoneController.text,
        bloodType: _selectedBloodType,
        location: _hospitalController.text,
        requestDate: DateTime.now(),
        urgency: _selectedUrgency,
        notes: _notesController.text,
      );
      
      appProvider.addBloodRequest(bloodRequest);
      
      // Simulate network delay
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _isLoading = false;
        });
        
        _showSuccessDialog();
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppConstants.successColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Request Submitted',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.darkTextColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your blood request has been submitted successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    icon: Icons.bloodtype,
                    title: 'Blood Type',
                    value: _selectedBloodType,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: _selectedUrgency == 'Urgent' ? Icons.priority_high : Icons.access_time,
                    title: 'Urgency',
                    value: _selectedUrgency,
                    color: _selectedUrgency == 'Urgent' ? AppConstants.errorColor : AppConstants.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    title: 'Location',
                    value: _hospitalController.text,
                    color: Colors.indigo,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Potential donors will be notified. You will receive a notification when a donor accepts your request.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppConstants.lightTextColor,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'DONE',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon, 
    required String title, 
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required String? Function(String?) validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
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
              color: Colors.grey.withOpacity(0.1),
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
          fillColor: Colors.white,
          filled: true,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildBloodTypeDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Blood Type',
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
              Icons.bloodtype_outlined,
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
              color: Colors.grey.withOpacity(0.1),
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
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        value: _selectedBloodType,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppConstants.primaryColor.withOpacity(0.7),
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(15),
        items: _bloodTypes.map((type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppConstants.primaryColor,
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedBloodType = value!;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a blood type';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        title: const Text(
          'Blood Requests',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(
              icon: Icon(Icons.list_alt),
              text: 'All Requests',
            ),
            Tab(
              icon: Icon(Icons.add_circle_outline),
              text: 'Create Request',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: List of Blood Requests
          _buildBloodRequestsList(),
          
          // Tab 2: Blood Request Form
          _buildBloodRequestForm(),
        ],
      ),
    );
  }
  
  // Build the list of blood requests
  Widget _buildBloodRequestsList() {
    final appProvider = Provider.of<AppProvider>(context);
    final bloodRequests = appProvider.bloodRequests;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: bloodRequests.isEmpty
          ? _buildEmptyRequestsList()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bloodRequests.length,
              itemBuilder: (context, index) {
                final request = bloodRequests[index];
                return _buildRequestCard(request);
              },
            ),
    );
  }
  
  // Build empty state for blood requests list
  Widget _buildEmptyRequestsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bloodtype_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Blood Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'There are no active blood requests at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(1); // Switch to Create Request tab
            },
            icon: const Icon(Icons.add),
            label: const Text('Create a Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build individual request card
  Widget _buildRequestCard(BloodRequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.white,
              request.urgency == 'Urgent' ? Colors.red.shade50 : Colors.blue.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        request.bloodType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                request.urgency == 'Urgent' ? 'Urgent: ${request.requesterName}' : request.requesterName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: request.urgency == 'Urgent'
                                    ? AppConstants.errorColor.withOpacity(0.1)
                                    : AppConstants.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: request.urgency == 'Urgent'
                                      ? AppConstants.errorColor.withOpacity(0.5)
                                      : AppConstants.primaryColor.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                request.urgency,
                                style: TextStyle(
                                  color: request.urgency == 'Urgent'
                                      ? AppConstants.errorColor
                                      : AppConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.location,
                          style: const TextStyle(
                            color: AppConstants.lightTextColor,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppConstants.lightTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${request.requestDate.day}/${request.requestDate.month}/${request.requestDate.year}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppConstants.lightTextColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppConstants.lightTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              request.contactNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppConstants.lightTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (request.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  request.notes,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.darkTextColor,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // Option to call the requester
                    },
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.primaryColor,
                      side: BorderSide(color: AppConstants.primaryColor),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Handle donation response
                      _showResponseDialog(request);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Respond'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Show dialog to respond to a blood request
  void _showResponseDialog(BloodRequestModel request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do you want to respond to ${request.requesterName}\'s blood request?'),
            const SizedBox(height: 16),
            Text(
              'Responding will share your contact information with the requester.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Add logic to handle the response
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You have responded to ${request.requesterName}\'s request'),
                  backgroundColor: AppConstants.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            child: const Text('RESPOND'),
          ),
        ],
      ),
    );
  }
  
  // Build the blood request form
  Widget _buildBloodRequestForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism,
                          color: AppConstants.primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Blood Request',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.darkTextColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please complete the form below to submit your blood request',
                              style: TextStyle(
                                color: AppConstants.lightTextColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Form for blood request
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 16),
                      child: Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.darkTextColor,
                        ),
                      ),
                    ),
                    
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
                    
                    _buildFormField(
                      controller: _phoneController,
                      label: 'Contact Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your contact number';
                        }
                        return null;
                      },
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.only(left: 4, top: 10, bottom: 16),
                      child: Text(
                        'Request Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.darkTextColor,
                        ),
                      ),
                    ),
                    
                    _buildBloodTypeDropdown(),
                    
                    _buildFormField(
                      controller: _hospitalController,
                      label: 'Hospital/Location',
                      icon: Icons.location_on_outlined,
                      hintText: 'Enter hospital name or location',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the hospital or location';
                        }
                        return null;
                      },
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 16),
                      child: Text(
                        'Urgency Level',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppConstants.darkTextColor,
                        ),
                      ),
                    ),
                    
                    Row(
                      children: _urgencyTypes.map((type) {
                        final isSelected = _selectedUrgency == type;
                        final color = type == 'Urgent'
                            ? AppConstants.errorColor
                            : AppConstants.primaryColor;
                        
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedUrgency = type;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: type == 'Normal' ? 8 : 0),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : Colors.grey.withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.1),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      type == 'Urgent'
                                          ? Icons.priority_high
                                          : Icons.access_time,
                                      color: isSelected
                                          ? color
                                          : Colors.grey[400],
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    type,
                                    style: TextStyle(
                                      color: isSelected
                                          ? color
                                          : Colors.grey[600],
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildFormField(
                      controller: _notesController,
                      label: 'Additional Notes',
                      icon: Icons.note_alt_outlined,
                      hintText: 'E.g., Patient details, specific requirements',
                      maxLines: 3,
                      validator: (value) => null, // Optional field
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : ElevatedButton(
                              onPressed: _submitRequest,
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
                                'SUBMIT REQUEST',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Important Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'By submitting this form, you agree to share your contact information with potential donors. Blood availability cannot be guaranteed and depends on donor response.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 