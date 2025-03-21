import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/donation_model.dart';
import '../utils/theme_helper.dart';

class DonationCard extends StatelessWidget {
  final DonationModel donation;
  final bool showActions;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onContactRecipient;
  final VoidCallback? onCancel;
  final bool isDonor;
  final bool isAccepted;

  const DonationCard({
    super.key,
    required this.donation,
    this.showActions = false,
    this.actionLabel,
    this.onAction,
    this.onContactRecipient,
    this.onCancel,
    this.isDonor = true,
    this.isAccepted = false,
  });

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor() {
    switch (donation.status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'scheduled':
        return Colors.blue.shade600;
      case 'completed':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDarkMode ? 4 : 3,
      shadowColor: _getStatusColor().withOpacity(isDarkMode ? 0.4 : 0.3),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _getStatusColor().withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator bar at the top
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Blood type badge
                    _buildBloodTypeBadge(donation.bloodType, isDarkMode),
                    const SizedBox(width: 8),
                    // Center name with icon
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_hospital,
                            size: 16,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              donation.centerName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: context.textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    _buildStatusBadge(donation.status),
                  ],
                ),
                const SizedBox(height: 16),
                // Information rows with better organization
                _buildInfoSection(context),

                // Action buttons section
                if (showActions) ...[
                  const SizedBox(height: 16),
                  _buildActionButtons(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced blood type badge
  Widget _buildBloodTypeBadge(String bloodType, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? AppConstants.primaryColor.withOpacity(0.25) 
          : AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode 
            ? AppConstants.primaryColor.withOpacity(0.5)
            : AppConstants.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        bloodType,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode 
            ? AppConstants.primaryColor.withAlpha(240)
            : AppConstants.primaryColor,
          fontSize: 15,
        ),
      ),
    );
  }

  // Enhanced status badge
  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor().withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Organized information section
  Widget _buildInfoSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? Theme.of(context).cardColor.withOpacity(0.5)
          : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode 
            ? Colors.grey.shade800 
            : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (donation.recipientName.isNotEmpty)
            _buildInfoRow(
              icon: Icons.person,
              title: 'Recipient',
              value: donation.recipientName,
              context: context,
            ),
          if (donation.recipientName.isNotEmpty) 
            Divider(
              height: 16, 
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),

          if (donation.donorName.isNotEmpty)
            _buildInfoRow(
              icon: Icons.volunteer_activism,
              title: 'Donor',
              value: donation.donorName,
              context: context,
            ),
          if (donation.donorName.isNotEmpty) 
            Divider(
              height: 16, 
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),

          _buildInfoRow(
            icon: Icons.calendar_today,
            title: 'Date',
            value: _formatDate(donation.date.toString()),
            context: context,
          ),

          if (donation.address.isNotEmpty) ...[
            Divider(
              height: 16, 
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            _buildInfoRow(
              icon: Icons.location_on,
              title: 'Location',
              value: donation.address,
              isLast: true,
              context: context,
            ),
          ],
        ],
      ),
    );
  }

  // Action buttons section with improved styling
  Widget _buildActionButtons(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Row 1: Primary action button (Mark as Complete or Accept Request)
        if (showActions && onAction != null)
          ElevatedButton.icon(
            onPressed: onAction,
            icon: Icon(
              isDonor && isAccepted ? Icons.check_circle : Icons.handshake,
              size: 16,
            ),
            label: Text(
              actionLabel ??
                  (isDonor && isAccepted ? 'Mark as Complete' : 'Accept'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 40),
              elevation: isDarkMode ? 4 : 2,
              shadowColor: isDarkMode 
                ? AppConstants.primaryColor.withOpacity(0.5) 
                : AppConstants.primaryColor.withOpacity(0.3),
            ),
          ),

        if (onContactRecipient != null || 
            (onCancel != null && donation.status.toLowerCase() != 'completed'))
          const SizedBox(height: 8),
          
        // Row 2: Contact and Cancel buttons
        Row(
          children: [
            // Contact button always shows if available
            if (onContactRecipient != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onContactRecipient,
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Contact'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                    side: BorderSide(
                      color: isDarkMode 
                        ? AppConstants.primaryColor.withOpacity(0.8) 
                        : AppConstants.primaryColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            // Spacing between second row buttons
            if (onContactRecipient != null &&
                onCancel != null &&
                donation.status.toLowerCase() != 'completed')
              const SizedBox(width: 8),

            // Cancel button if available and not completed
            if (onCancel != null &&
                donation.status.toLowerCase() != 'completed')
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.red.shade300 : Colors.red,
                    side: BorderSide(
                      color: isDarkMode ? Colors.red.shade300 : Colors.red,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Enhanced info row with better typography
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isLast = false,
    required BuildContext context,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon, 
              size: 16, 
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
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
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
