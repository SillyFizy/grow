import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class LocationService {
  static final Location _location = Location();

  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await _location.serviceEnabled();
  }

  // Request location permission
  static Future<PermissionStatus> requestPermission() async {
    PermissionStatus permission = await _location.hasPermission();

    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }

    return permission;
  }

  // Get current position
  static Future<LocationData?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }

      // Check location permission
      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) {
          return null;
        }
      }

      // Get current location
      return await _location.getLocation();
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Convert LocationData to LatLng
  static LatLng locationDataToLatLng(LocationData location) {
    return LatLng(location.latitude!, location.longitude!);
  }

  // Submit a new plant location
  static Future<ApiResponse> submitPlantLocation({
    required int plantId,
    required double latitude,
    required double longitude,
    required int quantity,
    String? notes,
  }) async {
    final body = {
      'plant': plantId,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'quantity': quantity,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    return await ApiService.post('/plant-locations/', body);
  }

  // Get all plant locations
  static Future<ApiResponse> getAllPlantLocations() async {
    return await ApiService.get('/plant-locations/');
  }

  // Get locations for a specific plant
  static Future<ApiResponse> getPlantLocationsByPlant(int plantId) async {
    return await ApiService.get('/plants/$plantId/locations/');
  }

  // Get user's location statistics
  static Future<ApiResponse> getUserLocationStats() async {
    return await ApiService.get('/users/me/location-stats/');
  }
}
