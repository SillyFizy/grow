import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/category_screen.dart';
import '../screens/plant_details_screen.dart';

class Routes {
  static const String login = '/login';
  static const String home = '/';
  static const String categories = '/categories';
  static const String plantDetails = '/plant_details';

  static Map<String, WidgetBuilder> getRoutes() {
    print('Setting up application routes');

    return {
      login: (context) {
        print('Building LoginScreen via routes');
        return const LoginScreen();
      },
      home: (context) {
        print('Building HomeScreen via routes');
        return const HomeScreen();
      },
      categories: (context) {
        print('Building CategoryScreen via routes');
        return const CategoryScreen();
      },
      // For the plant details route, we will use a different approach
      // since we need to pass arguments
    };
  }

  // Helper method for direct navigation with debugging
  static void navigateTo(BuildContext context, String routeName) {
    print('Navigating to route: $routeName');
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  // Helper method for navigating to plant details with arguments
  static void navigateToPlantDetails(
      BuildContext context, String title, String imageAsset,
      [String? description]) {
    print('Navigating to plant details with title: $title, image: $imageAsset');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlantDetailsScreen(
          title: title,
          imageAsset: imageAsset,
          description: description,
        ),
      ),
    );
  }
}
