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
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Get responder user details
      final userDetails = await appProvider.getUserDetailsById(widget.responderId);
      if (userDetails != null) {
        setState(() {
          _responderDetails = userDetails;
        });
      }

      // Get emergency contacts
      final contacts = await appProvider.getEmergencyContactsForUser(widget.responderId);
      setState(() {
        _emergencyContacts = contacts;
      });
    } catch (e) {
      debugPrint('Error fetching responder details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildDialogContent(context),
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
            bottom: 20,
            left: 20,
            right: 20,
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
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Text(
                  '${widget.responderName} has responded to your blood request',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Responder details card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]!
                              : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        context: context,
                        icon: Icons.person,
                        title: 'Responder',
                        value: widget.responderName,
                        color: AppConstants.primaryColor,
                        onTap:
                            () =>
                                _copyToClipboard(widget.responderName, 'Name'),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context: context,
                        icon: Icons.bloodtype,
                        title: 'Blood Type',
                        value: widget.bloodType,
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context: context,
                        icon: Icons.phone,
                        title: 'Phone Number',
                        value: widget.responderPhone,
                        color: Colors.green,
                        onTap:
                            () => _copyToClipboard(
                              widget.responderPhone,
                              'Phone',
                            ),
                        trailing: _buildContactOptionsButton(),
                      ),
                      // Contact options (conditionally displayed)
                      if (_showContactOptions) ...[
                        const SizedBox(height: 16),
                        _buildContactOptions(),
                      ],
                      // Show location section if available
                      if (_showingLocation && _responderDetails != null)
                        _buildLocationSection(),
                      // Show emergency contacts section
                      if (_showingContacts)
                        _buildEmergencyContactsSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'DISMISS',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onViewRequest();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'VIEW DETAILS',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Action buttons
                _buildActionButtons(),
                const SizedBox(height: 20),
                // Accept button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _acceptDonation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'ACCEPT DONATION',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
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

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null && trailing == null)
              Icon(
                Icons.content_copy,
                size: 16,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildContactOptionsButton() {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      splashRadius: 24,
      onPressed: () {
        setState(() {
          _showContactOptions = !_showContactOptions;
        });
      },
      tooltip: 'Contact options',
    );
  }

  Widget _buildContactOptions() {
    return AnimatedOpacity(
      opacity: _showContactOptions ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildContactButton(
            icon: Icons.call,
            label: 'Call',
            color: Colors.green,
            onPressed: () => _makePhoneCall(widget.responderPhone),
          ),
          _buildContactButton(
            icon: Icons.message,
            label: 'SMS',
            color: Colors.blue,
            onPressed: () => _sendSMS(widget.responderPhone),
          ),
          _buildContactButton(
            icon: Icons.copy,
            label: 'Copy',
            color: Colors.orange,
            onPressed: () => _copyToClipboard(widget.responderPhone, 'Phone'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
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

  Widget _buildLocationSection() {
    final location = _responderDetails?.location;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Donor Location',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(),
          if (location != null) ...[
            Text('Address: ${location.address ?? 'Not available'}'),
            const SizedBox(height: 8),
            Text('Coordinates: ${location.latitude}, ${location.longitude}'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
                  if (await url_launcher.canLaunch(url)) {
                    await url_launcher.launch(url);
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text('Open in Maps'),
              ),
            ),
          ] else
            const Text('Location information not available'),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.contact_emergency, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(),
          if (_emergencyContacts.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _emergencyContacts.length,
              itemBuilder: (context, index) {
                final contact = _emergencyContacts[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(contact.name),
                  subtitle: Text(contact.phoneNumber),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone, size: 20),
                        onPressed: () async {
                          final url = 'tel:${contact.phoneNumber}';
                          if (await url_launcher.canLaunch(url)) {
                            await url_launcher.launch(url);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.message, size: 20),
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
            )
          else
            const Text('No emergency contacts available'),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.phone,
          label: 'Call',
          color: Colors.green,
          onTap: () => _makePhoneCall(widget.responderPhone),
        ),
        _buildActionButton(
          icon: Icons.message,
          label: 'Message',
          color: Colors.blue,
          onTap: () => _sendSMS(widget.responderPhone),
        ),
        _buildActionButton(
          icon: Icons.contact_emergency,
          label: 'Contacts',
          color: Colors.orange,
          onTap: _toggleEmergencyContacts,
          isSelected: _showingContacts,
        ),
        _buildActionButton(
          icon: Icons.location_on,
          label: 'Location',
          color: Colors.purple,
          onTap: _toggleLocation,
          isSelected: _showingLocation,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: color, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleEmergencyContacts() {
    setState(() {
      _showingContacts = !_showingContacts;
      if (_showingContacts) {
        _showingLocation = false;
      }
    });
  }

  void _toggleLocation() {
    setState(() {
      _showingLocation = !_showingLocation;
      if (_showingLocation) {
        _showingContacts = false;
      }
    });
  }
}
