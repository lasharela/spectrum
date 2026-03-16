import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/admin_provider.dart';

class AdminEventsView extends ConsumerWidget {
  const AdminEventsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(pendingEventsProvider);

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (events) {
        if (events.isEmpty) {
          return const Center(child: Text('No pending events'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingEventsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (ctx, i) => _EventCard(event: events[i]),
          ),
        );
      },
    );
  }
}

class _EventCard extends ConsumerWidget {
  final Map<String, dynamic> event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizer = event['organizer'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event['title'] as String? ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Category: ${event['category'] ?? ''}'),
            if (organizer != null)
              Text('Organizer: ${organizer['name'] ?? ''}'),
            Text('Date: ${event['startDate'] ?? ''}'),
            Text('Status: ${event['status'] ?? ''}'),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: () => _handleAction(ref, context, 'approved'),
                  child: const Text('Approve'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _handleAction(ref, context, 'rejected'),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
      WidgetRef ref, BuildContext context, String status) async {
    final id = event['id'] as String;
    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.approveEvent(id, status);
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Event ${status == 'approved' ? 'approved' : 'rejected'}',
          ),
        ),
      );
      ref.invalidate(pendingEventsProvider);
    }
  }
}
