import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import your MyCarPage here
import '/widgets/success_page.dart'; // Import your success page here
import 'package:firebase_auth/firebase_auth.dart';

class VehicleForm extends StatefulWidget {
  const VehicleForm({super.key});

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  final _formKey = GlobalKey<FormState>();

  String? _make, _model, _licensePlate;
  int? _year, _milage;
  List<String> _brands = [];
  List<String> _models = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCarBrands();
  }

  Future<void> _loadCarBrands() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('car_brands').get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'No car brands found in database';
          _isLoading = false;
        });
        return;
      }

      List<String> brandsList = [];
      for (var doc in snapshot.docs) {
        // Get the document ID (like "perodua", "proton", "toyota")
        brandsList.add(doc.id);
      }

      setState(() {
        _brands = brandsList;
        _isLoading = false;
      });

      // Print for debugging
      print('Loaded ${_brands.length} brands: $_brands');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load car brands: $e';
        _isLoading = false;
      });
      print('Error loading car brands: $e');
    }
  }

  Future<void> _loadModelsForBrand(String brand) async {
    setState(() {
      _models = [];
      _model = null;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Loading models for brand: $brand');

      final doc =
          await FirebaseFirestore.instance
              .collection('car_brands')
              .doc(brand)
              .get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = 'No models found for $brand';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data();
      if (data == null) {
        setState(() {
          _errorMessage = 'Invalid data format for $brand';
          _isLoading = false;
        });
        return;
      }

      // Check if models is in the expected format
      if (!data.containsKey('models')) {
        setState(() {
          _errorMessage = 'No models field found for $brand';
          _isLoading = false;
        });
        print('Models field missing for $brand. Data: $data');
        return;
      }

      var modelsData = data['models'];
      List<String> modelsList = [];

      // Handle different possible formats of the models field
      if (modelsData is List) {
        // If models is already a list
        modelsList = List<String>.from(modelsData);
      } else if (modelsData is Map) {
        // If models is a map (which appears to be the case from your screenshot)
        modelsData.forEach((key, value) {
          if (value is String) {
            modelsList.add(value);
          }
        });
      }

      setState(() {
        _models = modelsList;
        _isLoading = false;
      });

      // Print for debugging
      print('Loaded ${_models.length} models for $brand: $_models');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load models: $e';
        _isLoading = false;
      });
      print('Error loading models: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      ;

      final DocumentReference docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vehicles')
          .add({
            'make': _make,
            'model': _model,
            'year': _year,
            'licensePlate': _licensePlate,
            'milage': _milage,
            'createdAt': FieldValue.serverTimestamp(),
          });
      await docRef.update({'id': docRef.id});

      // ignore: use_build_context_synchronously
      /* ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle registered successfully')),
      );*/

      // ignore: use_build_context_synchronously
      //Navigator.pop(context); // Go back after save
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessPage(),
        ), // Create a basic page to show success
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error registering vehicle: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
                ),
                value: _make,
                items:
                    _brands.map((brand) {
                      String displayName =
                          brand[0].toUpperCase() + brand.substring(1);
                      return DropdownMenuItem(
                        value: brand,
                        child: Text(displayName),
                      );
                    }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _make = val);
                    _loadModelsForBrand(val);
                  }
                },
                validator: (val) => val == null ? 'Select a brand' : null,
                isExpanded: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                ),
                value: _model,
                items:
                    _models.map((model) {
                      return DropdownMenuItem(value: model, child: Text(model));
                    }).toList(),
                onChanged: (val) => setState(() => _model = val),
                validator: (val) => val == null ? 'Select a model' : null,
                isExpanded: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSaved: (val) => _year = int.tryParse(val ?? ''),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter year';
                  final year = int.tryParse(val);
                  if (year == null) return 'Enter a valid year';
                  if (year < 1900 || year > DateTime.now().year + 1) {
                    return 'Enter a valid year between 1900 and ${DateTime.now().year + 1}';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Plate Number',
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => _licensePlate = val,
                validator:
                    (val) =>
                        val == null || val.isEmpty
                            ? 'Enter plate number'
                            : null,
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Mileage (km)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSaved: (val) => _milage = int.tryParse(val ?? ''),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter mileage (km)';
                  final mileage = int.tryParse(val);
                  if (mileage == null || mileage < 0)
                    return 'Enter a valid mileage';
                  return null;
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                onPressed: _submit,
                child: const Text('Register Vehicle'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
