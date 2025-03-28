import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const BottomNavBar({
    super.key,
    this.selectedIndex = 3,
  });

  @override
  Widget build(BuildContext context) {
    print('Building BottomNavBar with selectedIndex: $selectedIndex');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          print('Tab tapped: $index, current selectedIndex: $selectedIndex');

          // Only navigate if tapping a different tab
          if (index != selectedIndex) {
            print('Navigating to tab $index');

            switch (index) {
              case 0: // Profile
                print('Would navigate to Profile - not implemented');
                // TODO: Implement profile navigation when available
                break;
              case 1: // Weather/Categories
                print('Navigating to Categories route');
                Navigator.of(context).pushReplacementNamed('/categories');
                break;
              case 2: // Search
                print('Would navigate to Search - not implemented');
                // TODO: Implement search navigation when available
                break;
              case 3: // Home
                print('Navigating to Home route');
                Navigator.of(context).pushReplacementNamed('/');
                break;
            }
          } else {
            print('Already on tab $index, not navigating');
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny_outlined),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
        ],
      ),
    );
  }
}
