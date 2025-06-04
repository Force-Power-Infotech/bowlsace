import 'package:flutter/material.dart';
import '../../../ui/screens/dashboard/dashboard_screen.dart';
import '../../../ui/screens/practice/drill_groups_screen.dart';
import '../../../ui/screens/challenge/challenge_list_screen.dart';
import '../../../ui/screens/profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int selectedIndex;

  const MainNavigationScreen({super.key, this.selectedIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const DrillGroupsScreen(), // Updated to use DrillGroupsScreen
    const ChallengeListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_outlined),
            selectedIcon: Icon(Icons.sports),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Challenge',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
