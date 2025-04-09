import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';
import '../services/api_service.dart';
import '../utils/plant_data_cache.dart';
import 'plant_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _plants = [];
  String? _nextPageUrl;
  bool _isLoadingMore = false;

  // Reference to our cache
  final PlantDataCache _cache = PlantDataCache();

  @override
  void initState() {
    super.initState();
    _loadPlantsFromCacheOrApi();
  }

  Future<void> _loadPlantsFromCacheOrApi() async {
    // Check if we have valid cached data
    if (_cache.plants.isNotEmpty && !_cache.isCacheExpired) {
      print('Loading plants from cache (${_cache.plants.length} plants)');
      setState(() {
        _plants = _cache.plants;
        _nextPageUrl = _cache.nextPageUrl;
        _isLoading = false;
      });
    } else {
      // No valid cache, load from API
      await _fetchPlants();
    }
  }

  Future<void> _fetchPlants({String? url}) async {
    if (url == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final response = await ApiService.get(url ?? '/plants/');

      if (response.success) {
        final newPlants = response.data['results'] ?? [];
        final nextUrl = response.data['next'];

        setState(() {
          if (url == null) {
            // First page - replace existing data
            _plants = newPlants;
            _cache.updatePlantsCache(newPlants, nextUrl);
          } else {
            // Next pages - append to existing data
            _plants.addAll(newPlants);
            _cache.appendPlantsCache(newPlants, nextUrl);
          }
          _nextPageUrl = nextUrl;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _errorMessage = response.errorMessage ?? 'Failed to load plants';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _loadMorePlants() {
    if (_nextPageUrl != null && !_isLoadingMore) {
      _fetchPlants(url: _nextPageUrl);
    }
  }

  void _navigateToPlantDetail(int plantId, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantDetailScreen(
          initialPlantId: plantId,
          plantsList: _plants,
          initialIndex: index,
          loadMorePlants: _loadMorePlants,
          nextPageUrl: _nextPageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building CategoryScreen');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
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
                                onPressed: () => _fetchPlants(),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // App logo at the top
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/login-logo.png',
                                    height: 80,
                                    errorBuilder: (context, error, stackTrace) {
                                      print(
                                          'Error loading logo in CategoryScreen: $error');
                                      return const SizedBox(height: 80);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Header text
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.0),
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Text(
                                      'اجمل ',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'النباتات ',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF96C994),
                                      ),
                                    ),
                                    Text(
                                      'داخلية للمنزل',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Plants grid
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: _buildPlantsGrid(),
                              ),

                              // Load more button
                              if (_nextPageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: _isLoadingMore
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : ElevatedButton(
                                          onPressed: _loadMorePlants,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF96C994),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text('تحميل المزيد',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
            ),
            // Bottom navigation bar
            const BottomNavBar(selectedIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantsGrid() {
    print('Building plants grid with ${_plants.length} plants');

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: _plants.length,
      itemBuilder: (context, index) {
        final plant = _plants[index];
        return _buildPlantItem(plant, index);
      },
    );
  }

  Widget _buildPlantItem(Map<String, dynamic> plant, int index) {
    final int plantId = plant['id'];
    final String nameArabic = plant['name_arabic'] ?? '';
    final String? imageUrl = plant['image_url'];

    return GestureDetector(
      onTap: () => _navigateToPlantDetail(plantId, index),
      child: Column(
        children: [
          // Fixed size container for the image with Hero animation
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Hero(
                tag: 'plant_image_$plantId',
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print(
                              'Error loading plant image $nameArabic: $error');
                          return Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                            ),
                            child: const Center(
                              child: Icon(Icons.eco, color: Colors.green),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                        ),
                        child: const Center(
                          child: Icon(Icons.eco, color: Colors.green),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nameArabic,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
