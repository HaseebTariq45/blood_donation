import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/app_constants.dart';
import '../widgets/blood_response_notification_dialog.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();

  factory FirebaseNotificationService() => _instance;

  FirebaseNotificationService._internal();

  // Initialize notification settings
  Future<void> initialize(BuildContext? context) async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'User notification permission status: ${settings.authorizationStatus}',
    );

    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: iosInitializationSettings,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        final payload = details.payload;
        if (payload != null && context != null) {
          try {
            final data = json.decode(payload);
            _handleNotificationTap(data, context);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      _showLocalNotification(message);
    });

    // Only setup app-level notification handling if context is available
    if (context != null) {
      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Message opened from background state!');
        _handleNotificationTap(message.data, context);
      });

      // Check for initial notification (app was terminated)
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage.data, context);
      }
    }

    // Subscribe to topics
    await _subscribeToTopics();

    // Save the device token to Firestore
    await _saveDeviceToken();
  }

  // Save device token to user's document
  Future<void> _saveDeviceToken() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
                'deviceTokens': FieldValue.arrayUnion([token]),
                'lastTokenUpdate': DateTime.now().toIso8601String(),
              });
          debugPrint('FCM Token saved: $token');
        }
      }
    } catch (e) {
      debugPrint('Error saving device token: $e');
    }
  }

  // Show a local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'blood_donation_channel',
      'Blood Donation Notifications',
      channelDescription: 'Notifications for blood donation app',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: AppConstants.primaryColor,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond,
        notification.title ?? 'BloodLine Notification',
        notification.body ?? 'You have a new notification',
        details,
        payload: json.encode(data),
      );
    }
  }

  // Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data, BuildContext context) {
    // Skip processing if context is no longer valid
    if (!context.mounted) return;

    // Check notification type
    final String? notificationType = data['type'];

    if (notificationType == 'blood_request_response') {
      final String? requestId = data['requestId'];
      final String? responderName = data['responderName'];
      final String? responderPhone = data['responderPhone'];
      final String? bloodType = data['bloodType'];
      final String? responderId = data['responderId'];
      
      debugPrint('Notification data for blood request response:');
      debugPrint('  requestId: $requestId');
      debugPrint('  responderName: $responderName');
      debugPrint('  responderPhone: $responderPhone');
      debugPrint('  bloodType: $bloodType');
      debugPrint('  responderId: $responderId');

      if (requestId != null &&
          responderName != null &&
          responderPhone != null &&
          responderId != null &&
          responderId.isNotEmpty) {
        // Show response dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => BloodResponseNotificationDialog(
                responderName: responderName,
                responderPhone: responderPhone,
                bloodType: bloodType ?? 'Unknown',
                requestId: requestId,
                responderId: responderId,
                onViewRequest: () {
                  Navigator.of(context, rootNavigator: true).pushNamed(
                    '/blood_requests_list',
                    arguments: {
                      'initialTab': 3,
                      'highlightRequestId': requestId,
                    },
                  );
                },
              ),
        );
      } else {
        // Notify user about missing responder information
        if (responderId == null || responderId.isEmpty) {
          debugPrint('Error: Missing responderId in notification data');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not show details: Missing responder information'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        
        // Fallback - navigate to blood requests list if requestId is available
        if (requestId != null) {
          Navigator.of(context, rootNavigator: true).pushNamed(
            '/blood_requests_list',
            arguments: {'initialTab': 3, 'highlightRequestId': requestId},
          );
        }
      }
    }
  }

  // Send a notification when someone responds to a blood request
  Future<void> sendBloodRequestResponseNotification({
    required String requesterId,
    required String requesterName,
    required String requestId,
    required String responderName,
    required String responderPhone,
    required String bloodType,
  }) async {
    try {
      // 1. Get requester's device tokens from Firestore
      final requesterDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(requesterId)
              .get();

      if (!requesterDoc.exists) {
        debugPrint('Requester document not found');
        return;
      }

      final requesterData = requesterDoc.data();
      if (requesterData == null) return;

      final deviceTokens = requesterData['deviceTokens'];
      if (deviceTokens == null ||
          (deviceTokens is List && deviceTokens.isEmpty)) {
        debugPrint('No device tokens found for requester');
        return;
      }

      // 2. Create the notification in Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': requesterId,
        'title': 'Response to Your Blood Request',
        'body': '$responderName has responded to your blood request',
        'type': 'blood_request_response',
        'requestId': requestId,
        'responderName': responderName,
        'responderPhone': responderPhone,
        'bloodType': bloodType,
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('Blood request response notification created');

      // Note: For actual push notifications, you would need a server-side component
      // with Firebase Cloud Messaging (FCM) to send the notifications to the device tokens.
      // This would typically be done with a Cloud Function or a backend server.

      // For this implementation, we'll rely on Firestore triggers (which you'd implement separately)
      // or the app checking the notifications collection when it opens.
    } catch (e) {
      debugPrint('Error sending blood request response notification: $e');
    }
  }

  Future<void> _subscribeToTopics() async {
    try {
      // Web platforms don't support topic subscription directly
      if (kIsWeb) {
        debugPrint('Topic subscription not supported on web. Skipping...');
        return;
      }
      
      // For mobile platforms, subscribe to topic
      await _firebaseMessaging.subscribeToTopic('blood_requests');
      
      // Subscribe to user-specific topic for targeted notifications
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userTopic = 'user_${currentUser.uid}';
        await _firebaseMessaging.subscribeToTopic(userTopic);
        debugPrint('Subscribed to user-specific topic: $userTopic');
      }
    } catch (e) {
      debugPrint('Error subscribing to topics: $e');
    }
  }
}
