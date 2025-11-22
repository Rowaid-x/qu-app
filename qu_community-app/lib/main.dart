import 'package:flutter/material.dart';

import 'pages/bus_page.dart';
import 'pages/classes_page.dart';
import 'pages/community_page.dart';
import 'pages/profile_page.dart';
import 'pages/calendar_page.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/bus_driver_navigation.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const QuCommunityApp());
}

class QuCommunityApp extends StatelessWidget {
  const QuCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryMaroon = Color(0xFF8A1538);

    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primaryMaroon,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryMaroon,
      onPrimary: Colors.white,
    );

    return MaterialApp(
      title: 'qu_community',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const AuthWrapper(child: _NavigationSelector()),
      routes: {
        '/home': (context) => const AuthWrapper(child: _NavigationSelector()),
      },
    );
  }
}

class _NavigationSelector extends StatelessWidget {
  const _NavigationSelector();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.getCurrentUserType(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A1538)),
              ),
            ),
          );
        }

        final userType = snapshot.data;
        
        if (userType == 'bus_driver') {
          return const BusDriverNavigation();
        } else {
          // For students and admins, show full navigation
          return const _RootNavigation();
        }
      },
    );
  }
}

class _RootNavigation extends StatefulWidget {
  const _RootNavigation();

  @override
  State<_RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<_RootNavigation> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    BusPage(),
    ClassesPage(),
    CalendarPage(),
    CommunityPage(),
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
          NavigationDestination(icon: Icon(Icons.directions_bus), label: 'Bus'),
          NavigationDestination(icon: Icon(Icons.class_), label: 'Classes'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.forum), label: 'Community'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
