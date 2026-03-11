import 'package:flutter/material.dart';
import '../pages/bus_page.dart';
import '../pages/profile_page.dart';

class BusDriverNavigation extends StatefulWidget {
  const BusDriverNavigation({super.key});

  @override
  State<BusDriverNavigation> createState() => _BusDriverNavigationState();
}

class _BusDriverNavigationState extends State<BusDriverNavigation> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    BusPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.directions_bus),
            label: 'Bus',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
