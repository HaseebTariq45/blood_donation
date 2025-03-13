import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // This would be populated from an API in a real app
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Urgent Blood Request',
      'message': 'Blood type A+ needed urgently at Memorial Hospital',
      'time': DateTime.now().subtract(Duration(minutes: 30)),
      'isRead': false,
      'type': 'urgent',
    },
    {
      'id': '2',
      'title': 'Donation Complete',
      'message': 'Thank you for your blood donation. You just saved a life!',
      'time': DateTime.now().subtract(Duration(hours: 4)),
      'isRead': false,
      'type': 'success',
    },
    {
      'id': '3',
      'title': 'New Blood Drive',
      'message': 'There\'s a blood drive happening near you next week',
      'time': DateTime.now().subtract(Duration(days: 1)),
      'isRead': true,
      'type': 'info',
    },
    {
      'id': '4',
      'title': 'Reminder',
      'message': 'You are eligible to donate blood again starting tomorrow!',
      'time': DateTime.now().subtract(Duration(days: 2)),
      'isRead': true,
      'type': 'reminder',
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Mark all notifications as read when this screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.markAllNotificationsAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Notifications',
        showNotificationIcon: false,
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any notifications yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    // Determine the notification color based on type
    Color color;
    IconData iconData;
    
    switch (notification['type']) {
      case 'urgent':
        color = Colors.red;
        iconData = Icons.priority_high;
        break;
      case 'success':
        color = AppConstants.successColor;
        iconData = Icons.check_circle;
        break;
      case 'reminder':
        color = Colors.orange;
        iconData = Icons.access_time;
        break;
      case 'info':
      default:
        color = AppConstants.primaryColor;
        iconData = Icons.info;
        break;
    }
    
    // Format the time
    final now = DateTime.now();
    final time = notification['time'] as DateTime;
    final diff = now.difference(time);
    
    String timeText;
    if (diff.inMinutes < 60) {
      timeText = '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      timeText = '${diff.inHours} hrs ago';
    } else {
      timeText = '${diff.inDays} days ago';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Mark as read when tapped
          setState(() {
            notification['isRead'] = true;
          });
          
          // Show the full notification in a dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(notification['title']),
              content: Text(notification['message']),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!notification['isRead'])
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeText,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
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
}

enum NotificationType {
  urgent,
  event,
  thanks,
  reminder,
  request,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? time,
    bool? isRead,
    NotificationType? type,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}