import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import '../widgets/BottomNavBar.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../utils/routes.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // Default position centered on Iraq (Baghdad)
  static const LatLng _iraqPosition = LatLng(33.3152, 44.3661);

  // Maximum distance (in km) allowed between user and new plant location
  static const double _maxDistanceKm = 2.0;

  LatLng? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  List<Marker> _markers = [];
  final Location _location = Location();
  bool _isFetchingLocations = false;

  @override
  void initState() {
    super.initState();
    _initLocationService();
    _fetchPlantLocations();
  }

  Future<void> _initLocationService() async {
    try {
      bool _serviceEnabled;
      PermissionStatus _permissionGranted;

      _serviceEnabled = await _location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await _location.requestService();
        if (!_serviceEnabled) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Location services are disabled. Please enable them.';
          });
          return;
        }
      }

      _permissionGranted = await _location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await _location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Location permission denied. Some features may be limited.';
          });
          return;
        }
      }

      // Get current location
      final locationData = await _location.getLocation();

      if (mounted) {
        setState(() {
          _currentPosition =
              LatLng(locationData.latitude!, locationData.longitude!);
          _isLoading = false;

          // Add current location marker
          _markers.add(
            Marker(
              width: 40.0,
              height: 40.0,
              point: _currentPosition!,
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 30,
              ),
            ),
          );
        });

        // Move map to current location
        _moveToCurrentLocation();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error getting location: $e';
        });
      }
    }
  }

  void _moveToCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 14);
    }
  }

  Future<void> _fetchPlantLocations() async {
    if (_isFetchingLocations) return;

    setState(() {
      _isFetchingLocations = true;
    });

    try {
      final response = await ApiService.get('/plant-locations/');

      if (response.success && mounted) {
        // Parse plant locations and add markers
        if (response.data != null && response.data['results'] != null) {
          final locations = response.data['results'];
          final List<Marker> plantMarkers = [];

          for (var location in locations) {
            final double lat = double.parse(location['latitude'].toString());
            final double lng = double.parse(location['longitude'].toString());
            final String plantName = location['plant_name'] ?? 'Unknown Plant';
            final int plantId = location['plant'] ?? 0;
            final int quantity = location['quantity'] ?? 1;
            final String? notes = location['notes'];

            plantMarkers.add(
              Marker(
                width: 40.0,
                height: 40.0,
                point: LatLng(lat, lng),
                child: GestureDetector(
                  onTap: () {
                    _showPlantInfoDialog(plantName, plantId, quantity, notes);
                  },
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF96C994),
                    size: 40,
                  ),
                ),
              ),
            );
          }

          setState(() {
            // Keep the user location marker and add plant markers
            _markers = [
              if (_currentPosition != null)
                Marker(
                  width: 40.0,
                  height: 40.0,
                  point: _currentPosition!,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ...plantMarkers
            ];
          });
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error: ${response.errorMessage ?? "Could not load plant locations"}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocations = false;
        });
      }
    }
  }

  void _showPlantInfoDialog(
      String plantName, int plantId, int quantity, String? notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plantName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity: $quantity'),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(notes),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to plant details - implementation will depend on your routing setup
              // You may need to adjust this based on your actual implementation
              Navigator.pushNamed(
                context,
                '/plant_detail', // Adjust this path based on your routes
                arguments: {'plantId': plantId},
              );
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  void _showAddPlantLocationDialog(LatLng position) {
    // Check if we have the user's current position
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot determine your location. Please try again.'),
        ),
      );
      return;
    }

    // Calculate distance between selected point and user's location
    final double distanceKm = _calculateDistance(_currentPosition!, position);

    // If distance is too far, show warning
    if (distanceKm > _maxDistanceKm) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Too Far'),
          content: Text(
              'The selected location is ${distanceKm.toStringAsFixed(2)} km away from your current position. Please select a location within $_maxDistanceKm km.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // If distance is acceptable, show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Plant at this Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${position.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${position.longitude.toStringAsFixed(6)}'),
            Text(
                'Distance from your location: ${distanceKm.toStringAsFixed(2)} km'),
            const SizedBox(height: 8),
            const Text('Would you like to add a plant at this location?')
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to the add plant location form with the selected position
              Routes.navigateToAddPlantLocation(context, position)
                  .then((result) {
                // Refresh plant locations if a new location was added
                if (result == true) {
                  _fetchPlantLocations();
                }
              });
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? _iraqPosition,
              initialZoom: _currentPosition != null ? 14 : 7,
              onTap: (_, point) {
                _showAddPlantLocationDialog(point);
              },
            ),
            children: [
              // Map tiles (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.grow',
              ),
              // Markers layer
              MarkerLayer(markers: _markers),
            ],
          ),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Error message
          if (_errorMessage != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          // Top bar with logo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isFetchingLocations)
                        const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF96C994)),
                            )),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/login-logo.png',
                        height: 50,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(height: 50);
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed:
                            _isFetchingLocations ? null : _fetchPlantLocations,
                        color: const Color(0xFF96C994),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating buttons for map controls
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                // My location button
                FloatingActionButton(
                  heroTag: 'my_location',
                  backgroundColor: Colors.white,
                  onPressed: _moveToCurrentLocation,
                  mini: true,
                  child:
                      const Icon(Icons.my_location, color: Color(0xFF96C994)),
                ),
                const SizedBox(height: 8),
                // Add plant location button
                FloatingActionButton(
                  heroTag: 'add_location',
                  backgroundColor: const Color(0xFF96C994),
                  onPressed: () {
                    if (_currentPosition != null) {
                      _showAddPlantLocationDialog(_currentPosition!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Cannot determine your location. Please try again.'),
                        ),
                      );
                    }
                  },
                  child:
                      const Icon(Icons.add_location_alt, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 2),
    );
  }
}
