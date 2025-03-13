import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../utils/theme_helper.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../models/emergency_contact_model.dart';
import '../models/user_location_model.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class BloodResponseNotificationDialog extends StatefulWidget {
  final String responderName;
  final String responderPhone;
  final String bloodType;
  final String responderId;
  final String requestId;
  final VoidCallback onViewRequest;

  const BloodResponseNotificationDialog({
    super.key,
    required this.responderName,
    required this.responderPhone,
    required this.bloodType,
    required this.responderId,
    required this.requestId,
    required this.onViewRequest,
  });

  @override
  State<BloodResponseNotificationDialog> createState() =>
      _BloodResponseNotificationDialogState();
}

class _BloodResponseNotificationDialogState
    extends State<BloodResponseNotificationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  bool _showContactOptions = false;
  String? _copiedText;
  Timer? _copyTimer;
  bool _isLoading = false;
  bool _showingContacts = false;
  bool _showingLocation = false;
  UserModel? _responderDetails;
  List<EmergencyContactModel> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Start the animation
    _animationController.forward();

    // Fetch responder details when dialog opens
    _fetchResponderDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _copyTimer?.cancel();
    super.dispose();
  }

  // Fetch responder details including location
  Future<void> _fetchResponderDetails() async {
    if (widget.responderId.isEmpty) {
      debugPrint('BloodResponseNotificationDialog - Error: Empty responderId provided');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Debug logging
      debugPrint('BloodResponseNotificationDialog - Fetching details for responder ID: ${widget.responderId}');

      // Get responder user details
      final userDetails = await appProvider.getUserDetailsById(widget.responderId);
      if (userDetails != null) {
        debugPrint('BloodResponseNotificationDialog - Successfully retrieved user details');
        if (mounted) {
          setState(() {
            _responderDetails = userDetails;
          });
        }
      } else {
        debugPrint('BloodResponseNotificationDialog - Failed to retrieve user details (null returned)');
      }

      // Get emergency contacts
      final contacts = await appProvider.getEmergencyContactsForUser(widget.responderId);
      debugPrint('BloodResponseNotificationDialog - Retrieved ${contacts.length} emergency contacts');
      
      if (mounted) {
        setState(() {
          _emergencyContacts = contacts;
        });
      }
    } catch (e) {
      debugPrint('BloodResponseNotificationDialog - Error fetching responder details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Accept the donation
  Future<void> _acceptDonation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.acceptBloodRequestResponse(
        widget.requestId, 
        widget.responderId,
      );

      // Show success message and close dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation accepted! Location has been shared with the donor.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      debugPrint('Error accepting donation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting donation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await url_launcher.launchUrl(launchUri);
  }

  // Function to send SMS
  Future<void> _sendSMS(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    await url_launcher.launchUrl(launchUri);
  }

  // Function to copy text to clipboard
  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() {
      _copiedText = label;
    });

    // Reset the copied text after 2 seconds
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedText = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size to make dialog responsive
    final screenSize = MediaQuery.of(context).size;
    final maxDialogWidth = screenSize.width * 0.9;
    final maxDialogHeight = screenSize.height * 0.85;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxDialogWidth,
            maxHeight: maxDialogHeight,
          ),
          child: _buildDialogContent(context),
        ),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Stack(
      children: [
        // Main container
        Container(
          padding: const EdgeInsets.only(
            top: 65,
            bottom: 16,
            left: 16,
            right: 16,
          ),
          margin: const EdgeInsets.only(top: 45),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Blood Donation Response',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.responderName} has responded to your blood request',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Responder details card - more compact
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Responder info
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCompactInfoRow(
                                  context: context,
                                  icon: Icons.person,
                                  title: 'Name',
                                  value: widget.responderName,
                                  color: AppConstants.primaryColor,
                                ),
                                const SizedBox(height: 8),
                                _buildCompactInfoRow(
                                  context: context,
                                  icon: Icons.bloodtype,
                                  title: 'Blood Type',
                                  value: widget.bloodType,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 8),
                                _buildCompactInfoRow(
                                  context: context,
                                  icon: Icons.phone,
                                  title: 'Phone',
                                  value: widget.responderPhone,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                          // Quick action buttons
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildQuickActionButton(
                                  icon: Icons.call,
                                  label: 'Call',
                                  color: Colors.green,
                                  onTap: () => _makePhoneCall(widget.responderPhone),
                                ),
                                const SizedBox(height: 8),
                                _buildQuickActionButton(
                                  icon: Icons.message,
                                  label: 'SMS',
                                  color: Colors.blue,
                                  onTap: () => _sendSMS(widget.responderPhone),
                                ),
                                const SizedBox(height: 8),
                                _buildQuickActionButton(
                                  icon: Icons.content_copy,
                                  label: 'Copy',
                                  color: Colors.orange,
                                  onTap: () => _copyToClipboard(widget.responderPhone, 'Phone'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Toggle buttons for additional info
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              icon: Icons.contact_emergency,
                              label: 'Emergency Contacts',
                              color: Colors.orange,
                              isSelected: _showingContacts,
                              onTap: () {
                                setState(() {
                                  _showingContacts = !_showingContacts;
                                  if (_showingContacts) {
                                    _showingLocation = false;
                                    
                                    // If we don't have contacts yet, fetch them
                                    if (_emergencyContacts.isEmpty && !_isLoading) {
                                      _fetchEmergencyContacts();
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildToggleButton(
                              icon: Icons.location_on,
                              label: 'Location',
                              color: Colors.purple,
                              isSelected: _showingLocation,
                              onTap: () {
                                setState(() {
                                  _showingLocation = !_showingLocation;
                                  if (_showingLocation) {
                                    _showingContacts = false;
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      // Conditionally show location or contacts
                      if (_showingLocation && _responderDetails?.location != null)
                        _buildCompactLocationSection(),
                      if (_showingContacts)
                        _isLoading && _emergencyContacts.isEmpty
                          ? _buildLoadingIndicator()
                          : _emergencyContacts.isNotEmpty
                            ? _buildCompactEmergencyContactsSection()
                            : _buildNoContactsMessage(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Action buttons - simplified to just two main actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppConstants.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'DISMISS',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _acceptDonation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.successColor,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'ACCEPT',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Top circular avatar with pulse animation
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: CircleAvatar(
                  backgroundColor: AppConstants.primaryColor,
                  radius: 45,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.primaryColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.volunteer_activism,
                      color: AppConstants.primaryColor,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Copied text indicator
        if (_copiedText != null)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$_copiedText copied',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // New compact info row for basic details
  Widget _buildCompactInfoRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Quick action button for the right side of the card
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toggle button for showing/hiding additional sections
  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact location section
  Widget _buildCompactLocationSection() {
    final location = _responderDetails?.location;
    if (location == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.purple, size: 14),
              const SizedBox(width: 4),
              const Text(
                'Location',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.purple,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () async {
                  final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
                  if (await url_launcher.canLaunch(url)) {
                    await url_launcher.launch(url);
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map, color: Colors.purple, size: 12),
                    SizedBox(width: 2),
                    Text(
                      'Open Maps',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 8, thickness: 0.5),
          Text(
            location.address ?? 'Address not available',
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Compact emergency contacts section
  Widget _buildCompactEmergencyContactsSection() {
    if (_emergencyContacts.isEmpty) return const SizedBox.shrink();
    
    // Show the first contact
    final contact = _emergencyContacts.first;
    final hasMultipleContacts = _emergencyContacts.length > 1;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contact_emergency, color: Colors.orange, size: 14),
              const SizedBox(width: 4),
              Text(
                'Emergency Contact${hasMultipleContacts ? 's' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.orange,
                ),
              ),
              if (hasMultipleContacts) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_emergencyContacts.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Divider(height: 8, thickness: 0.5),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      contact.phoneNumber,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final url = 'tel:${contact.phoneNumber}';
                      if (await url_launcher.canLaunch(url)) {
                        await url_launcher.launch(url);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone, color: Colors.green, size: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final url = 'sms:${contact.phoneNumber}';
                      if (await url_launcher.canLaunch(url)) {
                        await url_launcher.launch(url);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.message, color: Colors.blue, size: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Show "View All" button if there are multiple contacts
          if (hasMultipleContacts) ...[
            const Divider(height: 12, thickness: 0.5),
            InkWell(
              onTap: _showAllContacts,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.people,
                      size: 12,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'View All ${_emergencyContacts.length} Contacts',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAllContacts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Contacts'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _emergencyContacts.length,
            itemBuilder: (context, index) {
              final contact = _emergencyContacts[index];
              return ListTile(
                title: Text(contact.name),
                subtitle: Text(contact.phoneNumber),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: () async {
                        final url = 'tel:${contact.phoneNumber}';
                        if (await url_launcher.canLaunch(url)) {
                          await url_launcher.launch(url);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.message, color: Colors.blue),
                      onPressed: () async {
                        final url = 'sms:${contact.phoneNumber}';
                        if (await url_launcher.canLaunch(url)) {
                          await url_launcher.launch(url);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Loading contacts...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoContactsMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          const Text(
            'No emergency contacts available',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  void _fetchEmergencyContacts() async {
    if (widget.responderId.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // Get emergency contacts
      final contacts = await appProvider.getEmergencyContactsForUser(widget.responderId);
      
      if (mounted) {
        setState(() {
          _emergencyContacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching emergency contacts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

