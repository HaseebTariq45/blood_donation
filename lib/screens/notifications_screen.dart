import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme_helper.dart';
import 'dart:math' as math;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Urgent Blood Request',
      message: 'A patient at City Hospital needs A+ blood urgently. Can you help?',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      type: NotificationType.urgent,
    ),
    NotificationItem(
      id: '2',
      title: 'Donation Drive',
      message: 'Join our blood donation drive this Saturday at Community Center from 9 AM to 5 PM.',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: NotificationType.event,
    ),
    NotificationItem(
      id: '3',
      title: 'Thank You!',
      message: 'Your recent blood donation has helped save 3 lives. Thank you for your generosity!',
      time: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
      type: NotificationType.thanks,
    ),
    NotificationItem(
      id: '4',
      title: 'Donation Reminder',
      message: 'It\'s been 3 months since your last donation. You are now eligible to donate again!',
      time: DateTime.now().subtract(const Duration(days: 5)),
      isRead: false,
      type: NotificationType.reminder,
    ),
    NotificationItem(
      id: '5',
      title: 'Blood Request',
      message: 'A patient at Memorial Hospital needs B- blood. Are you available to donate?',
      time: DateTime.now().subtract(const Duration(days: 7)),
      isRead: true,
      type: NotificationType.request,
    ),
  ];

  // Get responsive dimensions based on screen size
  double _getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Scale font size based on screen width, with min and max bounds
    return math.max(baseFontSize * screenWidth / 400, baseFontSize - 2);
  }

  // Get responsive padding based on screen size
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust padding based on screen width
    final horizontalPadding = math.max(16.0, screenWidth * 0.05);
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: math.max(12.0, screenWidth * 0.03),
    );
  }
  
  // Get responsive icon size
  double _getResponsiveIconSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    return math.max(baseSize * screenWidth / 400, baseSize - 2);
  }
  
  // Get responsive spacing
  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    return math.max(baseSpacing * screenWidth / 400, baseSpacing - 2);
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((item) => item.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });

    // Use the AppProvider to update the notification indicator
    Provider.of<AppProvider>(context, listen: false).markAllNotificationsAsRead();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All notifications marked as read',
          style: TextStyle(
            fontSize: _getResponsiveFontSize(context, 14),
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((item) => item.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((item) => !item.isRead).length;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: CustomAppBar(
        title: 'Notifications',
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: Icon(
                Icons.done_all,
                size: _getResponsiveIconSize(context, 24),
              ),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: _getResponsiveIconSize(context, 70),
              color: context.isDarkMode ? Colors.grey[700] : Colors.grey[400],
            ),
            SizedBox(height: _getResponsiveSpacing(context, 16)),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(context, 8)),
            Text(
              'You\'re all caught up!',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 14),
                color: context.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Builder(
      builder: (context) => Dismissible(
        key: Key(notification.id),
        background: Container(
          color: AppConstants.errorColor,
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: _getResponsiveSpacing(context, 20)),
          child: Icon(
            Icons.delete,
            color: Colors.white,
            size: _getResponsiveIconSize(context, 24),
          ),
        ),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _deleteNotification(notification.id),
        child: Card(
          margin: EdgeInsets.only(bottom: _getResponsiveSpacing(context, 12)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          color: notification.isRead 
              ? context.cardColor 
              : context.isDarkMode 
                  ? AppConstants.accentColor.withOpacity(0.3) 
                  : AppConstants.accentColor,
          elevation: 1,
          shadowColor: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
          child: InkWell(
            onTap: () => _markAsRead(notification.id),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            child: Padding(
              padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationIcon(notification.type),
                  SizedBox(width: _getResponsiveSpacing(context, 16)),
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
                                  fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                                  fontSize: _getResponsiveFontSize(context, 16),
                                  color: context.textColor,
                                ),
                              ),
                            ),
                            Text(
                              _formatTime(notification.time),
                              style: TextStyle(
                                color: context.secondaryTextColor,
                                fontSize: _getResponsiveFontSize(context, 12),
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _getResponsiveSpacing(context, 8)),
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: notification.isRead 
                                ? context.secondaryTextColor
                                : context.textColor,
                            fontSize: _getResponsiveFontSize(context, 14),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            margin: EdgeInsets.only(top: _getResponsiveSpacing(context, 12)),
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveSpacing(context, 12),
                              vertical: _getResponsiveSpacing(context, 6),
                            ),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(AppConstants.radiusL),
                            ),
                            child: Text(
                              'Mark as read',
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: _getResponsiveFontSize(context, 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case NotificationType.urgent:
        iconData = Icons.priority_high;
        iconColor = Colors.red;
        break;
      case NotificationType.request:
        iconData = Icons.bloodtype;
        iconColor = AppConstants.primaryColor;
        break;
      case NotificationType.event:
        iconData = Icons.event;
        iconColor = Colors.blue;
        break;
      case NotificationType.thanks:
        iconData = Icons.favorite;
        iconColor = Colors.pink;
        break;
      case NotificationType.reminder:
        iconData = Icons.access_time;
        iconColor = Colors.amber;
        break;
    }

    return Builder(
      builder: (context) => Container(
        padding: EdgeInsets.all(_getResponsiveSpacing(context, 10)),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconData,
          color: iconColor,
          size: _getResponsiveIconSize(context, 20),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
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