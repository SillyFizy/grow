import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/plant_data_cache.dart';
import 'dart:math' as Math;

class PlantDetailScreen extends StatefulWidget {
  final int initialPlantId;
  final List<dynamic> plantsList;
  final int initialIndex;
  final Function loadMorePlants;
  final String? nextPageUrl;

  const PlantDetailScreen({
    Key? key,
    required this.initialPlantId,
    required this.plantsList,
    required this.initialIndex,
    required this.loadMorePlants,
    this.nextPageUrl,
  }) : super(key: key);

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late List<dynamic> _plants;
  String? _nextPageUrl;
  bool _isLoadingMore = false;

  // Reference to our cache
  final PlantDataCache _cache = PlantDataCache();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _plants = List.from(widget.plantsList); // Make a copy to safely modify
    _nextPageUrl = widget.nextPageUrl;

    // Set viewportFraction to show partial views of adjacent pages
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.7,
    );

    // Pre-fetch current plant details
    _fetchPlantDetails(widget.initialPlantId);

    // Pre-fetch adjacent plants if they exist
    if (_currentIndex > 0) {
      _fetchPlantDetails(_plants[_currentIndex - 1]['id']);
    }
    if (_currentIndex < _plants.length - 1) {
      _fetchPlantDetails(_plants[_currentIndex + 1]['id']);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlantDetails(int plantId) async {
    // Check cache first
    final cachedDetails = _cache.getPlantDetails(plantId);
    if (cachedDetails != null) {
      print('Found plant $plantId details in cache');
      return;
    }

    // Not in cache, need to fetch
    setState(() {
      // Set loading state for this plant
      _cache.savePlantDetails(plantId, null); // Mark as loading
    });

    try {
      final response = await ApiService.get('/plants/$plantId/');
      if (response.success && mounted) {
        // Save to cache
        _cache.savePlantDetails(plantId, response.data);
        setState(() {});
      } else if (mounted) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to load plant details: ${response.errorMessage}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadMorePlants() async {
    if (_nextPageUrl == null || _isLoadingMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await ApiService.get(_nextPageUrl!);
      if (response.success && mounted) {
        final newPlants = response.data['results'] ?? [];

        // Use cache to filter out duplicates and get only newly added plants
        final actuallyAddedPlants =
            _cache.appendPlantsCache(newPlants, response.data['next']);

        setState(() {
          // Add only the plants that weren't already in our list
          if (actuallyAddedPlants.isNotEmpty) {
            _plants.addAll(actuallyAddedPlants);
          }
          _nextPageUrl = response.data['next'];
          _isLoadingMore = false;
        });

        // Pre-fetch details for the first few new plants
        for (int i = 0; i < Math.min(3, actuallyAddedPlants.length); i++) {
          _fetchPlantDetails(actuallyAddedPlants[i]['id']);
        }
      } else if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to load more plants: ${response.errorMessage}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more plants: ${e.toString()}')),
        );
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Get the current plant ID
    final int currentPlantId = _plants[index]['id'];

    // Fetch details for the current plant if needed
    _fetchPlantDetails(currentPlantId);

    // Pre-fetch next plant's details if it exists
    if (index < _plants.length - 1) {
      final int nextPlantId = _plants[index + 1]['id'];
      _fetchPlantDetails(nextPlantId);
    }

    // Pre-fetch previous plant's details if it exists
    if (index > 0) {
      final int prevPlantId = _plants[index - 1]['id'];
      _fetchPlantDetails(prevPlantId);
    }

    // Check if we're approaching the end of the list and need to load more
    if (_nextPageUrl != null &&
        index >= _plants.length - 3 &&
        !_isLoadingMore) {
      print('Approaching end of plant list, loading more...');
      _loadMorePlants();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset(
          'assets/images/login-logo.png',
          height: 80,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(height: 40);
          },
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Loading indicator for pagination
          if (_isLoadingMore)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF96C994)),
              minHeight: 2,
            ),

          // Carousel that takes about 40% of the screen height
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _plants.length,
              itemBuilder: (context, index) {
                final plant = _plants[index];
                final int plantId = plant['id'];
                final String imageUrl = plant['image_url'] ?? '';

                // Use PageView with Hero animation for carousel effect
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: _currentIndex == index ? 0 : 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Hero(
                      tag: 'plant_image_$plantId',
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.green.withOpacity(0.1),
                            child: const Center(
                              child: Icon(Icons.eco,
                                  color: Colors.green, size: 50),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Plant details section
          Expanded(
            child: _buildPlantDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantDetails() {
    // Get current plant ID
    if (_currentIndex >= _plants.length) {
      return const Center(child: Text('No plant selected'));
    }

    final int plantId = _plants[_currentIndex]['id'];
    final details = _cache.getPlantDetails(plantId);

    if (details == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Plant name section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF96C994),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  details['classification'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    details['name_arabic'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if ((details['name_english'] ?? '').isNotEmpty)
                    Text(
                      details['name_english'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  Text(
                    details['name_scientific'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF96C994),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Description
          if ((details['description'] ?? '').isNotEmpty) ...[
            const Text(
              'الوصف:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            Text(
              details['description'] ?? '',
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 20),
          ],

          // Divider for visual separation
          const Divider(thickness: 1),
          const SizedBox(height: 10),

          // Family info
          const Text(
            'العائلة:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          Text(
            details['family']?['name_arabic'] ?? '',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.right,
          ),

          const SizedBox(height: 20),

          // Seed info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'نوع الفلقة:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details['cotyledon_type'] == 'MONO'
                          ? 'أحادية الفلقة'
                          : details['cotyledon_type'] == 'DI'
                              ? 'ثنائية الفلقة'
                              : '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'شكل البذرة:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details['seed_shape_arabic'] ?? '',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Flower info
          const Text(
            'معلومات الزهرة:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          Text(
            details['flower_type'] == 'BOTH'
                ? 'ذكرية وأنثوية'
                : details['flower_type'] == 'HERMAPHRODITE'
                    ? 'خنثى'
                    : '',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.right,
          ),

          // Male flower info if it exists
          if (details['male_flower'] != null) ...[
            const SizedBox(height: 16),
            const Text(
              'الزهرة الذكرية:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            Text(
              'الأسدية: ${details['male_flower']['stamens'] ?? ''}',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ],

          // Female flower info if it exists
          if (details['female_flower'] != null) ...[
            const SizedBox(height: 16),
            const Text(
              'الزهرة الأنثوية:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            Text(
              'الكرابل: ${details['female_flower']['carpels'] ?? ''}',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ],

          // Hermaphrodite flower info if it exists
          if (details['hermaphrodite_flower'] != null) ...[
            const SizedBox(height: 16),
            const Text(
              'الزهرة الخنثى:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            Text(
              'الأسدية: ${details['hermaphrodite_flower']['stamens'] ?? ''}',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            Text(
              'الكرابل: ${details['hermaphrodite_flower']['carpels'] ?? ''}',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }
}
