import 'package:flutter/material.dart';
import '../widgets/BottomNavBar.dart';
import '../utils/routes.dart';
import '../models/plant_classification.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<PlantClassification> _classifications = [];

  @override
  void initState() {
    super.initState();
    // Initialize predefined classifications
    _initializeClassifications();
  }

  void _initializeClassifications() {
    // These are the predefined classifications with descriptions
    setState(() {
      _classifications = [
        PlantClassification(
            title: 'نباتات برية',
            classification: 'بري',
            imageAsset: 'homescreen_p1.png',
            description:
                'النباتات البرية هي نباتات تنمو طبيعياً دون تدخل بشري، وتتكيف مع ظروف بيئتها المحلية. تتميز بقدرتها على التحمل والبقاء في ظروف قاسية، وتشكل جزءاً أساسياً من النظم البيئية الطبيعية، توفر الغذاء والمأوى للحياة البرية.'),
        PlantClassification(
            title: 'نباتات اقتصادية',
            classification: 'اقتصادي',
            imageAsset: 'homescreen_p2.png',
            description:
                'النباتات الاقتصادية هي نباتات تزرع لقيمتها التجارية والاقتصادية. تشمل المحاصيل الغذائية، والألياف، والأخشاب، والزيوت، والأصباغ. تساهم هذه النباتات بشكل كبير في الاقتصاد المحلي والعالمي، وتوفر الموارد الأساسية للعديد من الصناعات والاحتياجات البشرية.'),
        PlantClassification(
            title: 'نباتات طبية',
            classification: 'طبي',
            imageAsset: 'homescreen_p3.png',
            description:
                'النباتات الطبية هي نباتات تحتوي على مواد فعالة تستخدم في العلاج والوقاية من الأمراض. استخدمت هذه النباتات في الطب التقليدي منذ آلاف السنين، وتشكل أساسًا للعديد من الأدوية الحديثة. تتميز بخصائصها العلاجية المتنوعة، من مضادات الالتهاب إلى المضادات الحيوية الطبيعية.'),
        PlantClassification(
            title: 'نباتات الزينة',
            classification: 'نباتات الزينة',
            imageAsset: 'homescreen_p4.png',
            description:
                'نباتات الزينة هي نباتات تزرع لجمالها وقيمتها الجمالية. تشمل الأزهار والشجيرات والأشجار التي تستخدم لتزيين الحدائق والمنازل والمساحات العامة. تضيف هذه النباتات الجمال إلى البيئة المحيطة، وتحسن جودة الهواء، وتساعد على تخفيف التوتر وتعزيز الراحة النفسية.'),
      ];
    });
  }

  // Function to fetch plants for a specific classification
  Future<void> _fetchPlantsByClassification(String classification) async {
    try {
      final response =
          await ApiService.fetchPlantsByClassification(classification);
      if (response.success) {
        // Process the data if needed
        print(
            'Successfully fetched plants for classification: $classification');
        print('Number of plants: ${response.data['results']?.length ?? 0}');
      } else {
        print('Error fetching plants: ${response.errorMessage}');
      }
    } catch (e) {
      print('Exception fetching plants: $e');
    }
  }

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
                            print('Error loading logo in HomeScreen: $error');
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
                      child: _buildCategoriesGrid(context),
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
            Builder(
              builder: (context) {
                return const BottomNavBar(selectedIndex: 3);
              },
            ),
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
                  print('Error loading banner image: $error');
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

  Widget _buildCategoriesGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 8.0, bottom: 16.0),
          child: Text(
            'تصنيفات النباتات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _classifications.length,
          itemBuilder: (context, index) {
            final classification = _classifications[index];
            return GestureDetector(
              onTap: () {
                print('Category tapped: ${classification.title}');
                // Fetch plants for this classification when tapped
                _fetchPlantsByClassification(classification.classification);
                // Navigate to plant details screen with category details
                Routes.navigateToPlantDetails(
                    context,
                    classification.title,
                    'assets/images/${classification.imageAsset}',
                    classification.description);
              },
              child: _buildCategoryItem(classification),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryItem(PlantClassification classification) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Column(
        children: [
          // Category image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.asset(
                'assets/images/${classification.imageAsset}',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  print(
                      'Error loading category image ${classification.imageAsset}: $error');
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.eco, color: Colors.green),
                    ),
                  );
                },
              ),
            ),
          ),
          // Category title
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              classification.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
