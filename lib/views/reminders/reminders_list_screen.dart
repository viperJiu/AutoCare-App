import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'create_reminder_screen.dart';
import 'reminder_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_test_reminder.dart';

class ReminderPage extends StatelessWidget {
  ReminderPage({super.key});

  final String? testUserId =
      FirebaseAuth
          .instance
          .currentUser
          ?.uid; // Replace with FirebaseAuth.instance.currentUser.uid

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(testUserId!)
                      .collection('reminders')
                      .orderBy('predictedDate')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No reminders found.'));
                }

                final reminders = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder =
                        reminders[index].data() as Map<String, dynamic>;
                    final serviceType = reminder['serviceType'] ?? 'Unknown';
                    final interval = reminder['intervalMileage'] ?? 0;
                    final targetMileage = reminder['targetMileage'] ?? 0;
                    final currentMileage = reminder['currentMileage'] ?? 0;
                    final predictedDate =
                        (reminder['predictedDate'] as Timestamp?)?.toDate();
                    final vehicleId = reminder['vehicleId'] ?? '';

                    final progress = currentMileage / targetMileage;
                    final clampedProgress = progress.clamp(0.0, 1.0);

                    return FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(testUserId!)
                              .collection('vehicles')
                              .doc(vehicleId)
                              .get(),
                      builder: (context, vehicleSnapshot) {
                        String vehicleName = 'Unknown Vehicle';

                        if (vehicleSnapshot.hasData &&
                            vehicleSnapshot.data!.exists) {
                          vehicleName =
                              vehicleSnapshot.data!.get('model') ??
                              'Unnamed Vehicle';
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    serviceType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Vehicle: $vehicleName'),
                                      Text('Interval: $interval km'),
                                      if (predictedDate != null)
                                        Text(
                                          'Due Date: ${DateFormat('d MMMM yyyy').format(predictedDate)}',
                                        ),
                                    ],
                                  ),
                                  trailing: Column(
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      ReminderDetailsPage(
                                                        reminderId:
                                                            reminders[index].id,
                                                        reminderData: reminder,
                                                        uid: testUserId!,
                                                      ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Text(
                                            'Details',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: clampedProgress,
                                  backgroundColor: Colors.grey.shade300,
                                  color: Colors.amber,
                                  minHeight: 6,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(clampedProgress * 100).toStringAsFixed(1)}% to target',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Create Reminder Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateReminderPage(),
                            ),
                          );
                        },
                        child: const Text('Create Reminder'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateCustomReminderPage(),
                            ),
                          );
                        },
                        child: const Text('Create Test Reminder'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Additional widgets can go here
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
