import 'dart:async';

/// Singleton class for caching plant data to avoid redundant API calls
class PlantDataCache {
  static final PlantDataCache _instance = PlantDataCache._internal();

  factory PlantDataCache() {
    return _instance;
  }

  PlantDataCache._internal();

  // Plants list cache
  List<dynamic> _plants = [];
  String? _nextPageUrl;
  bool _hasMorePages = true;
  DateTime? _lastFetchTime;

  // Set to track plant IDs for quick duplicate checking
  final Set<int> _plantIds = {};

  // Plant details cache
  final Map<int, dynamic> _plantDetails = {};
  final Map<int, DateTime> _detailsFetchTime = {};

  // Cache expiration time (4 hours)
  static const Duration _cacheExpiration = Duration(hours: 4);

  // Getters
  List<dynamic> get plants => _plants;
  String? get nextPageUrl => _nextPageUrl;
  bool get hasMorePages => _hasMorePages;

  // Check if cache is expired
  bool get isCacheExpired {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > _cacheExpiration;
  }

  // Update plants cache with new data
  void updatePlantsCache(List<dynamic> plants, String? nextPageUrl) {
    // If we're updating with a new first page, replace the cache
    _plants = [];
    _plantIds.clear();

    // Add all plants with ID tracking
    for (final plant in plants) {
      if (plant['id'] != null) {
        final int id = plant['id'];
        if (!_plantIds.contains(id)) {
          _plants.add(plant);
          _plantIds.add(id);
        }
      }
    }

    _nextPageUrl = nextPageUrl;
    _hasMorePages = nextPageUrl != null;
    _lastFetchTime = DateTime.now();
  }

  // Append plants to cache (for pagination)
  List<dynamic> appendPlantsCache(
      List<dynamic> newPlants, String? nextPageUrl) {
    // Track newly added plants to return them
    List<dynamic> actuallyAddedPlants = [];

    // Add new plants, avoiding duplicates
    for (final plant in newPlants) {
      if (plant['id'] != null) {
        final int id = plant['id'];
        if (!_plantIds.contains(id)) {
          _plants.add(plant);
          _plantIds.add(id);
          actuallyAddedPlants.add(plant);
        }
      }
    }

    _nextPageUrl = nextPageUrl;
    _hasMorePages = nextPageUrl != null;
    _lastFetchTime = DateTime.now();

    return actuallyAddedPlants;
  }

  // Get plant details from cache
  dynamic getPlantDetails(int plantId) {
    // Check if details exist and aren't expired
    if (_plantDetails.containsKey(plantId)) {
      final fetchTime = _detailsFetchTime[plantId];
      if (fetchTime != null &&
          DateTime.now().difference(fetchTime) <= _cacheExpiration) {
        return _plantDetails[plantId];
      }
    }
    return null;
  }

  // Save plant details to cache
  void savePlantDetails(int plantId, dynamic details) {
    _plantDetails[plantId] = details;
    _detailsFetchTime[plantId] = DateTime.now();
  }

  // Clear cache (useful for logout or refresh)
  void clearCache() {
    _plants = [];
    _nextPageUrl = null;
    _hasMorePages = true;
    _lastFetchTime = null;
    _plantIds.clear();
    _plantDetails.clear();
    _detailsFetchTime.clear();
  }

  // Check if we need to fetch more plants
  bool shouldFetchMorePlants(int currentIndex) {
    // If we're 3 items from the end and there are more pages, fetch more
    return _hasMorePages &&
        currentIndex >= _plants.length - 3 &&
        _plants.isNotEmpty;
  }
}
