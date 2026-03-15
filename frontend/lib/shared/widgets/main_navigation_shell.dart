import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'spectrum_app_bar.dart';

class MainNavigationShell extends StatefulWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  static const _routes = ['/home', '/community', '/catalog', '/promotions', '/events'];
  static const _titles = ['Home', 'Community', 'Catalogue', 'Promotions', 'Events'];

  int _indexFromLocation(String location) {
    for (var i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  bool _isDetailRoute(String location) {
    for (final route in _routes) {
      if (location.startsWith(route) && location != route) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFromLocation(location);
    final isDetail = _isDetailRoute(location);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (isDetail)
              _DetailAppBar(onBack: () => context.pop())
            else
              SpectrumAppBar(title: _titles[selectedIndex]),
            Expanded(child: widget.child),
          ],
        ),
      ),
      bottomNavigationBar: FBottomNavigationBar(
        index: selectedIndex,
        onChange: (index) => context.go(_routes[index]),
        children: const [
          FBottomNavigationBarItem(icon: Icon(Icons.home), label: Text('Home')),
          FBottomNavigationBarItem(icon: Icon(Icons.people), label: Text('Community')),
          FBottomNavigationBarItem(icon: Icon(Icons.storefront), label: Text('Catalogue')),
          FBottomNavigationBarItem(icon: Icon(Icons.local_offer), label: Text('Promotions')),
          FBottomNavigationBarItem(icon: Icon(Icons.event), label: Text('Events')),
        ],
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  final VoidCallback onBack;

  const _DetailAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return FHeader.nested(
      title: const Text('Place Details'),
      titleAlignment: Alignment.center,
      prefixes: [
        FHeaderAction(
          icon: const Icon(Icons.arrow_back_rounded),
          onPress: onBack,
        ),
      ],
    );
  }
}
