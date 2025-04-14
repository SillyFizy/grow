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

  // Search related variables
  bool _isSearchActive = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  String? _searchErrorMessage;

  // Reference to our cache
  final PlantDataCache _cache = PlantDataCache();

  @override
  void initState() {
    super.initState();
    _loadPlantsFromCacheOrApi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  // Search plants using the API
  Future<void> _searchPlants(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchErrorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchErrorMessage = null;
    });

    try {
      final response = await ApiService.searchPlants(query);

      setState(() {
        _isSearching = false;

        if (response.success) {
          if (response.data != null && response.data['results'] != null) {
            _searchResults = response.data['results'];
          } else if (response.data is List) {
            _searchResults = response.data;
          } else {
            _searchResults = [];
          }
        } else {
          _searchErrorMessage = response.errorMessage ?? 'Search failed';
          _searchResults = [];
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchErrorMessage = 'Search error: ${e.toString()}';
        _searchResults = [];
      });
    }
  }

  // Navigate to plant detail from search results
  void _navigateToPlantDetailFromSearch(dynamic plant) {
    // If we have a plant ID, create a temporary list with just this plant
    // and navigate to the detail screen
    if (plant != null && plant['id'] != null) {
      final int plantId = plant['id'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlantDetailScreen(
            initialPlantId: plantId,
            plantsList: [plant],
            initialIndex: 0,
            loadMorePlants: () {}, // No need to load more from search results
            nextPageUrl: null,
          ),
        ),
      );
    }
  }

  // Toggle search mode
  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        // Clear search when exiting search mode
        _searchController.clear();
        _searchResults = [];
        _searchErrorMessage = null;
      }
    });
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
                      : Column(
                          children: [
                            // Top bar with logo and search icon
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  // Search icon on the left
                                  IconButton(
                                    icon: Icon(
                                      _isSearchActive
                                          ? Icons.close
                                          : Icons.search,
                                      color: Theme.of(context).primaryColor,
                                      size: 28,
                                    ),
                                    onPressed: _toggleSearch,
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Image.asset(
                                        'assets/images/login-logo.png',
                                        height: 80,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          print(
                                              'Error loading logo in CategoryScreen: $error');
                                          return const SizedBox(height: 80);
                                        },
                                      ),
                                    ),
                                  ),
                                  // Empty space to balance the search icon
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),

                            // Search input field (visible when search is active)
                            if (_isSearchActive)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'بحث عن النباتات...',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {
                                                    _searchResults = [];
                                                  });
                                                },
                                              )
                                            : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                  ),
                                  textDirection: TextDirection.rtl,
                                  onChanged: (value) {
                                    // Only search when there are at least 2 characters
                                    if (value.length >= 2) {
                                      _searchPlants(value);
                                    } else if (value.isEmpty) {
                                      setState(() {
                                        _searchResults = [];
                                      });
                                    }
                                  },
                                ),
                              ),

                            // Search results or main content
                            Expanded(
                              child: _isSearchActive
                                  ? _buildSearchResults()
                                  : SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Header text
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 24.0),
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
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: _isLoadingMore
                                                  ? const Center(
                                                      child:
                                                          CircularProgressIndicator())
                                                  : ElevatedButton(
                                                      onPressed:
                                                          _loadMorePlants,
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                                0xFF96C994),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                          'تحميل المزيد',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                            ),

                                          const SizedBox(height: 24),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
            ),
            // Bottom navigation bar
            const BottomNavBar(selectedIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchErrorMessage != null) {
      return Center(
        child: Text(
          'Error: $_searchErrorMessage',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج لـ "${_searchController.text}"',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'قم بالبحث عن النباتات',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Display search results
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final plant = _searchResults[index];
        final String nameArabic = plant['name_arabic'] ?? 'نبات غير معروف';
        final String nameScientific = plant['name_scientific'] ?? '';
        final String? imageUrl = plant['image_url'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () => _navigateToPlantDetailFromSearch(plant),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Plant image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.green.withOpacity(0.1),
                                child:
                                    const Icon(Icons.eco, color: Colors.green),
                              );
                            },
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.green.withOpacity(0.1),
                            child: const Icon(Icons.eco, color: Colors.green),
                          ),
                  ),

                  const SizedBox(width: 16),

                  // Plant details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          nameArabic,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        if (nameScientific.isNotEmpty)
                          Text(
                            nameScientific,
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.right,
                          ),

                        // Show classification if available
                        if (plant['classification'] != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF96C994).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              plant['classification'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF96C994),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  const Icon(
                    Icons.arrow_back_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
