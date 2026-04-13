import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _navbarPurple = Color(0xFF7C3AED);
const _navbarLightPurple = Color(0xFFF3F0FF);

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem(label: 'Eğitim', icon: Icons.school_outlined, route: '/home'),
    _TabItem(
      label: 'Soru Sor',
      icon: Icons.chat_bubble_outline,
      route: '/ask',
    ),
    _TabItem(label: 'Profil', icon: Icons.person_outline, route: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        height: 65,
        backgroundColor: Colors.white,
        indicatorColor: _navbarLightPurple,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon, size: 26),
                selectedIcon: Icon(tab.icon, size: 26, color: _navbarPurple),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}
