import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class CreateCustomReminderPage extends StatefulWidget {
  const CreateCustomReminderPage({super.key});

  @override
  State<CreateCustomReminderPage> createState() =>
      _CreateCustomReminderPageState();
}

class _CreateCustomReminderPageState extends State<CreateCustomReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _selectedVehicleId;
  Map<String, dynamic>? _selectedVehicleData;
  String? _selectedServiceType;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedNotificationTime;
  bool _isLoading = false;

  final List<String> serviceTypes = [
    'Oil Change',
    'Tire Rotation',
    'Brake Inspection',
    'Battery Check',
    'Fluid Top-Up',
    'Air Filter Replacement',
    'Spark Plug Replacement',
    'Transmission Service',
  ];

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  @override
  Widget build(BuildContext context) {
    // Handle null user
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Test Reminder'),
          backgroundColor: Colors.amber,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Please log in to create reminders.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Test Reminder',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    const Text(
                      'Date & Time Reminder',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Vehicle dropdown
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid!)
                              .collection('vehicles')
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Text(
                              'Error loading vehicles: ${snapshot.error}',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: const Text(
                              'No vehicles found. Please add a vehicle first.',
                              style: TextStyle(color: Colors.orange),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        final vehicles = snapshot.data!.docs;

                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select Vehicle',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.directions_car),
                          ),
                          value: _selectedVehicleId,
                          isExpanded: true, // Prevent overflow
                          items:
                              vehicles.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final vehicleName =
                                    '${data['make'] ?? 'Unknown'} ${data['model'] ?? 'Vehicle'}';
                                return DropdownMenuItem(
                                  value: doc.id,
                                  child: Text(
                                    vehicleName,
                                    overflow:
                                        TextOverflow
                                            .ellipsis, // Prevent overflow
                                  ),
                                );
                              }).toList(),
                          onChanged:
                              _isLoading
                                  ? null
                                  : (val) {
                                    setState(() {
                                      _selectedVehicleId = val;
                                      _selectedVehicleData =
                                          vehicles
                                                  .firstWhere(
                                                    (doc) => doc.id == val!,
                                                  )
                                                  .data()
                                              as Map<String, dynamic>;
                                    });
                                  },
                          validator:
                              (val) =>
                                  val == null
                                      ? 'Please select a vehicle'
                                      : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Service Type Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Service Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.build),
                      ),
                      value: _selectedServiceType,
                      isExpanded: true, // Prevent overflow
                      items:
                          serviceTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                overflow:
                                    TextOverflow.ellipsis, // Prevent overflow
                              ),
                            );
                          }).toList(),
                      onChanged:
                          _isLoading
                              ? null
                              : (val) =>
                                  setState(() => _selectedServiceType = val),
                      validator:
                          (val) =>
                              val == null
                                  ? 'Please select a service type'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    // Due Date Picker
                    InkWell(
                      onTap: _isLoading ? null : _selectDueDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Due Date',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon:
                              _selectedDueDate != null
                                  ? IconButton(
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : () {
                                              setState(() {
                                                _selectedDueDate = null;
                                              });
                                            },
                                    icon: const Icon(Icons.clear),
                                  )
                                  : null,
                        ),
                        child: Text(
                          _selectedDueDate != null
                              ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                              : 'Select due date',
                          style: TextStyle(
                            color:
                                _selectedDueDate != null
                                    ? Colors.black
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notification Time Picker
                    InkWell(
                      onTap: _isLoading ? null : _selectNotificationTime,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Notification Time',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.access_time),
                          suffixIcon:
                              _selectedNotificationTime != null
                                  ? IconButton(
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : () {
                                              setState(() {
                                                _selectedNotificationTime =
                                                    null;
                                              });
                                            },
                                    icon: const Icon(Icons.clear),
                                  )
                                  : null,
                        ),
                        child: Text(
                          _selectedNotificationTime != null
                              ? _selectedNotificationTime!.format(context)
                              : 'Select notification time',
                          style: TextStyle(
                            color:
                                _selectedNotificationTime != null
                                    ? Colors.black
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Preview section
                    if (_selectedDueDate != null &&
                        _selectedNotificationTime != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.schedule, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Reminder Preview',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You will be notified on ${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year} at ${_selectedNotificationTime!.format(context)}',
                              style: TextStyle(
                                color: Colors.amber.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Create Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitReminder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                              : const Text(
                                'Create Test Reminder',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Colors.amber),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _selectNotificationTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Colors.amber),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedNotificationTime) {
      setState(() {
        _selectedNotificationTime = picked;
      });
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
  }) async {
    try {
      final tz.TZDateTime tzDateTime = tz.TZDateTime.from(
        scheduledDateTime,
        tz.local,
      );

      if (tzDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
        print('Warning: Scheduled time is in the past');
        return;
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'autocare_reminders',
            'AutoCare Reminders',
            channelDescription:
                'Notifications for vehicle maintenance reminders',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            color: Colors.amber,
            icon: '@mipmap/ic_launcher',
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      print('Notification scheduled for: $tzDateTime');
    } catch (e) {
      print('Error scheduling notification: $e');
      rethrow;
    }
  }

  Future<void> _submitReminder() async {
    // Custom validation for date and time
    if (_selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a due date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedNotificationTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a notification time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Combine date and time for the notification
      final notificationDateTime = DateTime(
        _selectedDueDate!.year,
        _selectedDueDate!.month,
        _selectedDueDate!.day,
        _selectedNotificationTime!.hour,
        _selectedNotificationTime!.minute,
      );

      // Check if notification time is in the future
      if (notificationDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification time must be in the future'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Generate unique ID for the reminder
      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Save to Firestore first
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid!)
          .collection('reminders')
          .add({
            'vehicleId': _selectedVehicleId,
            'serviceType': _selectedServiceType,
            'dueDate': _selectedDueDate,
            'notificationTime':
                _selectedNotificationTime != null
                    ? '${_selectedNotificationTime!.hour.toString().padLeft(2, '0')}:${_selectedNotificationTime!.minute.toString().padLeft(2, '0')}'
                    : null,
            'notificationDateTime': notificationDateTime,
            'notificationId': notificationId,
            'currentMileage': _selectedVehicleData?['milage'] ?? 0,
            'isCompleted': false, // Changed to false for active reminders
            'reminderType': 'custom_date',
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Schedule the local notification
      final vehicleName =
          _selectedVehicleData != null
              ? '${_selectedVehicleData!['make']} ${_selectedVehicleData!['model']}'
              : 'Your vehicle';

      await _scheduleNotification(
        id: notificationId,
        title: 'AutoCare Reminder',
        body: '$_selectedServiceType due for $vehicleName',
        scheduledDateTime: notificationDateTime,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminder created and notification scheduled for ${notificationDateTime.day}/${notificationDateTime.month}/${notificationDateTime.year} at ${_selectedNotificationTime!.format(context)}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error creating reminder: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
