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

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    _NavItem(icon: Icons.sports_outlined, label: 'Practice'),
    _NavItem(icon: Icons.person_outline, label: 'Profile'),
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
      final theme = Theme.of(context);
      final navTheme = Theme.of(context).bottomNavigationBarTheme;
      return Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: navTheme.backgroundColor,
             borderRadius: const BorderRadius.only(
               topLeft: Radius.circular(24),
               topRight: Radius.circular(24),
             ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final selected = _selectedIndex == index;
              final item = _navItems[index];
              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: selected
                      ? const EdgeInsets.symmetric(horizontal: 18, vertical: 8)
                      : const EdgeInsets.all(8),
                  decoration: selected
                      ? BoxDecoration(
                          color: navTheme.selectedItemColor,
                          borderRadius: BorderRadius.circular(24),
                        )
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: selected
                            ? Colors.white
                            : navTheme.unselectedItemColor ?? theme.iconTheme.color?.withOpacity(0.7),
                        size: 28,
                      ),
                      if (selected) ...[
                        const SizedBox(width: 10),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      );
    }
  }

  class _NavItem {
    final IconData icon;
    final String label;
    const _NavItem({required this.icon, required this.label});
  }
//             items: [
//               BottomNavigationBarItem(
//                 icon: AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   decoration: BoxDecoration(
//                     color: _selectedIndex == 0
//                         ? Theme.of(context).colorScheme.secondary.withOpacity(0.13)
//                         : Colors.transparent,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                   child: Icon(Icons.dashboard_outlined),
//                 ),
//                 label: 'Dashboard',
//               ),
//               BottomNavigationBarItem(
//                 icon: AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   decoration: BoxDecoration(
//                     color: _selectedIndex == 1
//                         ? Theme.of(context).colorScheme.secondary.withOpacity(0.13)
//                         : Colors.transparent,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                   child: Icon(Icons.sports_outlined),
//                 ),
//                 label: 'Practice',
//               ),
//               BottomNavigationBarItem(
//                 icon: AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   decoration: BoxDecoration(
//                     color: _selectedIndex == 2
//                         ? Theme.of(context).colorScheme.secondary.withOpacity(0.13)
//                         : Colors.transparent,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                   child: Icon(Icons.person_outline),
//                 ),
//                 label: 'Profile',
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
