import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CarDetailsPage extends StatelessWidget {
  final String vehicleId;
  final String uid;

  const CarDetailsPage({super.key, required this.vehicleId, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('vehicles')
                .doc(vehicleId)
                .snapshots(),
        builder: (context, vehicleSnapshot) {
          if (vehicleSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!vehicleSnapshot.hasData || !vehicleSnapshot.data!.exists) {
            return const Center(child: Text('Vehicle not found'));
          }

          final vehicleData =
              vehicleSnapshot.data!.data() as Map<String, dynamic>;
          final model = vehicleData['model'] ?? '';
          final currentMileage =
              vehicleData['milage'] ?? vehicleData['mileage'] ?? 0;
          final plateNumber =
              vehicleData['licensePlate'] ?? vehicleData['plate'] ?? '';

          return CustomScrollView(
            slivers: [
              // App Bar with car image
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Colors.grey[200],
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),

                title: Text(
                  '$model',

                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),
                        // Car image placeholder - you can replace with actual car image
                        Text(
                          plateNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Current Mileage Card
                      _buildMileageCard(currentMileage),

                      const SizedBox(height: 16),

                      // Maintenance Status Card
                      _buildMaintenanceStatusCard(),

                      const SizedBox(height: 16),

                      // Reminders Section
                      _buildRemindersSection(),

                      const SizedBox(height: 16),

                      // Total Expenses Card
                      _buildTotalExpensesCard(),

                      const SizedBox(height: 20),

                      // New Reminder Button
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMileageCard(int currentMileage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${NumberFormat('#,###').format(currentMileage)} km',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Current Mileage',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceStatusCard() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('reminders')
              .where('vehicleId', isEqualTo: vehicleId)
              .snapshots(),
      builder: (context, snapshot) {
        bool hasIncompleteReminders = false;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          // Check if any reminder has isCompleted = false or isCompleted field doesn't exist
          hasIncompleteReminders = snapshot.data!.docs.any((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isCompleted = data['isCompleted'] ?? false;
            return !isCompleted;
          });
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.refresh,
                color: hasIncompleteReminders ? Colors.orange : Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Maintenance Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      hasIncompleteReminders
                          ? 'You have pending maintenance tasks'
                          : 'All maintenance tasks completed',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRemindersSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reminders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.list, color: Colors.grey[600]),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('reminders')
                    .where('vehicleId', isEqualTo: vehicleId)
                    .limit(3)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No upcoming reminders',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children:
                    snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildReminderItem(data);
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(Map<String, dynamic> reminderData) {
    final serviceType = reminderData['serviceType'] ?? 'Unknown Service';
    final targetMileage = reminderData['targetMileage'] ?? 0;
    final predictedDate =
        (reminderData['predictedDate'] as Timestamp?)?.toDate();
    final isCompleted = reminderData['isCompleted'] ?? false;

    // Calculate months remaining (simplified)
    String timeRemaining = 'Unknown';
    String statusText = 'UPCOMING';
    Color statusColor = Colors.orange;
    Color statusBgColor = Colors.orange[100]!;

    if (isCompleted) {
      statusText = 'COMPLETED';
      statusColor = Colors.green[800]!;
      statusBgColor = Colors.green[100]!;
      timeRemaining = 'Done';
    } else if (predictedDate != null) {
      final difference = predictedDate.difference(DateTime.now());
      final months = (difference.inDays / 30).round();
      if (months < 0) {
        timeRemaining = 'Overdue';
        statusText = 'OVERDUE';
        statusColor = Colors.red[800]!;
        statusBgColor = Colors.red[100]!;
      } else {
        timeRemaining = months > 0 ? '$months months' : 'Due soon';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceType,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'at ${NumberFormat('#,###').format(targetMileage)}km',
                  style: TextStyle(
                    fontSize: 14,
                    color: isCompleted ? Colors.grey[400] : Colors.grey,
                  ),
                ),
                // Progress bar
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value:
                      isCompleted
                          ? 1.0
                          : 0.7, // Full if completed, otherwise calculate actual progress
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : Colors.amber[600]!,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeRemaining,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalExpensesCard() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('maintenance_records')
              .where('vehicleId', isEqualTo: vehicleId)
              .snapshots(),
      builder: (context, snapshot) {
        double totalExpenses = 0.0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final cost = data['cost'];
            if (cost != null) {
              totalExpenses +=
                  (cost is int) ? cost.toDouble() : (cost as double? ?? 0.0);
            }
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Icon(Icons.attach_money, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Total Expenses',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'RM ${totalExpenses.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
