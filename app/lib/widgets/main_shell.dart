import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.navy,
        indicatorColor: AppColors.blue,
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home, color: Colors.white), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long, color: Colors.white),
              label: 'Order'),
          NavigationDestination(
              icon: Icon(Icons.bookmark, color: Colors.white),
              label: 'Wishlist'),
          NavigationDestination(
              icon: Icon(Icons.person, color: Colors.white), label: 'Profile'),
        ],
      ),
    );
  }
}