import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '/helpers/notification_helper.dart';
// Import your NotificationHelper
// Remove permission_handler import if causing issues

import 'widgets/app_scaffold.dart';
import 'views/login/login_page.dart';
import 'views/splash_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handle background notifications
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  print("Background message received: ${message.messageId}");
  print("Message data: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationHelper.initialize();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

  await _requestNotificationPermissions();
  // Malaysia

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // ✅ Initialize local notifications
  await _initializeNotifications();

  // ✅ Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Setup FCM
  await _setupFCM();

  runApp(const MyApp());
}

Future<void> _initializeNotifications() async {
  // ✅ Request notification permissions first

  // ✅ Android notification setup
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // ✅ iOS notification setup
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  // ✅ Initialize with callback for when notification is tapped
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      print('Notification tapped: ${response.payload}');
      // Handle notification tap here
    },
  );

  // ✅ Create notification channel for Android
  await _createNotificationChannel();
}

Future<void> _createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'autocare_reminders', // Channel ID
    'AutoCare Reminders', // Channel name
    description: 'Notifications for vehicle maintenance reminders',
    importance: Importance.high,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

Future<void> _requestNotificationPermissions() async {
  // ✅ For Android, request notification permissions using the plugin
  final androidImplementation =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  if (androidImplementation != null) {
    final bool? granted =
        await androidImplementation.requestNotificationsPermission();
    print('Android notification permission granted: $granted');

    // Request exact alarms permission for Android 12+
    final bool? exactAlarmGranted =
        await androidImplementation.requestExactAlarmsPermission();
    print('Android exact alarm permission granted: $exactAlarmGranted');
  }
}

Future<void> _setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // ✅ Request FCM permissions
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );

  print('FCM Permission status: ${settings.authorizationStatus}');

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }

  // ✅ Get FCM token
  try {
    String? token = await messaging.getToken();
    print('FCM Token: $token');
    // Save this token to your backend if needed
  } catch (e) {
    print('Error getting FCM token: $e');
  }

  // ✅ Handle token refresh
  messaging.onTokenRefresh.listen((String token) {
    print('FCM Token refreshed: $token');
    // Update token in your backend
  });

  // ✅ Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Foreground message received: ${message.messageId}');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Notification Title: ${message.notification!.title}');
      print('Notification Body: ${message.notification!.body}');

      // ✅ Show local notification for foreground messages
      _showLocalNotification(
        title: message.notification!.title ?? 'AutoCare Reminder',
        body: message.notification!.body ?? 'You have a new reminder',
        payload: message.data.toString(),
      );
    }
  });

  // ✅ Handle notification taps when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Message clicked: ${message.messageId}');
    // Navigate to specific screen based on message data
    _handleNotificationTap(message.data);
  });

  // ✅ Check if app was opened from a terminated state by tapping notification
  RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    print(
      'App opened from terminated state by notification: ${initialMessage.messageId}',
    );
    _handleNotificationTap(initialMessage.data);
  }
}

Future<void> _showLocalNotification({
  required String title,
  required String body,
  String? payload,
}) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'autocare_reminders',
        'AutoCare Reminders',
        channelDescription: 'Notifications for vehicle maintenance reminders',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        color: Colors.amber,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
    title,
    body,
    platformChannelSpecifics,
    payload: payload,
  );
}

Future<void> scheduleCustomReminderNotification({
  required String title,
  required String body,
  required DateTime scheduledDate,
  String? payload,
}) async {
  final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
    scheduledDate,
    tz.local,
  );

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'autocare_reminders',
    'AutoCare Reminders',
    channelDescription: 'Notifications for vehicle maintenance reminders',
    importance: Importance.high,
    priority: Priority.high,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
    title,
    body,
    scheduledTZDate,
    platformDetails,
    matchDateTimeComponents: DateTimeComponents.time, // Optional
    payload: payload,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );

  print('✅ Custom reminder scheduled at: $scheduledTZDate');
}

void _handleNotificationTap(Map<String, dynamic> data) {
  print('Handling notification tap with data: $data');
  // Add your navigation logic here based on the notification data
  // For example:
  // if (data['type'] == 'reminder') {
  //   // Navigate to reminders page
  // }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 3)); // Splash delay
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoCare',
      theme: ThemeData(
        fontFamily: 'Montserrat',
        scaffoldBackgroundColor: const Color.fromRGBO(234, 234, 234, 100),
        primarySwatch: Colors.amber,
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.amber, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(foregroundColor: Colors.amber),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashScreen();
          }
          return AuthGate();
        },
      ),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const AppScaffold(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return const AppScaffold();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
