import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';
import '../services/api_service.dart';

class PlantDetailsScreen extends StatefulWidget {
  final String title;
  final String imageAsset;
  final String? description;

  const PlantDetailsScreen({
    super.key,
    required this.title,
    required this.imageAsset,
    this.description,
  });

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _plants = [];
  bool _showAllPlants = false; // New state to track whether to show all plants

  @override
  void initState() {
    super.initState();
    _fetchPlantsByClassification();
  }

  Future<void> _fetchPlantsByClassification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Extract classification value from the title
    // This assumes the title format is consistent with how we map classifications
    String classification = '';
    if (widget.title == 'نباتات برية') {
      classification = 'بري';
    } else if (widget.title == 'نباتات اقتصادية') {
      classification = 'اقتصادي';
    } else if (widget.title == 'نباتات طبية') {
      classification = 'طبي';
    } else if (widget.title == 'نباتات الزينة') {
      classification = 'نباتات الزينة';
    }

    try {
      final response =
          await ApiService.fetchPlantsByClassification(classification);

      setState(() {
        _isLoading = false;
        if (response.success) {
          // Check if response includes a results array
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top area with logo and bookmark
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Logo
                          Image.asset(
                            'assets/images/login-logo.png',
                            height: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(width: 40, height: 40);
                            },
                          ),

                          // Bookmark icon - just the outline, no background
                          IconButton(
                            icon: const Icon(
                              Icons.bookmark_border_outlined,
                              color: Color(0xFF96C994),
                              size: 30,
                            ),
                            onPressed: () {
                              // TODO: Implement bookmark functionality
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Title with different color for the category name
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'معلومات عن ',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA33535),
                          ),
                        ),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA33535),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Plant image with rounded corners in the middle
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        widget.imageAsset,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 220,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading plant image: $error');
                          return Container(
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Icon(Icons.eco,
                                  color: Colors.green, size: 40),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Description text
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: Text(
                      widget.description ?? 'لا يوجد وصف متاح لهذا التصنيف.',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                  ),

                  // Plants in this category section
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'خطأ في تحميل النباتات: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (_plants.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'لا توجد نباتات في هذه الفئة حالياً.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    _buildPlantsList(),

                  // Read more button and heart icon
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 20.0),
                    child: Row(
                      children: [
                        // Heart icon in circle with border
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF96C994),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.favorite_border,
                              color: Color(0xFF96C994),
                              size: 26,
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Read more button
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Implement read more functionality
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF96C994),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(23),
                                ),
                              ),
                              child: const Text(
                                'اقرأ المزيد',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom navigation bar
          const BottomNavBar(selectedIndex: 3),
        ],
      ),
    );
  }

  Widget _buildPlantsList() {
    // Determine how many plants to show based on state
    final displayedPlants = _showAllPlants
        ? _plants
        : (_plants.length > 5 ? _plants.sublist(0, 5) : _plants);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8.0, bottom: 12.0),
            child: Text(
              'النباتات في هذه الفئة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                displayedPlants.length, // Show all or just 5 based on state
            itemBuilder: (context, index) {
              final plant = displayedPlants[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  title: Text(
                    plant['name_arabic'] ?? 'اسم غير معروف',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textDirection: TextDirection.rtl,
                  ),
                  subtitle: Text(
                    plant['name_scientific'] ?? '',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  leading: plant['image_url'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            plant['image_url'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                color: Colors.green.withOpacity(0.1),
                                child:
                                    const Icon(Icons.eco, color: Colors.green),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.eco, color: Colors.green),
                        ),
                  // Removed arrow_forward_ios icon as requested
                  onTap: () {
                    // TODO: Navigate to individual plant detail screen
                    print('Tapped on plant: ${plant['name_arabic']}');
                  },
                ),
              );
            },
          ),
          if (_plants.length > 5 && !_showAllPlants)
            Center(
              child: TextButton(
                onPressed: () {
                  // Toggle to show all plants
                  setState(() {
                    _showAllPlants = true;
                  });
                },
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(
                    color: Color(0xFF96C994),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
