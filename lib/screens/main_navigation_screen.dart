import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';
import 'resources_screen.dart';
import 'promotions_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const ResourcesScreen(),
    const CatalogScreen(),
    const PromotionsScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = [
    'Spectrum',
    'Resources',
    'Catalogue',
    'Promotions',
    'Profile',
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
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
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: AppColors.surface,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Spectrum',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Community Support Platform',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                selected: _selectedIndex == 0,
                selectedTileColor: AppColors.primary.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Resources'),
                selected: _selectedIndex == 1,
                selectedTileColor: AppColors.primary.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: const Text('Catalogue'),
                selected: _selectedIndex == 2,
                selectedTileColor: AppColors.primary.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_offer_outlined),
                title: const Text('Promotions'),
                selected: _selectedIndex == 3,
                selectedTileColor: AppColors.primary.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 3;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile'),
                selected: _selectedIndex == 4,
                selectedTileColor: AppColors.primary.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 4;
                  });
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings coming soon'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Help section coming soon'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                onTap: () {
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: 'Spectrum',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2024 Spectrum Community',
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'A community-driven platform to support individuals with autism and their families.',
                      ),
                    ],
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  'Logout',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate back to login
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
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
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 24),
              activeIcon: Icon(Icons.home, size: 24),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined, size: 24),
              activeIcon: Icon(Icons.menu_book, size: 24),
              label: 'Resources',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 2 ? AppColors.primary : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.place_outlined,
                  size: 28,
                  color: _selectedIndex == 2 ? Colors.white : AppColors.primary,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.place,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              label: 'Catalogue',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.local_offer_outlined, size: 24),
              activeIcon: Icon(Icons.local_offer, size: 24),
              label: 'Promotions',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 24),
              activeIcon: Icon(Icons.person, size: 24),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}