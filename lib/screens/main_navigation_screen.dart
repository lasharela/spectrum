import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';
import 'promotions_screen.dart';
import 'events_screen.dart';
import 'community_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const CatalogScreen(),
    const PromotionsScreen(),
    const EventsScreen(),
    const CommunityScreen(),
  ];

  final List<String> _titles = [
    'Spectrum',
    'Catalogue',
    'Promotions',
    'Events',
    'Community',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications coming soon'),
                backgroundColor: AppColors.info,
              ),
            );
          },
        ),
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 24),
              activeIcon: Icon(Icons.home, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined, size: 24),
              activeIcon: Icon(Icons.category, size: 24),
              label: 'Catalogue',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_offer_outlined, size: 24),
              activeIcon: Icon(Icons.local_offer, size: 24),
              label: 'Promotions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined, size: 24),
              activeIcon: Icon(Icons.event, size: 24),
              label: 'Events',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined, size: 24),
              activeIcon: Icon(Icons.forum, size: 24),
              label: 'Community',
            ),
          ],
        ),
      ),
    );
  }
}