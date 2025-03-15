import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../utils/theme_helper.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class DonationRequestNotificationDialog extends StatefulWidget {
  final String requesterId;
  final String requesterName;
  final String requesterPhone;
  final String requesterEmail;
  final String requesterBloodType;
  final String requesterAddress;

  const DonationRequestNotificationDialog({
    super.key,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhone,
    required this.requesterEmail,
    required this.requesterBloodType,
    required this.requesterAddress,
  });

  @override
  State<DonationRequestNotificationDialog> createState() =>
      _DonationRequestNotificationDialogState();
}

class _DonationRequestNotificationDialogState
    extends State<DonationRequestNotificationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  bool _showContactOptions = false;
  String? _copiedText;
  Timer? _copyTimer;
  bool _isLoading = false;
  UserModel? _requesterDetails;

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

    // Fetch requester details if needed
    _fetchRequesterDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _copyTimer?.cancel();
    super.dispose();
  }

  // Fetch additional requester details if necessary
  Future<void> _fetchRequesterDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Get user details if available in provider
      _requesterDetails = await appProvider.getUserDetailsById(
        widget.requesterId,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching requester details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to copy text to clipboard with feedback
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));

    setState(() {
      _copiedText = label;
    });

    // Show copied message for 2 seconds
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedText = null;
        });
      }
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  // Launch phone call
  Future<void> _launchCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: widget.requesterPhone);
    if (await url_launcher.canLaunchUrl(phoneUri)) {
      await url_launcher.launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Launch SMS
  Future<void> _launchSms() async {
    final Uri smsUri = Uri(scheme: 'sms', path: widget.requesterPhone);
    if (await url_launcher.canLaunchUrl(smsUri)) {
      await url_launcher.launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch messaging app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Launch email
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: widget.requesterEmail,
      queryParameters: {
        'subject': 'Blood Donation Request Response',
        'body':
            'Hello ${widget.requesterName},\n\nI received your blood donation request...',
      },
    );

    if (await url_launcher.canLaunchUrl(emailUri)) {
      await url_launcher.launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch email app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Accept donation request
  void _acceptDonationRequest() {
    // TODO: Implement donation acceptance
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'You accepted the donation request. The requester will be notified.',
        ),
        backgroundColor: AppConstants.successColor,
      ),
    );
  }

  // Decline donation request
  void _declineDonationRequest() {
    // TODO: Implement donation declination
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You declined the donation request.'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: _buildDialogContent(context),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main content with fixed header, scrollable details, and fixed buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header - Fixed position
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Blood Donation Request',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBloodTypeBadge(widget.requesterBloodType),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Urgent Request',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Needs Assistance',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Requester information - Scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Requester Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Requester details
                          _buildDetailRow(
                            context,
                            Icons.person,
                            'Name',
                            widget.requesterName,
                            onCopy:
                                () => _copyToClipboard(
                                  widget.requesterName,
                                  'Name',
                                ),
                            showCopy: true,
                          ),

                          _buildDetailRow(
                            context,
                            Icons.phone,
                            'Phone',
                            widget.requesterPhone,
                            onCopy:
                                () => _copyToClipboard(
                                  widget.requesterPhone,
                                  'Phone',
                                ),
                            showCopy: true,
                            onCall: _launchCall,
                            showCall: true,
                            onMessage: _launchSms,
                            showMessage: true,
                          ),

                          if (widget.requesterEmail.isNotEmpty)
                            _buildDetailRow(
                              context,
                              Icons.email,
                              'Email',
                              widget.requesterEmail,
                              onCopy:
                                  () => _copyToClipboard(
                                    widget.requesterEmail,
                                    'Email',
                                  ),
                              showCopy: true,
                              onEmail: _launchEmail,
                              showEmail: true,
                            ),

                          _buildDetailRow(
                            context,
                            Icons.location_on,
                            'Address',
                            widget.requesterAddress,
                            onCopy:
                                () => _copyToClipboard(
                                  widget.requesterAddress,
                                  'Address',
                                ),
                            showCopy: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Action buttons - Fixed position at bottom
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color:
                      context.isDarkMode ? Colors.black12 : Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _declineDonationRequest,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'DECLINE',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _acceptDonationRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ACCEPT',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Close button
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: Icon(
                Icons.close,
                color: context.isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: context.cardColor.withOpacity(0.7),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),

          // Copied text indicator
          if (_copiedText != null)
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_copiedText copied to clipboard',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBloodTypeBadge(String bloodType) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppConstants.primaryColor,
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            bloodType,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool showCopy = false,
    Function()? onCopy,
    bool showCall = false,
    Function()? onCall,
    bool showMessage = false,
    Function()? onMessage,
    bool showEmail = false,
    Function()? onEmail,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppConstants.primaryColor, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      context.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.textColor,
                    ),
                  ),
                ),
              ),
              if (showCopy && onCopy != null)
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.copy,
                    size: 18,
                    color: context.secondaryTextColor,
                  ),
                  onPressed: onCopy,
                  tooltip: 'Copy to clipboard',
                ),
              if (showCall && onCall != null)
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                  icon: Icon(Icons.call, size: 18, color: Colors.green),
                  onPressed: onCall,
                  tooltip: 'Call',
                ),
              if (showMessage && onMessage != null)
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                  icon: Icon(Icons.message, size: 18, color: Colors.blue),
                  onPressed: onMessage,
                  tooltip: 'Send message',
                ),
              if (showEmail && onEmail != null)
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                  icon: Icon(Icons.email, size: 18, color: Colors.orange),
                  onPressed: onEmail,
                  tooltip: 'Send email',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
