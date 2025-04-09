import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class AddPlantLocationScreen extends StatefulWidget {
  final LatLng position;

  const AddPlantLocationScreen({
    super.key,
    required this.position,
  });

  @override
  State<AddPlantLocationScreen> createState() => _AddPlantLocationScreenState();
}

class _AddPlantLocationScreenState extends State<AddPlantLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedPlantId;
  String? _selectedPlantName;
  int _quantity = 1;
  String _notes = '';

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _plants = [];

  @override
  void initState() {
    super.initState();
    _fetchPlants();
  }

  Future<void> _fetchPlants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/plants/');

      setState(() {
        _isLoading = false;
        if (response.success) {
          if (response.data != null && response.data['results'] != null) {
            _plants = response.data['results'];
          } else if (response.data is List) {
            _plants = response.data;
          } else {
            _plants = [];
          }
        } else {
          _errorMessage = response.errorMessage ?? 'Failed to load plants';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  Future<void> _submitLocation() async {
    if (_formKey.currentState?.validate() != true || _selectedPlantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please select a plant and fill all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await LocationService.submitPlantLocation(
        plantId: _selectedPlantId!,
        latitude: widget.position.latitude,
        longitude: widget.position.longitude,
        quantity: _quantity,
        notes: _notes.isNotEmpty ? _notes : null,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        // Show success message and close the screen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plant location added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        setState(() {
          _errorMessage =
              response.errorMessage ?? 'Failed to add plant location';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Plant Location'),
        backgroundColor: const Color(0xFF96C994),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchPlants,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Selected coordinates card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected Location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Color(0xFF96C994)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Latitude: ${widget.position.latitude.toStringAsFixed(6)}\nLongitude: ${widget.position.longitude.toStringAsFixed(6)}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Plant dropdown
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Select Plant',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.eco),
                          ),
                          value: _selectedPlantId,
                          items: _plants.map<DropdownMenuItem<int>>((plant) {
                            return DropdownMenuItem<int>(
                              value: plant['id'],
                              child:
                                  Text(plant['name_arabic'] ?? 'Unknown Plant'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPlantId = value;
                              _selectedPlantName = _plants.firstWhere(
                                  (p) => p['id'] == value,
                                  orElse: () =>
                                      {'name_arabic': null})['name_arabic'];
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a plant';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Quantity field
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          keyboardType: TextInputType.number,
                          initialValue: _quantity.toString(),
                          onChanged: (value) {
                            setState(() {
                              _quantity = int.tryParse(value) ?? 1;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a quantity';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity < 1) {
                              return 'Quantity must be at least 1';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Notes field
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                          onChanged: (value) {
                            setState(() {
                              _notes = value;
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        // Submit button
                        ElevatedButton(
                          onPressed: _submitLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF96C994),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Submit Location'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
