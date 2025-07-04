import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReminderDetailsPage extends StatefulWidget {
  final String reminderId;
  final Map<String, dynamic> reminderData;
  final String uid;

  const ReminderDetailsPage({
    super.key,
    required this.reminderId,
    required this.reminderData,
    required this.uid,
  });

  @override
  State<ReminderDetailsPage> createState() => _ReminderDetailsPageState();
}

class _ReminderDetailsPageState extends State<ReminderDetailsPage> {
  bool showCompletionForm = false;
  final _formKey = GlobalKey<FormState>();

  double? cost;
  String? notes;
  bool continueReminder = false;
  int? currentMileage;

  @override
  Widget build(BuildContext context) {
    final data = widget.reminderData;
    final predictedDate = (data['predictedDate'] as Timestamp?)?.toDate();
    final interval = data['intervalMileage'] ?? 0;
    final target = data['targetMileage'] ?? 0;
    final serviceType = data['serviceType'] ?? '';
    final vehicleId = data['vehicleId'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Reminder',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$serviceType',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Interval: $interval km'),
                    Text('Target Mileage: $target km'),
                    if (predictedDate != null)
                      Text(
                        'Predicted Date: ${DateFormat('d MMMM yyyy').format(predictedDate)}',
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (!showCompletionForm)
              ElevatedButton(
                onPressed: () => setState(() => showCompletionForm = true),
                child: const Text('Mark as Done'),
              ),

            if (showCompletionForm)
              _buildCompletionForm(vehicleId, serviceType, target, interval),
            const SizedBox(height: 20),
            Divider(),
            TextButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Delete Reminder',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionForm(
    String vehicleId,
    String serviceType,
    int oldTarget,
    int interval,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Current Milage (km)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator:
                (val) =>
                    (val == null || int.tryParse(val) == null)
                        ? 'Enter valid mileage'
                        : null,
            onSaved: (val) => currentMileage = int.tryParse(val!),
          ),
          const SizedBox(height: 10),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Cost (RM)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator:
                (val) =>
                    (val == null || double.tryParse(val) == null)
                        ? 'Enter valid amount'
                        : null,
            onSaved: (val) => cost = double.tryParse(val!),
          ),
          const SizedBox(height: 10),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onSaved: (val) => notes = val,
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            title: const Text('Continue same reminder'),
            value: continueReminder,
            onChanged: (val) => setState(() => continueReminder = val ?? false),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _submitCompletion,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCompletion() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final reminder = widget.reminderData;
    final uid = widget.uid;
    final reminderId = widget.reminderId;

    final vehicleId = reminder['vehicleId'];
    final newCurrentMileage = reminder['targetMileage'];

    try {
      // 1. Save maintenance record with serviceType directly stored
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('maintenance_records')
          .add({
            'vehicleId': vehicleId,
            'reminderId': reminderId,
            'serviceType':
                reminder['serviceType'], // Store serviceType directly
            'mileage': currentMileage,
            'cost': cost,
            'notes': notes,
            'date': FieldValue.serverTimestamp(),
          });

      // 2. Update the vehicle's current mileage
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vehicles')
          .doc(vehicleId)
          .update({'milage': currentMileage});

      // 3. Mark reminder as completed by deleting it
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reminders')
          .doc(reminderId)
          .delete();

      // 4. Create next reminder if continuing
      if (continueReminder) {
        final newTargetMileage =
            newCurrentMileage + reminder['intervalMileage'];
        final dailyMileage = reminder['dailyMileage'] ?? 50;
        final daysToReach = reminder['intervalMileage'] ~/ dailyMileage;

        final newPredictedDate = DateTime.now().add(
          Duration(days: daysToReach),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('reminders')
            .add({
              'vehicleId': vehicleId,
              'serviceType': reminder['serviceType'],
              'intervalMileage': reminder['intervalMileage'],
              'targetMileage': newTargetMileage,
              'dailyMileage': dailyMileage,
              'predictedDate': newPredictedDate,
              'isCompleted': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance record saved.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Reminder'),
            content: const Text(
              'Are you sure you want to delete this reminder?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  await _deleteReminder();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteReminder() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('reminders')
          .doc(widget.reminderId)
          .delete();

      if (!mounted) return;
      Navigator.pop(context); // Close the details page
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder deleted.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete reminder: $e')));
    }
  }
}
