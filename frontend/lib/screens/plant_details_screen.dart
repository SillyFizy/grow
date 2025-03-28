import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';

class PlantDetailsScreen extends StatelessWidget {
  final String title;
  final String imageAsset;

  const PlantDetailsScreen({
    super.key,
    required this.title,
    required this.imageAsset,
  });

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
                          title,
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
                        imageAsset,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 400, // Make image take up more space
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading plant image: $error');
                          return Container(
                            height: 280,
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
                      'النباتات السامة هي نباتات تحتوي على مركبات كيميائية يمكن أن تسبب أضرارا صحية عند لمسها، ابتلاعها أو استنشاقها. تختلف خطورة السموم بين النباتات: بعضها يسبب تهيجا بسيطا في الجلد، بينما قد يكون البعض الآخر قاتلا. يجب الحذر عند تناوله. مثل نبات الدفلى أو الزينيب الإبري',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                  ),

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
}
