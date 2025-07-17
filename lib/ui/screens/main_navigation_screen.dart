import 'package:flutter/material.dart';
import '../../../ui/screens/dashboard/dashboard_screen.dart';
import '../../../ui/screens/practice/drill_groups_screen.dart';
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
    const DrillGroupsScreen(),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.18),
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.25)
                  : Colors.grey.withOpacity(0.13),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            selectedItemColor: Theme.of(context).colorScheme.secondary,
            unselectedItemColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[500]
                : Colors.grey[600],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0
                        ? Theme.of(context).colorScheme.secondary.withOpacity(0.13)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(Icons.dashboard_outlined),
                ),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1
                        ? Theme.of(context).colorScheme.secondary.withOpacity(0.13)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(Icons.sports_outlined),
                ),
                label: 'Practice',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2
                        ? Theme.of(context).colorScheme.secondary.withOpacity(0.13)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(Icons.person_outline),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
