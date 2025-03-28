import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';
import '../models/PlantCategory.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building CategoryScreen');
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                            print('Error loading logo in CategoryScreen: $error');
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
                    // Grid of plant categories
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildPlantCategoriesGrid(),
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

  Widget _buildPlantCategoriesGrid() {
    print('Building plant categories grid');
    
    final plants = [
      {'name': 'الشاميدوريا', 'image': 'image-1.png'},
      {'name': 'زاميا', 'image': 'image-2.png'},
      {'name': 'دراسينا', 'image': 'image-3.png'},
      {'name': 'نبات الفيلكا', 'image': 'image-4.png'},
      {'name': 'بامبو', 'image': 'image-5.png'},
      {'name': 'ميكونيكا يونسالي', 'image': 'image-6.png'},
      {'name': 'زيني الفلامنغو', 'image': 'image-7.png'},
      {'name': 'المنكوتين', 'image': 'image-8.png'},
      {'name': 'الأوركيد', 'image': 'image-9.png'},
      {'name': 'النباتات الصغيرة', 'image': 'image-10.png'},
      {'name': 'جلد النمر', 'image': 'image-11.png'},
      {'name': 'مونستيرا', 'image': 'image.png'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: plants.length,
      itemBuilder: (context, index) {
        return _buildPlantCategoryItem(
          name: plants[index]['name'] as String,
          imageName: plants[index]['image'] as String,
        );
      },
    );
  }

  Widget _buildPlantCategoryItem({required String name, required String imageName}) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
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
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/images/$imageName',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading plant image $imageName: $error');
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Icon(Icons.eco, color: Colors.green),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}