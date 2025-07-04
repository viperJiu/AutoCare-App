import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateReminderPage extends StatefulWidget {
  const CreateReminderPage({super.key});

  @override
  State<CreateReminderPage> createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends State<CreateReminderPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedVehicleId;
  Map<String, dynamic>? _selectedVehicleData;
  String? _selectedServiceType;
  int? _targetMileage;
  int? _dailyMileage;
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
  Widget build(BuildContext context) {
    // Handle null user
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Reminder'),
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

                    // Current Mileage Display
                    if (_selectedVehicleData != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.speed, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Current Mileage: ${_selectedVehicleData!['milage'] ?? 0} km',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Target Mileage Input
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Mileage Interval (km)',
                        hintText: 'e.g., 10000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timeline),
                        helperText: 'How many km between services',
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isLoading,
                      onSaved:
                          (val) => _targetMileage = int.tryParse(val ?? ''),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter mileage interval';
                        }
                        final parsed = int.tryParse(val.trim());
                        if (parsed == null) {
                          return 'Please enter a valid number';
                        }
                        if (parsed <= 0) {
                          return 'Interval must be greater than 0';
                        }
                        if (parsed > 100000) {
                          return 'Interval seems too high';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Daily Mileage Input
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Average Daily Mileage (km)',
                        hintText: 'e.g., 50',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.today),
                        helperText: 'Used to predict service date',
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isLoading,
                      onSaved: (val) => _dailyMileage = int.tryParse(val ?? ''),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter daily mileage';
                        }
                        final parsed = int.tryParse(val.trim());
                        if (parsed == null) {
                          return 'Please enter a valid number';
                        }
                        if (parsed <= 0) {
                          return 'Daily mileage must be greater than 0';
                        }
                        if (parsed > 1000) {
                          return 'Daily mileage seems too high';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

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
                                'Create Reminder',
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

  Future<void> _submitReminder() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_selectedVehicleData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vehicle first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentMileage = _selectedVehicleData!['milage'] ?? 0;
      final targetMileage = currentMileage + _targetMileage!;
      final daysToReach = _targetMileage! ~/ _dailyMileage!;
      final predictedDate = DateTime.now().add(Duration(days: daysToReach));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid!)
          .collection('reminders')
          .add({
            'vehicleId': _selectedVehicleId,
            'serviceType': _selectedServiceType,
            'intervalMileage': _targetMileage,
            'targetMileage': targetMileage,
            'predictedDate': predictedDate,
            'currentMileage': currentMileage,
            'dailyMileage': _dailyMileage,
            'isCompleted': false,
            'reminderType': 'mileage_based',
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminder created! Predicted service date: ${predictedDate.day}/${predictedDate.month}/${predictedDate.year}',
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
