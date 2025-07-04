import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceLogPage extends StatefulWidget {
  const ServiceLogPage({super.key});

  @override
  State<ServiceLogPage> createState() => _ServiceLogPageState();
}

class _ServiceLogPageState extends State<ServiceLogPage> {
  final String? testUserId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Maintenance, Car
  bool _isSearchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle null user
    if (testUserId == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Please log in to view your service records.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Search bar toggle and filter buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isSearchVisible = !_isSearchVisible;
                          if (!_isSearchVisible) {
                            _searchController.clear();
                            _searchQuery = '';
                          }
                        });
                      },
                      icon: Icon(
                        _isSearchVisible ? Icons.search_off : Icons.search,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Maintenance'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Car'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Search bar (appears when toggled)
                if (_isSearchVisible) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          _selectedFilter == 'All'
                              ? 'Search maintenance type or car name...'
                              : _selectedFilter == 'Maintenance'
                              ? 'Search maintenance type...'
                              : 'Search car name...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                icon: const Icon(Icons.clear),
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.amber),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),

          // Service Records List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(testUserId!)
                      .collection('maintenance_records')
                      .orderBy('date', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading records: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No maintenance records found.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Service records will appear here after maintenance.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final records = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final data = records[index].data() as Map<String, dynamic>;
                    return _buildServiceRecord(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.amber,
      checkmarkColor: Colors.white,
      side: BorderSide(color: isSelected ? Colors.amber : Colors.grey[300]!),
    );
  }

  Widget _buildServiceRecord(Map<String, dynamic> data) {
    final vehicleId = data['vehicleId'];
    final dueDate = (data['date'] as Timestamp).toDate();
    final mileage = data['mileage']?.toString() ?? '';
    final cost = data['cost']?.toString() ?? '';
    final notes = data['notes'] ?? '';
    final maintenanceType = data['serviceType'] ?? 'Untitled';

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .doc(testUserId!)
              .collection('vehicles')
              .doc(vehicleId)
              .get(),
      builder: (context, vehicleSnap) {
        final carName =
            vehicleSnap.hasData && vehicleSnap.data!.exists
                ? vehicleSnap.data!['model'] ?? 'Unknown Car'
                : 'Unknown Car';

        // Apply search and filter logic
        if (_searchQuery.isNotEmpty || _selectedFilter != 'All') {
          bool matchesSearch = true;
          bool matchesFilter = true;

          // Search filter
          if (_searchQuery.isNotEmpty) {
            final maintenanceMatch = maintenanceType.toLowerCase().contains(
              _searchQuery,
            );
            final carMatch = carName.toLowerCase().contains(_searchQuery);
            final notesMatch = notes.toLowerCase().contains(_searchQuery);

            matchesSearch = maintenanceMatch || carMatch || notesMatch;
          }

          // Category filter
          if (_selectedFilter == 'Maintenance') {
            matchesFilter = maintenanceType.toLowerCase().contains(
              _searchQuery.isEmpty ? '' : _searchQuery,
            );
          } else if (_selectedFilter == 'Car') {
            matchesFilter = carName.toLowerCase().contains(
              _searchQuery.isEmpty ? '' : _searchQuery,
            );
          }

          if (!matchesSearch || !matchesFilter) {
            return const SizedBox.shrink(); // Hide non-matching items
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with date and maintenance type
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('d MMMM yyyy').format(dueDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              maintenanceType,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (cost.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Text(
                            'RM $cost',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Details section
                  _buildDetailRow(Icons.directions_car, "Car", carName),
                  if (mileage.isNotEmpty)
                    _buildDetailRow(Icons.speed, "Mileage", "$mileage km"),
                  if (notes.isNotEmpty)
                    _buildDetailRow(Icons.note, "Notes", notes),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
