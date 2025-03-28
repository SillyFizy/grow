import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(height: 100);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Top banner with green background
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildGreenBanner(),
                    ),
                    const SizedBox(height: 24),
                    // Middle section with plant image and text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildAppPromoBanner(),
                    ),
                    const SizedBox(height: 24),
                    // Grid of category cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildCategoriesGrid(),
                    ),
                    const SizedBox(height: 24),
                    // Campaign section
                    _buildCampaignSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom navigation bar
            const BottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreenBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD1EAC5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text content on the right (for RTL layout)
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'الفئة الخضراء',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'تجمع ٧ نباتات الفئة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  'لفئة النباتات الخارجية ذات البيئة الدافئة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Checkmark circle on the left
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF96C994),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppPromoBanner() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background plant image covering the entire banner
            Positioned.fill(
              child: Image.asset(
                'assets/images/homescreen_banner.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.green.withOpacity(0.1),
                    child: const Center(
                      child: Icon(Icons.eco, color: Colors.green, size: 40),
                    ),
                  );
                },
              ),
            ),
            // Text overlay
            Positioned(
              right: 24,
              top: 0,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'THE BEST',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'APP FOR',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'YOUR PLANTS',
                    style: TextStyle(
                      fontSize: 22,
                      color: Color(0xFF96C994),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {'title': 'النباتات الجنينة', 'image': 'homescreen_p1.png'},
      {'title': 'النباتات السامة', 'image': 'homescreen_p2.png'},
      {'title': 'النباتات المعمرة', 'image': 'homescreen_p3.png'},
      {'title': 'منتجات طبيعية', 'image': 'homescreen_p4.png'},
      {'title': 'تحت منطق الزراع', 'image': 'homescreen_p5.png'},
      {'title': 'منتجات صديقة البيئة', 'image': 'homescreen_p6.png'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85, // Adjusted to make room for the text below
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            // Category image with shadow
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/${categories[index]['image']}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
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
            // Category title below the image
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                categories[index]['title'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCampaignSection() {
    return Column(
      children: [
        const Text(
          '! شارك بحملات تشجير معنا',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'تفحص جميع الحملات الموجودة',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}