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

  const DonationCard({
    super.key,
    required this.donation,
    this.showActions = false,
    this.actionLabel,
    this.onAction,
    this.onContactRecipient,
    this.onCancel,
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
    return Card(
      elevation: 3,
      shadowColor: _getStatusColor().withOpacity(0.3),
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
                    _buildBloodTypeBadge(donation.bloodType),
                    const SizedBox(width: 8),
                    // Center name with icon
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_hospital,
                            size: 16,
                            color: Colors.grey.shade600,
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
  Widget _buildBloodTypeBadge(String bloodType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        bloodType,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          if (donation.recipientName.isNotEmpty)
            _buildInfoRow(
              icon: Icons.person,
              title: 'Recipient',
              value: donation.recipientName,
            ),
          if (donation.recipientName.isNotEmpty) const Divider(height: 16),

          if (donation.donorName.isNotEmpty)
            _buildInfoRow(
              icon: Icons.volunteer_activism,
              title: 'Donor',
              value: donation.donorName,
            ),
          if (donation.donorName.isNotEmpty) const Divider(height: 16),

          _buildInfoRow(
            icon: Icons.calendar_today,
            title: 'Date',
            value: _formatDate(donation.date.toString()),
          ),

          if (donation.address.isNotEmpty) ...[
            const Divider(height: 16),
            _buildInfoRow(
              icon: Icons.location_on,
              title: 'Location',
              value: donation.address,
              isLast: true,
            ),
          ],
        ],
      ),
    );
  }

  // Action buttons section with improved styling
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (onContactRecipient != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onContactRecipient,
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Contact'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                    side: BorderSide(color: AppConstants.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            if (onContactRecipient != null && onAction != null)
              const SizedBox(width: 12),
            if (onAction != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Icon(
                    donation.status == 'Pending'
                        ? Icons.event
                        : Icons.check_circle,
                    size: 16,
                  ),
                  label: Text(actionLabel ?? 'Action'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        donation.status == 'Pending'
                            ? Colors.blue
                            : Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: (donation.status == 'Pending'
                            ? Colors.blue
                            : Colors.green)
                        .withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (onCancel != null &&
            (donation.status == 'Pending' ||
                donation.status == 'Scheduled')) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('Cancel Donation'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ],
    );
  }

  // Enhanced info row with better typography
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 16, color: Colors.grey[700]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
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
}
