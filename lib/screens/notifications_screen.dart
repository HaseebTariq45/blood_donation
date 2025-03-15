import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/notification_model.dart';
import '../widgets/notification_card.dart';
import '../widgets/empty_state.dart';
import '../constants/app_constants.dart';
import '../utils/theme_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Use microtask to ensure this runs after the widget is fully built
    Future.microtask(() => _loadNotifications());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get notifications from provider
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.getUserNotifications();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Group notifications by date
  Map<String, List<NotificationModel>> _groupNotificationsByDate(List<NotificationModel> notifications) {
    final Map<String, List<NotificationModel>> grouped = {};
    
    for (final notification in notifications) {
      try {
        final date = DateTime.parse(notification.createdAt);
        final today = DateTime.now();
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        
        String dateKey;
        if (date.year == today.year && date.month == today.month && date.day == today.day) {
          dateKey = 'Today';
        } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
          dateKey = 'Yesterday';
        } else if (today.difference(date).inDays < 7) {
          dateKey = DateFormat('EEEE').format(date); // Day name (e.g., Monday)
        } else {
          dateKey = DateFormat('MMM d, yyyy').format(date); // Month day, year
        }
        
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        
        grouped[dateKey]!.add(notification);
      } catch (e) {
        // If date parsing fails, add to "Other" category
        if (!grouped.containsKey('Other')) {
          grouped['Other'] = [];
        }
        grouped['Other']!.add(notification);
      }
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final bool hasNotifications = appProvider.userNotifications.isNotEmpty;
    final bool hasUnreadNotifications = appProvider.userNotifications.any((notification) => !notification.read);
    final groupedNotifications = _groupNotificationsByDate(appProvider.userNotifications);
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: context.isDarkMode 
                  ? const Color(0xFF1E1E1E) 
                  : AppConstants.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppConstants.primaryColor,
                        AppConstants.primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0, bottom: 60.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications_active,
                                color: Colors.white.withOpacity(0.9),
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                hasUnreadNotifications 
                                    ? 'You have unread notifications' 
                                    : 'All caught up!',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (hasUnreadNotifications)
                  IconButton(
                    icon: const Icon(Icons.done_all, color: Colors.white),
                    tooltip: 'Mark all as read',
                    onPressed: () {
                      appProvider.markAllNotificationsAsRead();
                      // Show a confirmation snackbar
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text('All notifications marked as read'),
                              ],
                            ),
                            backgroundColor: AppConstants.successColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh notifications',
                  onPressed: () {
                    appProvider.refreshNotifications();
                    // Show loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Refreshing notifications...'),
                          ],
                        ),
                        backgroundColor: context.isDarkMode 
                            ? const Color(0xFF2C2C2C) 
                            : Colors.grey[800],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ];
        },
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading notifications...',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await appProvider.refreshNotifications();
                },
                color: AppConstants.primaryColor,
                child: hasNotifications
                    ? ListView.builder(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                        itemCount: groupedNotifications.length,
                        itemBuilder: (context, index) {
                          final dateKey = groupedNotifications.keys.elementAt(index);
                          final notifications = groupedNotifications[dateKey]!;
                          
                          return FadeInUp(
                            duration: Duration(milliseconds: 300 + (index * 100)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        dateKey,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: context.isDarkMode 
                                              ? Colors.white70 
                                              : Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Divider(
                                          color: context.isDarkMode 
                                              ? Colors.white24 
                                              : Colors.grey[300],
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...notifications.asMap().entries.map((entry) {
                                  final notificationIndex = entry.key;
                                  final notification = entry.value;
                                  return FadeInRight(
                                    duration: Duration(milliseconds: 300 + (notificationIndex * 50)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: NotificationCard(
                                        notification: notification,
                                        onMarkAsRead: (id) => appProvider.markNotificationAsRead(id),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          );
                        },
                      )
                    : FadeIn(
                        duration: const Duration(milliseconds: 500),
                        child: EmptyState(
                          icon: Icons.notifications_off_outlined,
                          title: 'No Notifications',
                          message: 'You don\'t have any notifications yet. We\'ll notify you when something important happens.',
                          action: ElevatedButton.icon(
                            onPressed: () {
                              appProvider.refreshNotifications();
                            },
                            icon: Icon(Icons.refresh),
                            label: Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
      ),
    );
  }
}
