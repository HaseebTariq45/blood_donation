import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/blood_response_notification_dialog.dart';

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
      case 'test':
        color = Colors.blue.shade700;
        iconData = Icons.notifications;
        break;
      default:
        color = Colors.purple.shade700;
        iconData = Icons.notifications;
    }

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: notification.read
            ? BorderSide.none
            : BorderSide(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          if (notification.type == 'blood_request_response') {
            // Mark notification as read
            onMarkAsRead(notification.id);
            
            // Show blood response dialog with donor details
            showDialog(
              context: context,
              builder: (context) => BloodResponseNotificationDialog(
                responderName: notification.metadata?['responderName'] ?? 'Unknown',
                responderPhone: notification.metadata?['responderPhone'] ?? 'Unknown',
                bloodType: notification.metadata?['bloodType'] ?? 'Unknown',
                responderId: notification.metadata?['responderId'] ?? '',
                requestId: notification.metadata?['requestId'] ?? '',
                onViewRequest: () {
                  // Handle viewing the request
                  Navigator.pop(context);
                  // TODO: Navigate to blood request detail page
                },
              ),
            );
          } else {
            // For other notification types
            onMarkAsRead(notification.id);
            
            // Show a simple dialog for other notification types
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(notification.title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.body),
                    const SizedBox(height: 16),
                    Text(
                      'Received: ${_formatDate(notification.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
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
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with colored background
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(iconData, color: color, size: 24.0),
              ),
              const SizedBox(width: 12.0),
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
                              fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                        if (!notification.read)
                          Container(
                            width: 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _formatDate(notification.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12.0,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
