import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/admin_provider.dart';

/// Human-readable labels for each category type.
const _categoryTypes = <String, String>{
  'catalog': 'Catalog',
  'event': 'Event',
  'promotion': 'Promotion',
  'age-group': 'Age Group',
  'special-need': 'Special Need',
};

class AdminCategoriesView extends ConsumerStatefulWidget {
  const AdminCategoriesView({super.key});

  @override
  ConsumerState<AdminCategoriesView> createState() =>
      _AdminCategoriesViewState();
}

class _AdminCategoriesViewState extends ConsumerState<AdminCategoriesView> {
  String _selectedType = 'catalog';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesProvider(_selectedType));

    return Column(
      children: [
        // Type selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Category Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _categoryTypes.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _showCategoryDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Category list
        Expanded(
          child: categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (categories) {
              if (categories.isEmpty) {
                return const Center(child: Text('No categories'));
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(adminCategoriesProvider(_selectedType)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (ctx, i) => _CategoryTile(
                    category: categories[i],
                    type: _selectedType,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCategoryDialog(BuildContext context) {
    _openCategoryFormDialog(
      context: context,
      ref: ref,
      type: _selectedType,
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final Map<String, dynamic> category;
  final String type;

  const _CategoryTile({required this.category, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = category['name'] as String? ?? '';
    final icon = category['icon'] as String? ?? '';
    final sortOrder = category['sortOrder'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: icon.isNotEmpty
            ? CircleAvatar(child: Text(icon, style: const TextStyle(fontSize: 20)))
            : const CircleAvatar(child: Icon(Icons.label)),
        title: Text(name),
        subtitle: Text('Sort order: ${sortOrder ?? 0}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _edit(context, ref),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              onPressed: () => _delete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context, WidgetRef ref) {
    _openCategoryFormDialog(
      context: context,
      ref: ref,
      type: type,
      existing: category,
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${category['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final id = category['id'] as String;
      final repo = ref.read(adminRepositoryProvider);
      final success = await repo.deleteCategory(type, id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted')),
        );
        ref.invalidate(adminCategoriesProvider(type));
      }
    }
  }
}

/// Opens a dialog to create or edit a category.
void _openCategoryFormDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String type,
  Map<String, dynamic>? existing,
}) {
  final isEditing = existing != null;
  final nameController =
      TextEditingController(text: existing?['name'] as String? ?? '');
  final iconController =
      TextEditingController(text: existing?['icon'] as String? ?? '');
  final sortOrderController = TextEditingController(
    text: '${existing?['sortOrder'] ?? 0}',
  );

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isEditing ? 'Edit Category' : 'Add Category'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icon (emoji or text)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sortOrderController,
              decoration: const InputDecoration(
                labelText: 'Sort Order',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final name = nameController.text.trim();
            if (name.isEmpty) return;

            final body = <String, dynamic>{
              'name': name,
              'icon': iconController.text.trim(),
              'sortOrder': int.tryParse(sortOrderController.text) ?? 0,
            };

            final repo = ref.read(adminRepositoryProvider);

            if (isEditing) {
              final id = existing['id'] as String;
              await repo.updateCategory(type, id, body);
            } else {
              await repo.createCategory(type, body);
            }

            ref.invalidate(adminCategoriesProvider(type));

            if (ctx.mounted) Navigator.of(ctx).pop();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEditing ? 'Category updated' : 'Category created',
                  ),
                ),
              );
            }
          },
          child: Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    ),
  );
}
