import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/category_screen.dart';

class Routes {
  static const String login = '/login';
  static const String home = '/';
  static const String categories = '/categories';

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
    };
  }

  // Helper method for direct navigation with debugging
  static void navigateTo(BuildContext context, String routeName) {
    print('Navigating to route: $routeName');
    Navigator.of(context).pushReplacementNamed(routeName);
  }
}
