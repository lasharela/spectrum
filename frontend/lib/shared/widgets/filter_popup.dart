import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/constants/app_colors.dart';
import 'package:spectrum_app/core/constants/app_spacing.dart';
import 'package:spectrum_app/features/catalog/domain/filter_option.dart';

class FilterPopup extends StatefulWidget {
  final List<FilterGroup> filterGroups;
  final Map<String, Set<String>> selectedFilters; // groupLabel -> set of selected option IDs
  final ValueChanged<Map<String, Set<String>>> onApply;

  const FilterPopup({
    super.key,
    required this.filterGroups,
    required this.selectedFilters,
    required this.onApply,
  });

  @override
  State<FilterPopup> createState() => _FilterPopupState();
}

class _FilterPopupState extends State<FilterPopup> {
  late Map<String, Set<String>> _selections;

  @override
  void initState() {
    super.initState();
    _selections = {
      for (final entry in widget.selectedFilters.entries)
        entry.key: Set<String>.from(entry.value),
    };
  }

  void _toggleOption(String groupLabel, String optionId) {
    setState(() {
      final group = _selections.putIfAbsent(groupLabel, () => {});
      if (group.contains(optionId)) {
        group.remove(optionId);
      } else {
        group.add(optionId);
      }
    });
  }

  void _clearAll() {
    setState(() {
      for (final set in _selections.values) {
        set.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320, maxHeight: 480),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        color: theme.colors.background,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearAll,
                    child: Text(
                      'Clear All',
                      style: theme.typography.sm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Scrollable filter groups
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < widget.filterGroups.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.xl),
                        _buildFilterGroup(widget.filterGroups[i], theme),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: FButton(
                  onPress: () {
                    widget.onApply(_selections);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterGroup(FilterGroup group, FThemeData theme) {
    final selected = _selections[group.label] ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.label,
          style: theme.typography.sm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Use Column since FCheckbox renders label+checkbox as a row
        Column(
          children: group.options.map((option) {
            final isSelected = selected.contains(option.id);
            return FCheckbox(
              label: Text(option.name),
              value: isSelected,
              onChange: (_) => _toggleOption(group.label, option.id),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Filter trigger button with badge count.
class FilterTriggerButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const FilterTriggerButton({
    super.key,
    required this.activeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final hasActive = activeCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hasActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : theme.colors.background,
          borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
          border: Border.all(
            color: hasActive ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                Icons.tune,
                size: 20,
                color: hasActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (hasActive)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
