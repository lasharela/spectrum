import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';

class MainNavigationShell extends StatefulWidget {
  final Widget child;
  
  const MainNavigationShell({super.key, required this.child});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;
  
  final List<Map<String, dynamic>> _destinations = [
    {'icon': Icons.home, 'label': 'Home', 'route': '/home'},
    {'icon': Icons.people, 'label': AppStrings.community, 'route': '/community'},
    {'icon': Icons.library_books, 'label': AppStrings.resources, 'route': '/resources'},
    {'icon': Icons.person, 'label': AppStrings.profile, 'route': '/profile'},
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    context.go(_destinations[index]['route']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _destinations.asMap().entries.map((entry) {
                final index = entry.key;
                final dest = entry.value;
                final isSelected = _selectedIndex == index;
                
                return Expanded(
                  child: InkWell(
                    onTap: () => _onItemTapped(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            dest['icon'],
                            color: isSelected ? AppColors.cyan : AppColors.textGray,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dest['label'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? AppColors.cyan : AppColors.textGray,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}