import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class MainNavigationShell extends StatefulWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  static const _destinations = [
    _NavDestination(Icons.home, 'Home', '/home'),
    _NavDestination(Icons.people, 'Community', '/community'),
    _NavDestination(Icons.storefront, 'Catalogue', '/catalog'),
    _NavDestination(Icons.local_offer, 'Promotions', '/promotions'),
    _NavDestination(Icons.event, 'Events', '/events'),
  ];

  int _indexFromLocation(String location) {
    for (var i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFromLocation(location);

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
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _destinations.asMap().entries.map((entry) {
                final index = entry.key;
                final dest = entry.value;
                final isSelected = selectedIndex == index;

                return Expanded(
                  child: InkWell(
                    onTap: () => context.go(dest.route),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            dest.icon,
                            color: isSelected
                                ? AppColors.cyan
                                : AppColors.textGray,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dest.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? AppColors.cyan
                                  : AppColors.textGray,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
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

class _NavDestination {
  final IconData icon;
  final String label;
  final String route;

  const _NavDestination(this.icon, this.label, this.route);
}
