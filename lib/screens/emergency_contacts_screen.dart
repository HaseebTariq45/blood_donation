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
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            side:
                contact.isPinned
                    ? BorderSide(color: AppConstants.primaryColor, width: 1.5)
                    : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            onTap: () => _makePhoneCall(contact.phoneNumber),
            child: Padding(
              padding: EdgeInsets.all(mediaQuery.size.width * 0.035),
              child: Row(
                children: [
                  // Contact avatar
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withOpacity(0.1),
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
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            if (contact.isPinned)
                              Padding(
                                padding: EdgeInsets.only(left: spacing * 0.5),
                                child: Icon(
                                  Icons.push_pin,
                                  size: isSmallScreen ? 14 : 16,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: mediaQuery.size.height * 0.005),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            contact.phoneNumber,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                        if (contact.relationship.isNotEmpty) ...[
                          SizedBox(height: mediaQuery.size.height * 0.005),
                          Text(
                            contact.relationship,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      SizedBox(
                        height: isSmallScreen ? 35 : 40,
                        width: isSmallScreen ? 35 : 40,
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

                      // Pin/unpin or delete button (only for user contacts)
                      if (!isSystemContact)
                        SizedBox(
                          height: isSmallScreen ? 35 : 40,
                          width: isSmallScreen ? 35 : 40,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.more_vert,
                              size: isSmallScreen ? 20 : 24,
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
          final iconSize = constraints.maxWidth * 0.2;
          final double fontSize1 = constraints.maxWidth * 0.045;
          final double fontSize2 = constraints.maxWidth * 0.035;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.contacts, size: iconSize, color: Colors.grey[400]),
                SizedBox(height: constraints.maxHeight * 0.02),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'No emergency contacts',
                    style: TextStyle(
                      fontSize: fontSize1,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.01),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Add your important contacts here',
                    style: TextStyle(
                      fontSize: fontSize2,
                      color: Colors.grey[500],
                    ),
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
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: mediaQuery.size.height * 0.01,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Emergency Services',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: mediaQuery.size.width < 360 ? 14 : 16,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          ...systemContacts.map(
            (contact) => _buildContactCard(
              contact,
              horizontalPadding: horizontalPadding,
            ),
          ),
          Divider(height: mediaQuery.size.height * 0.04),
        ],

        // User contacts section
        if (userContacts.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: mediaQuery.size.height * 0.01,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'My Contacts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: mediaQuery.size.width < 360 ? 14 : 16,
                  color: Colors.grey[700],
                ),
              ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
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
                    padding: EdgeInsets.all(iconSize * 0.15),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Icon(icon, color: color),
                    ),
                  ),

                  // Flexible spacing
                  SizedBox(height: cardConstraints.maxHeight * 0.05),

                  // Title with fitted text
                  Expanded(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Phone number with fitted text
                  Expanded(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        phoneNumber,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: isSmallScreen ? 13 : 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: const Text('Emergency Contacts'),
          ),
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppConstants.primaryColor, Colors.redAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorWeight: 3.0,
            tabs: [
              Tab(
                icon: Icon(Icons.contacts, size: tabIconSize),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Contacts',
                    style: TextStyle(
                      fontSize: tabLabelFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Tab(
                icon: Icon(Icons.call, size: tabIconSize),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Quick Dial',
                    style: TextStyle(fontSize: tabLabelFontSize),
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
        floatingActionButton: SizedBox(
          height: mediaQuery.size.height * 0.06,
          child: FittedBox(
            child: FloatingActionButton.extended(
              onPressed: _showAddContactDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
              backgroundColor: AppConstants.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              hoverElevation: 10,
            ),
          ),
        ),
      ),
    );
  }
}
