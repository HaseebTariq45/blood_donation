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
            fontSize: 14,
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
    
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;
    
    // Calculate responsive sizes
    final double titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final double messageFontSize = isSmallScreen ? 13.0 : 15.0;
    final double subtitleFontSize = isSmallScreen ? 12.0 : 14.0;
    final double timeFontSize = isSmallScreen ? 10.0 : 12.0;
    final double actionTextFontSize = isSmallScreen ? 10.0 : 12.0;
    
    // Calculate icon sizes
    final double mainIconSize = isSmallScreen ? 60.0 : 70.0;
    final double typeIconSize = isSmallScreen ? 16.0 : 20.0;
    final double actionIconSize = isSmallScreen ? 20.0 : 24.0;
    
    // Calculate padding based on screen size
    final double horizontalPadding = screenWidth * 0.04;
    final double verticalPadding = screenHeight * 0.01;
    final double itemSpacing = isSmallScreen ? 8.0 : 12.0;
    final double cardPadding = isSmallScreen ? 12.0 : 16.0;
    final double iconPadding = isSmallScreen ? 8.0 : 10.0;
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: CustomAppBar(
        title: 'Notifications',
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: Icon(
                Icons.done_all,
                size: actionIconSize,
              ),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _notifications.isEmpty
                ? _buildEmptyState(mainIconSize, titleFontSize, subtitleFontSize, itemSpacing)
                : ListView.builder(
                    padding: EdgeInsets.all(horizontalPadding),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(
                        notification,
                        itemSpacing,
                        cardPadding,
                        titleFontSize,
                        messageFontSize,
                        timeFontSize,
                        typeIconSize,
                        iconPadding,
                        actionTextFontSize
                      );
                    },
                  );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    double iconSize,
    double titleSize,
    double subtitleSize,
    double spacing
  ) {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: iconSize,
              color: context.isDarkMode ? Colors.grey[700] : Colors.grey[400],
            ),
            SizedBox(height: spacing),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            SizedBox(height: spacing * 0.5),
            Text(
              'You\'re all caught up!',
              style: TextStyle(
                fontSize: subtitleSize,
                color: context.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationItem notification,
    double spacing,
    double padding,
    double titleSize,
    double messageSize,
    double timeSize,
    double iconSize,
    double iconPadding,
    double actionTextSize
  ) {
    return Builder(
      builder: (context) => Dismissible(
        key: Key(notification.id),
        background: Container(
          color: AppConstants.errorColor,
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: padding),
          child: Icon(
            Icons.delete,
            color: Colors.white,
            size: iconSize,
          ),
        ),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _deleteNotification(notification.id),
        child: Card(
          margin: EdgeInsets.only(bottom: spacing),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          color: notification.isRead 
              ? context.cardColor 
              : context.isDarkMode 
                  ? AppConstants.accentColor.withOpacity(0.3) 
                  : AppConstants.accentColor.withOpacity(0.1),
          elevation: 1,
          shadowColor: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
          child: InkWell(
            onTap: () => _markAsRead(notification.id),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationIcon(notification.type, iconSize, iconPadding),
                  SizedBox(width: spacing),
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
                                  fontSize: titleSize,
                                  color: context.textColor,
                                ),
                              ),
                            ),
                            Text(
                              _formatTime(notification.time),
                              style: TextStyle(
                                color: context.secondaryTextColor,
                                fontSize: timeSize,
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing * 0.5),
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: notification.isRead 
                                ? context.secondaryTextColor
                                : context.textColor,
                            fontSize: messageSize,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            margin: EdgeInsets.only(top: spacing * 0.75),
                            padding: EdgeInsets.symmetric(
                              horizontal: padding * 0.75,
                              vertical: padding * 0.375,
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
                                fontSize: actionTextSize,
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

  Widget _buildNotificationIcon(
    NotificationType type,
    double iconSize,
    double padding
  ) {
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
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconData,
          color: iconColor,
          size: iconSize,
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