import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../models/emergency_contact_model.dart';
import '../providers/app_provider.dart';
import '../utils/theme_helper.dart';
import '../widgets/custom_alert_dialog.dart';
import 'package:flutter/gestures.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedContactType = 'personal';
  final _formKey = GlobalKey<FormState>();

  StreamSubscription? _contactsSubscription;
  List<EmergencyContactModel> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupContactsStream();
  }

  void _setupContactsStream() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Set initial loading state
    setState(() {
      _isLoading = true;
    });

    // Subscribe to contacts stream
    _contactsSubscription = appProvider.getEmergencyContactsStream().listen(
      (contacts) {
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      },
      onError: (error) {
        debugPrint('Error in contacts stream: $error');
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    _addressController.dispose();
    _contactsSubscription?.cancel();
    super.dispose();
  }

  // Make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot make phone call. Please check the number.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle adding a new contact
  void _showAddContactDialog() {
    // Reset form fields
    _nameController.clear();
    _phoneController.clear();
    _relationshipController.clear();
    _addressController.clear();
    _selectedContactType = 'personal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildContactForm(context),
    );
  }

  // Build the contact form modal
  Widget _buildContactForm(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final textTheme = Theme.of(context).textTheme;

    // Calculate responsive padding
    final double verticalPadding = screenHeight * 0.02;
    final double horizontalPadding = mediaQuery.size.width * 0.05;

    return Container(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
        top: verticalPadding,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85, // Limit max height to 85% of screen
      ),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusL),
          topRight: Radius.circular(AppConstants.radiusL),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form title
              Center(
                child: Container(
                  height: 4,
                  width: mediaQuery.size.width * 0.1,
                  margin: EdgeInsets.only(bottom: verticalPadding),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Add Emergency Contact',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: verticalPadding),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: verticalPadding * 0.75),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: verticalPadding * 0.75),

              // Relationship field
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: Icon(Icons.people),
                ),
              ),
              SizedBox(height: verticalPadding * 0.75),

              // Address field
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              SizedBox(height: verticalPadding * 0.75),

              // Contact type dropdown
              DropdownButtonFormField<String>(
                value: _selectedContactType,
                decoration: const InputDecoration(
                  labelText: 'Contact Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'personal', child: Text('Personal')),
                  DropdownMenuItem(value: 'hospital', child: Text('Hospital')),
                  DropdownMenuItem(
                    value: 'blood_bank',
                    child: Text('Blood Bank'),
                  ),
                  DropdownMenuItem(
                    value: 'ambulance',
                    child: Text('Ambulance'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedContactType = value;
                    });
                  }
                },
              ),
              SizedBox(height: verticalPadding * 1.25),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.06,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                  onPressed: _saveContact,
                  child: const Text('Save Contact'),
                ),
              ),
              SizedBox(height: verticalPadding),
            ],
          ),
        ),
      ),
    );
  }

  // Show success dialog for contact saved
  void _showContactSavedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: context.cardColor,
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
                Text(
                  'Contact Saved',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
            content: Text(
              'The emergency contact has been saved successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: context.textColor,
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
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
                    'OK',
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

  // Save a new contact
  void _saveContact() async {
    if (_formKey.currentState?.validate() ?? false) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Create a new contact
      final newContact = EmergencyContactModel(
        id: '',
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        relationship: _relationshipController.text.trim(),
        address: _addressController.text.trim(),
        contactType: _selectedContactType,
        createdAt: DateTime.now(),
        userId: appProvider.currentUser.id,
      );

      // Show loading indicator
      if (mounted) {
        Navigator.pop(context); // Close the form
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Add the contact
      final success = await appProvider.addEmergencyContact(newContact);

      // Close loading indicator
      if (mounted) {
        Navigator.pop(context);
      }

      // Show result
      if (mounted) {
        if (success) {
          _showContactSavedDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to add contact'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Confirm and delete a contact
  void _confirmDeleteContact(EmergencyContactModel contact) {
    showDialog(
      context: context,
      builder:
          (context) => CustomAlertDialog(
            title: 'Delete Contact',
            content: 'Are you sure you want to delete ${contact.name}?',
            confirmText: 'Delete',
            cancelText: 'Cancel',
            confirmColor: Colors.red,
            onConfirm: () async {
              Navigator.pop(context); // Close dialog

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) =>
                        const Center(child: CircularProgressIndicator()),
              );

              // Delete the contact
              final appProvider = Provider.of<AppProvider>(
                context,
                listen: false,
              );
              final success = await appProvider.deleteEmergencyContact(
                contact.id,
              );

              // Close loading
              if (mounted) {
                Navigator.pop(context);
              }

              // Show result
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Contact deleted' : 'Failed to delete contact',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
          ),
    );
  }

  // Build a contact card
  Widget _buildContactCard(
    EmergencyContactModel contact, {
    required double horizontalPadding,
  }) {
    // Determine icon based on contact type
    IconData typeIcon;
    Color iconColor;

    switch (contact.contactType) {
      case 'hospital':
        typeIcon = Icons.local_hospital;
        iconColor = Colors.red;
        break;
      case 'blood_bank':
        typeIcon = Icons.bloodtype;
        iconColor = AppConstants.primaryColor;
        break;
      case 'ambulance':
        typeIcon = Icons.emergency;
        iconColor = Colors.orange;
        break;
      case 'personal':
      default:
        typeIcon = Icons.person;
        iconColor = Colors.blue;
    }

    final bool isSystemContact = contact.userId == 'system';
    final mediaQuery = MediaQuery.of(context);
    final bool isSmallScreen = mediaQuery.size.width < 360;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes based on card width
        final double avatarSize = constraints.maxWidth * 0.15;
        final double iconSize = avatarSize * 0.6;
        final double spacing = constraints.maxWidth * 0.04;

        return Card(
          margin: EdgeInsets.only(bottom: mediaQuery.size.height * 0.015),
          elevation: 3,
          shadowColor: iconColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: contact.isPinned
                ? BorderSide(color: AppConstants.primaryColor, width: 1.5)
                : BorderSide.none,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.isDarkMode
                      ? context.cardColor
                      : Colors.white,
                  context.isDarkMode
                      ? context.cardColor
                      : iconColor.withOpacity(0.05),
                ],
                stops: const [0.85, 1.0],
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _makePhoneCall(contact.phoneNumber),
                child: Padding(
                  padding: EdgeInsets.all(mediaQuery.size.width * 0.035),
                  child: Row(
                    children: [
                      // Contact avatar with subtle gradient
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              iconColor.withOpacity(0.15),
                              iconColor.withOpacity(0.25),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(typeIcon, color: iconColor, size: iconSize),
                        ),
                      ),
                      SizedBox(width: spacing),

                      // Contact info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      contact.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 14 : 16,
                                        color: context.textColor,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                if (contact.isPinned)
                                  Container(
                                    margin: EdgeInsets.only(left: spacing * 0.5),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.push_pin,
                                      size: isSmallScreen ? 12 : 14,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: mediaQuery.size.height * 0.005),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.call,
                                    size: isSmallScreen ? 10 : 12,
                                    color: Colors.blue[700],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    contact.phoneNumber,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (contact.relationship.isNotEmpty) ...[
                              SizedBox(height: mediaQuery.size.height * 0.005),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: isSmallScreen ? 10 : 12,
                                    color: context.secondaryTextColor,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      contact.relationship,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 13,
                                        color: context.secondaryTextColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Actions
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Call button
                          Container(
                            height: isSmallScreen ? 35 : 40,
                            width: isSmallScreen ? 35 : 40,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.call,
                                color: Colors.green,
                                size: isSmallScreen ? 20 : 24,
                              ),
                              onPressed: () => _makePhoneCall(contact.phoneNumber),
                              tooltip: 'Call',
                            ),
                          ),

                          SizedBox(height: 4),
                          
                          // Pin/unpin or delete button (only for user contacts)
                          if (!isSystemContact)
                            Container(
                              height: isSmallScreen ? 35 : 40,
                              width: isSmallScreen ? 35 : 40,
                              decoration: BoxDecoration(
                                color: context.isDarkMode 
                                    ? Colors.grey.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.more_vert,
                                  size: isSmallScreen ? 20 : 24,
                                  color: context.secondaryTextColor,
                                ),
                                onSelected: (value) async {
                                  final appProvider = Provider.of<AppProvider>(
                                    context,
                                    listen: false,
                                  );

                                  if (value == 'pin') {
                                    await appProvider.toggleContactPinStatus(
                                      contact.id,
                                      !contact.isPinned,
                                    );
                                  } else if (value == 'delete') {
                                    _confirmDeleteContact(contact);
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      PopupMenuItem(
                                        value: 'pin',
                                        child: Row(
                                          children: [
                                            Icon(
                                              contact.isPinned
                                                  ? Icons.push_pin_outlined
                                                  : Icons.push_pin,
                                              size: 18,
                                              color:
                                                  contact.isPinned
                                                      ? Colors.grey
                                                      : AppConstants.primaryColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              contact.isPinned
                                                  ? 'Unpin Contact'
                                                  : 'Pin Contact',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Delete Contact'),
                                          ],
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
              ),
            ),
          ),
        );
      },
    );
  }

  // Build contacts tab
  Widget _buildContactsTab() {
    final mediaQuery = MediaQuery.of(context);
    final horizontalPadding = mediaQuery.size.width * 0.04;
    final bottomPadding = mediaQuery.size.height * 0.1; // For FAB

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_contacts.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double iconSize = constraints.maxWidth * 0.2;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize * 1.5,
                  height: iconSize * 1.5,
                  decoration: BoxDecoration(
                    color: context.isDarkMode 
                        ? AppConstants.primaryColor.withOpacity(0.1)
                        : AppConstants.primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.contacts_outlined, 
                      size: iconSize, 
                      color: AppConstants.primaryColor.withOpacity(0.5),
                    ),
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.04),
                Text(
                  'No Emergency Contacts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.02),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Text(
                    'Add important contacts that you might need in emergency situations',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: context.secondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.05),
                ElevatedButton.icon(
                  onPressed: _showAddContactDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Your First Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Filter contacts by system and user
    final systemContacts =
        _contacts.where((c) => c.userId == 'system').toList();
    final userContacts = _contacts.where((c) => c.userId != 'system').toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        mediaQuery.size.height * 0.01,
        horizontalPadding,
        bottomPadding,
      ),
      children: [
        // System contacts section
        if (systemContacts.isNotEmpty) ...[
          Container(
            margin: EdgeInsets.symmetric(
              vertical: mediaQuery.size.height * 0.015,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.red.withOpacity(0.2),
                  Colors.red.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_hospital_outlined,
                  size: 20,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Emergency Services',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width < 360 ? 14 : 16,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
          ...systemContacts.map(
            (contact) => _buildContactCard(
              contact,
              horizontalPadding: horizontalPadding,
            ),
          ),
          Divider(
            height: mediaQuery.size.height * 0.04,
            thickness: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
        ],

        // User contacts section
        if (userContacts.isNotEmpty) ...[
          Container(
            margin: EdgeInsets.symmetric(
              vertical: mediaQuery.size.height * 0.015,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppConstants.primaryColor.withOpacity(0.2),
                  AppConstants.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 20,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'My Contacts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width < 360 ? 14 : 16,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
          ...userContacts.map(
            (contact) => _buildContactCard(
              contact,
              horizontalPadding: horizontalPadding,
            ),
          ),
        ],
      ],
    );
  }

  // Build the quick dial tab
  Widget _buildQuickDialTab() {
    final mediaQuery = MediaQuery.of(context);
    final bool isSmallScreen = mediaQuery.size.width < 360;
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive grid layout
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        // Determine grid columns based on orientation and screen size
        final int crossAxisCount;
        final double childAspectRatio;

        if (isLandscape) {
          // Landscape mode has more horizontal space
          crossAxisCount = availableWidth > 600 ? 4 : 3;
          childAspectRatio = 1.3;
        } else {
          // Portrait mode
          crossAxisCount = availableWidth > 600 ? 3 : 2;
          childAspectRatio = isSmallScreen ? 0.9 : 1.0;
        }

        // Calculate responsive padding and spacing
        final double padding = availableWidth * 0.04;
        final double spacing = availableWidth * 0.02;

        return GridView.count(
          physics: const BouncingScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          padding: EdgeInsets.all(padding),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          children: [
            _buildQuickDialCard(
              title: 'Ambulance',
              phoneNumber: '108',
              icon: Icons.emergency,
              color: Colors.red,
              constraints: constraints,
            ),
            _buildQuickDialCard(
              title: 'Emergency',
              phoneNumber: '112',
              icon: Icons.phone_in_talk,
              color: Colors.orange,
              constraints: constraints,
            ),
            _buildQuickDialCard(
              title: 'Blood Bank',
              phoneNumber: '104',
              icon: Icons.bloodtype,
              color: AppConstants.primaryColor,
              constraints: constraints,
            ),
            _buildQuickDialCard(
              title: 'Police',
              phoneNumber: '100',
              icon: Icons.local_police,
              color: Colors.blue[800]!,
              constraints: constraints,
            ),
            _buildQuickDialCard(
              title: 'Fire',
              phoneNumber: '101',
              icon: Icons.local_fire_department,
              color: Colors.deepOrange,
              constraints: constraints,
            ),
            _buildQuickDialCard(
              title: 'Women Helpline',
              phoneNumber: '1091',
              icon: Icons.people,
              color: Colors.purple,
              constraints: constraints,
            ),
          ],
        );
      },
    );
  }

  // Build a quick dial card
  Widget _buildQuickDialCard({
    required String title,
    required String phoneNumber,
    required IconData icon,
    required Color color,
    required BoxConstraints constraints,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final bool isSmallScreen = mediaQuery.size.width < 360;
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.isDarkMode 
                  ? context.cardColor
                  : Colors.white,
              context.isDarkMode 
                  ? Colors.grey.withOpacity(0.05)
                  : color.withOpacity(0.05),
            ],
            stops: const [0.8, 1.0],
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _makePhoneCall(phoneNumber),
            child: Padding(
              padding: EdgeInsets.all(constraints.maxWidth * 0.02),
              child: LayoutBuilder(
                builder: (context, cardConstraints) {
                  // Calculate responsive sizes based on available card space
                  final double iconSize = cardConstraints.maxWidth * 0.3;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon container with flexible sizing
                      Container(
                        height: cardConstraints.maxHeight * 0.45,
                        width: iconSize,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.15),
                              color.withOpacity(0.25),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(icon, color: color, size: iconSize * 0.6),
                        ),
                      ),

                      // Flexible spacing
                      SizedBox(height: cardConstraints.maxHeight * 0.05),

                      // Title with fitted text
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                          color: context.textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Phone number with call icon
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.call,
                              size: isSmallScreen ? 12 : 14,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              phoneNumber,
                              style: TextStyle(
                                color: color,
                                fontSize: isSmallScreen ? 13 : 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final tabIconSize = isSmallScreen ? 20.0 : 24.0;
    final tabLabelFontSize = isSmallScreen ? 11.0 : 14.0;

    // Use a safe area to avoid system intrusions
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: const Text('Emergency Contacts'),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor, 
                  Colors.redAccent.shade700
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3.0,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            dividerColor: Colors.transparent,
            // Add tab indicator decoration
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.white.withOpacity(0.2),
            ),
            splashBorderRadius: BorderRadius.circular(50),
            tabs: [
              Tab(
                icon: Icon(Icons.contacts, size: tabIconSize),
                child: Text(
                  'Contacts',
                  style: TextStyle(
                    fontSize: tabLabelFontSize,
                  ),
                ),
              ),
              Tab(
                icon: Icon(Icons.call, size: tabIconSize),
                child: Text(
                  'Quick Dial',
                  style: TextStyle(
                    fontSize: tabLabelFontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildContactsTab(), _buildQuickDialTab()],
        ),
        floatingActionButton: Container(
          height: mediaQuery.size.height * 0.06,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _showAddContactDialog,
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Add Contact',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
