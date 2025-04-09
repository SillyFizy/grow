import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

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
  String _searchQuery = '';

  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  List<dynamic> _plants = [];
  List<dynamic> _filteredPlants = [];

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
            _filteredPlants = [..._plants];
          } else if (response.data is List) {
            _plants = response.data;
            _filteredPlants = [..._plants];
          } else {
            _plants = [];
            _filteredPlants = [];
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

  void _filterPlants(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;

      if (query.isEmpty) {
        _filteredPlants = [..._plants];
      } else {
        _filteredPlants = _plants.where((plant) {
          final nameArabic =
              plant['name_arabic']?.toString().toLowerCase() ?? '';
          final nameEnglish =
              plant['name_english']?.toString().toLowerCase() ?? '';
          final nameScientific =
              plant['name_scientific']?.toString().toLowerCase() ?? '';

          return nameArabic.contains(query.toLowerCase()) ||
              nameEnglish.contains(query.toLowerCase()) ||
              nameScientific.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _searchPlants(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredPlants = [..._plants];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await ApiService.searchPlants(query);

      setState(() {
        if (response.success) {
          if (response.data != null) {
            _filteredPlants = response.data;
          } else {
            _filteredPlants = [];
          }
        } else {
          // If search fails, fall back to client-side filtering
          _filterPlants(query);
        }
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        // If search fails, fall back to client-side filtering
        _filterPlants(query);
        _isSearching = false;
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
      // Round to 6 decimal places to match backend validation requirements
      final double roundedLatitude =
          double.parse(widget.position.latitude.toStringAsFixed(6));
      final double roundedLongitude =
          double.parse(widget.position.longitude.toStringAsFixed(6));

      final Map<String, dynamic> requestData = {
        'plant': _selectedPlantId,
        'latitude': roundedLatitude, // Now limited to 6 decimal places
        'longitude': roundedLongitude, // Now limited to 6 decimal places
        'quantity': _quantity,
      };

      if (_notes.isNotEmpty) {
        requestData['notes'] = _notes;
      }

      print('DEBUG - Submitting plant location with data:');
      print(
          'Plant ID: ${requestData['plant']} (type: ${requestData['plant'].runtimeType})');
      print(
          'Latitude: ${requestData['latitude']} (type: ${requestData['latitude'].runtimeType})');
      print(
          'Longitude: ${requestData['longitude']} (type: ${requestData['longitude'].runtimeType})');
      print(
          'Quantity: ${requestData['quantity']} (type: ${requestData['quantity'].runtimeType})');
      if (requestData.containsKey('notes')) {
        print(
            'Notes: ${requestData['notes']} (type: ${requestData['notes'].runtimeType})');
      }

      final response = await ApiService.post(
        '/plant-locations/',
        requestData,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plant location added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage =
              response.errorMessage ?? 'Failed to add plant location';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
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
      body: _isLoading && _plants.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _plants.isEmpty
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

                        // Search bar for plants
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Search Plants',
                            hintText: 'Type to search for plants',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _filteredPlants = [..._plants];
                                      });
                                    },
                                  )
                                : null,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _filterPlants(value);
                            // Debounce the API search to avoid too many requests
                            Future.delayed(const Duration(milliseconds: 500),
                                () {
                              if (value == _searchQuery && value.length > 2) {
                                _searchPlants(value);
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Plants list
                        Container(
                          constraints: const BoxConstraints(
                            maxHeight:
                                200, // Limit height to prevent list from taking too much space
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _isSearching
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _filteredPlants.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('No plants found'),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _filteredPlants.length,
                                      itemBuilder: (context, index) {
                                        final plant = _filteredPlants[index];
                                        final bool isSelected =
                                            plant['id'] == _selectedPlantId;

                                        return ListTile(
                                          title: Text(plant['name_arabic'] ??
                                              'Unknown Plant'),
                                          subtitle: Text(
                                              plant['name_scientific'] ?? ''),
                                          leading: plant['image_url'] != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: Image.network(
                                                    plant['image_url'],
                                                    width: 40,
                                                    height: 40,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Container(
                                                        width: 40,
                                                        height: 40,
                                                        color: Colors.grey[200],
                                                        child: const Icon(
                                                            Icons.eco,
                                                            color:
                                                                Colors.green),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Container(
                                                  width: 40,
                                                  height: 40,
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.eco,
                                                      color: Colors.green),
                                                ),
                                          tileColor: isSelected
                                              ? Colors.green.withOpacity(0.1)
                                              : null,
                                          onTap: () {
                                            setState(() {
                                              _selectedPlantId = plant['id'];
                                              _selectedPlantName =
                                                  plant['name_arabic'];
                                            });
                                          },
                                        );
                                      },
                                    ),
                        ),

                        // Selected plant display
                        if (_selectedPlantId != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Selected: $_selectedPlantName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF96C994),
                              ),
                            ),
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
                          onPressed: _isLoading ? null : _submitLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF96C994),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Submit Location'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
