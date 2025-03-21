import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/blood_request_model.dart';
import '../utils/theme_helper.dart';

class RequestCard extends StatelessWidget {
  final BloodRequestModel request;
  final bool showActions;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onCancel;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const RequestCard({
    super.key,
    required this.request,
    this.showActions = false,
    this.actionLabel,
    this.onAction,
    this.onCancel,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: _getStatusColor(request.status).withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getStatusColor(request.status).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator bar at the top
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(request.status),
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
                    // Blood type badge with improved styling
                    _buildBloodTypeBadge(request.bloodType),
                    const SizedBox(width: 8),
                    // Request title
                    Expanded(
                      child: Text(
                        'Blood Request',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.textColor,
                        ),
                      ),
                    ),
                    // Status badge with improved styling
                    _buildStatusBadge(request.status),
                  ],
                ),
                const SizedBox(height: 16),
                // Information rows with improved spacing and organization
                _buildInfoSection(context),
                if (request.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  // Notes section with better styling
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? Theme.of(context).cardColor.withOpacity(0.3) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.note,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: context.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.notes,
                          style: TextStyle(
                            fontSize: 14,
                            color: context.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Action buttons with improved styling
                if (showActions &&
                    (onAction != null ||
                        onCancel != null ||
                        onSecondaryAction != null)) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;

                      // For smaller screens, buttons need more vertical layout
                      if (availableWidth < 400 && onSecondaryAction != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (onSecondaryAction != null)
                              ElevatedButton.icon(
                                onPressed: onSecondaryAction,
                                icon: const Icon(Icons.info_outline, size: 16),
                                label: Text(
                                  secondaryActionLabel ?? 'View Details',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (onCancel != null)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: onCancel,
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text('Cancel'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                          width: 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (onCancel != null && onAction != null)
                                  const SizedBox(width: 8),
                                if (onAction != null)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: onAction,
                                      icon: const Icon(Icons.check, size: 16),
                                      label: Text(actionLabel ?? 'Action'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppConstants.primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shadowColor: AppConstants.primaryColor
                                            .withOpacity(0.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                          ],
                        );
                      } else {
                        // Default horizontal layout for buttons
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (onSecondaryAction != null) ...[
                              ElevatedButton.icon(
                                onPressed: onSecondaryAction,
                                icon: const Icon(Icons.info_outline, size: 16),
                                label: Text(
                                  secondaryActionLabel ?? 'View Details',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (onCancel != null)
                              OutlinedButton.icon(
                                onPressed: onCancel,
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Cancel'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            if (onAction != null) ...[
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: onAction,
                                icon: const Icon(Icons.check, size: 16),
                                label: Text(actionLabel ?? 'Action'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: AppConstants.primaryColor
                                      .withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      }
                    },
                  ),
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
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: _getStatusColor(status),
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
        color: context.isDarkMode ? Theme.of(context).cardColor.withOpacity(0.3) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, 
          width: 1
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person,
            title: 'Requester',
            value: request.requesterName,
            context: context,
          ),
          const Divider(height: 16),
          _buildInfoRow(
            icon: Icons.phone,
            title: 'Contact',
            value: request.contactNumber,
            context: context,
          ),
          const Divider(height: 16),
          _buildInfoRow(
            icon: Icons.location_on,
            title: 'Location',
            value: request.location,
            context: context,
          ),
          const Divider(height: 16),
          _buildInfoRow(
            icon: Icons.location_city,
            title: 'City',
            value: request.city.isNotEmpty ? request.city : 'Not specified',
            context: context,
          ),
          const Divider(height: 16),
          _buildInfoRow(
            icon: Icons.calendar_today,
            title: 'Requested',
            value: request.formattedDate,
            isLast: true,
            context: context,
          ),
        ],
      ),
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
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon, 
              size: 16, 
              color: context.isDarkMode ? Colors.grey[400] : Colors.grey[700]
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
                    color: context.isDarkMode ? Colors.grey[400] : Colors.grey[600]
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'fulfilled':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      case 'in progress':
        return Colors.blue.shade600;
      case 'accepted':
        return Colors.purple.shade600;
      default:
        return Colors.grey;
    }
  }
}
