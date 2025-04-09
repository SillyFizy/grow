import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import '../widgets/BottomNavBar.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // Default position centered on Iraq (Baghdad)
  static const LatLng _iraqPosition = LatLng(33.3152, 44.3661);

  LatLng? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  List<Marker> _markers = [];
  final Location _location = Location();

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

            plantMarkers.add(
              Marker(
                width: 40.0,
                height: 40.0,
                point: LatLng(lat, lng),
                child: GestureDetector(
                  onTap: () {
                    _showPlantInfoDialog(
                        plantName, plantId, location['quantity']);
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
            _markers.addAll(plantMarkers);
          });
        }
      } else if (mounted) {
        print('Error fetching plant locations: ${response.errorMessage}');
      }
    } catch (e) {
      print('Exception fetching plant locations: $e');
    }
  }

  void _showPlantInfoDialog(String plantName, int plantId, dynamic quantity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plantName),
        content: Text('Quantity: ${quantity ?? 'Unknown'}'),
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
              // Navigate to plant details
              Navigator.pushNamed(
                context,
                '/plant_details',
                arguments: {'plantId': plantId},
              );
            },
            child: const Text('View Details'),
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
                  child: Center(
                    child: Image.asset(
                      'assets/images/login-logo.png',
                      height: 50,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(height: 50);
                      },
                    ),
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

  void _showAddPlantLocationDialog(LatLng position) {
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
              // For now, just show a message - we'll implement the full form later
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Add plant at: ${position.latitude}, ${position.longitude}'),
                  action: SnackBarAction(
                    label: 'OK',
                    onPressed: () {},
                  ),
                ),
              );
            },
            child: const Text('Add Plant'),
          ),
        ],
      ),
    );
  }
}
