import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart'; // Ensure this imports your `flutterLocalNotificationsPlugin`

class NotificationDebugButton extends StatelessWidget {
  const NotificationDebugButton({super.key});

  Future<void> _scheduleTestNotification(BuildContext context) async {
    final now = DateTime.now();
    final scheduled = tz.TZDateTime.from(
      now.add(const Duration(seconds: 10)),
      tz.local,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      9999,
      '🔧 Debug Notification',
      'This is a test scheduled for 10 seconds later',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'autocare_reminders',
          'AutoCare Reminders',
          channelDescription: 'Test notification channel',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔔 Test notification scheduled')),
    );

    final pending =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    print('📌 Pending notifications:');
    for (var n in pending) {
      print('${n.id} - ${n.title} - ${n.body} - ${n.payload}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _scheduleTestNotification(context),
      icon: const Icon(Icons.notifications_active),
      label: const Text('Schedule Test Notification'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
    );
  }
}
