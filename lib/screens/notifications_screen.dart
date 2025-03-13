import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/notification_model.dart';
import '../widgets/notification_card.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use microtask to ensure this runs after the widget is fully built
    Future.microtask(() => _loadNotifications());
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

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final bool hasNotifications = appProvider.userNotifications.isNotEmpty;
    final bool hasUnreadNotifications = appProvider.userNotifications.any((notification) => !notification.read);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnreadNotifications)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: () {
                appProvider.markAllNotificationsAsRead();
                // Show a confirmation snackbar
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh notifications',
            onPressed: () {
              appProvider.refreshNotifications();
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing notifications...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await appProvider.refreshNotifications();
              },
              child: hasNotifications
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: appProvider.userNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = appProvider.userNotifications[index];
                        return NotificationCard(
                          notification: notification,
                          onMarkAsRead: (id) => appProvider.markNotificationAsRead(id),
                        );
                      },
                    )
                  : const EmptyState(
                      icon: Icons.notifications_none,
                      title: 'No Notifications',
                      message: 'You have no notifications at the moment.',
                    ),
            ),
    );
  }
}
