import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_model.dart';
import '../widgets/blood_response_notification_dialog.dart';
import '../constants/app_constants.dart';
import '../utils/theme_helper.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final Function(String) onMarkAsRead;
  final VoidCallback? onDelete;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onMarkAsRead,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the notification color based on type
    Color color;
    IconData iconData;
    
    switch (notification.type) {
      case 'blood_request_response':
        color = Colors.red.shade700;
        iconData = Icons.favorite;
        break;
      case 'donation_reminder':
        color = Colors.orange.shade700;
        iconData = Icons.calendar_today;
        break;
      case 'urgent_request':
        color = Colors.red.shade900;
        iconData = Icons.priority_high;
        break;
      case 'test':
        color = Colors.blue.shade700;
        iconData = Icons.notifications;
        break;
      default:
        color = Colors.purple.shade700;
        iconData = Icons.notifications;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          if (!notification.read)
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: context.isDarkMode 
            ? notification.read 
                ? const Color(0xFF1E1E1E) 
                : const Color(0xFF252525)
            : notification.read 
                ? Colors.white 
                : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        elevation: notification.read ? 0 : 1,
        child: InkWell(
          onTap: () {
            // Provide haptic feedback for better interaction
            HapticFeedback.lightImpact();
            
            if (notification.type == 'blood_request_response') {
              // Mark notification as read
              onMarkAsRead(notification.id);
              
              // Get responder information
              final String? responderId = notification.metadata?['responderId'];
              final String? responderName = notification.metadata?['responderName'];
              final String? responderPhone = notification.metadata?['responderPhone'];
              final String? bloodType = notification.metadata?['bloodType'];
              final String? requestId = notification.metadata?['requestId'];
              
              // Debug log
              debugPrint('Notification card, responder info:');
              debugPrint('  responderId: $responderId (${responderId?.isEmpty == true ? "empty" : "not empty"})');
              debugPrint('  requestId: $requestId');
              
              // Validate responderId
              if (responderId != null && responderId.isNotEmpty) {
                // Show blood response dialog with donor details
                showDialog(
                  context: context,
                  builder: (context) => BloodResponseNotificationDialog(
                    responderName: responderName ?? 'Unknown',
                    responderPhone: responderPhone ?? 'Unknown',
                    bloodType: bloodType ?? 'Unknown',
                    responderId: responderId,
                    requestId: requestId ?? '',
                    onViewRequest: () {
                      // Handle viewing the request
                      Navigator.pop(context);
                      // TODO: Navigate to blood request detail page
                    },
                  ),
                );
              } else {
                // Show error for missing responder ID
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Could not show details: Missing responder information'),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            } else {
              // For other notification types
              onMarkAsRead(notification.id);
              
              // Show a simple dialog for other notification types
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 16,
                          color: context.textColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Received: ${_formatDate(notification.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: context.isDarkMode ? const Color(0xFF252525) : Colors.white,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16.0),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: notification.read
                  ? null
                  : Border.all(
                      color: color.withOpacity(0.5),
                      width: 1.5,
                    ),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with colored background
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(iconData, color: color, size: 24.0),
                ),
                const SizedBox(width: 16.0),
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.read ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 16.0,
                                color: context.textColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          if (!notification.read)
                            Container(
                              width: 10.0,
                              height: 10.0,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: context.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          fontSize: 14.0,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: context.isDarkMode ? Colors.grey[400] : Colors.grey[500],
                              ),
                              SizedBox(width: 4),
                              Text(
                                _formatDate(notification.createdAt),
                                style: TextStyle(
                                  color: context.isDarkMode ? Colors.grey[400] : Colors.grey[500],
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                          if (notification.type == 'blood_request_response')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bloodtype,
                                    color: color,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    notification.metadata?['bloodType'] ?? 'Unknown',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Format timestamp to a readable format
  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}
