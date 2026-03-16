import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/admin_events_view.dart';
import '../widgets/admin_community_view.dart';
import '../widgets/admin_categories_view.dart';

enum AdminSection { events, community, categories }

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  AdminSection _section = AdminSection.events;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 768;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(),
            const VerticalDivider(width: 1),
            Expanded(child: _buildContent()),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: _buildContent(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _section.index,
        onDestinationSelected: (i) =>
            setState(() => _section = AdminSection.values[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.forum), label: 'Community'),
          NavigationDestination(
              icon: Icon(Icons.category), label: 'Categories'),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Admin Panel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          _sidebarItem(AdminSection.events, Icons.event, 'Events'),
          _sidebarItem(AdminSection.community, Icons.forum, 'Community'),
          _sidebarItem(AdminSection.categories, Icons.category, 'Categories'),
        ],
      ),
    );
  }

  Widget _sidebarItem(AdminSection section, IconData icon, String label) {
    final selected = _section == section;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      selected: selected,
      onTap: () => setState(() => _section = section),
    );
  }

  Widget _buildContent() {
    return switch (_section) {
      AdminSection.events => const AdminEventsView(),
      AdminSection.community => const AdminCommunityView(),
      AdminSection.categories => const AdminCategoriesView(),
    };
  }
}
