import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    print('Notification permission status: $status');
  }

  static Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'autocare_reminders',
      'AutoCare Reminders',
      description: 'Notifications for vehicle maintenance reminders',
      importance: Importance.high,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap here
    // You can navigate to specific screens based on the payload
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    try {
      // Convert to timezone-aware DateTime
      final tz.TZDateTime tzDateTime = tz.TZDateTime.from(
        scheduledDateTime,
        tz.local,
      );

      // Check if the scheduled time is in the future
      if (tzDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
        print('Warning: Cannot schedule notification in the past');
        throw Exception('Scheduled time must be in the future');
      }

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'autocare_reminders',
            'AutoCare Reminders',
            channelDescription: 'Vehicle maintenance reminders',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            color: Colors.amber,
            icon: '@mipmap/ic_launcher',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: BigTextStyleInformation(body),
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      print('✅ Notification scheduled successfully for: $tzDateTime');
      print('📱 Notification ID: $id');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
      rethrow;
    }
  }

  // Method to show immediate notification (for testing)
  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'autocare_reminders',
          'AutoCare Reminders',
          channelDescription: 'Vehicle maintenance reminders',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          color: Colors.amber,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
    print('Notification $id cancelled');
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    print('All notifications cancelled');
  }

  // Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  static Future<bool?> areNotificationsEnabled() async {
    final androidImplementation =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled();
    }
    return null;
  }

  // Request notification permissions (Android 13+)
  static Future<bool?> requestNotificationPermissions() async {
    final androidImplementation =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      return await androidImplementation.requestNotificationsPermission();
    }
    return null;
  }
}
