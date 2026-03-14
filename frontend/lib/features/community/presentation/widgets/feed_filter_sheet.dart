import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/constants/us_locations.dart';

class FeedFilterSheet extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedState;
  final String? selectedCity;
  final void Function({
    String? category,
    String? state,
    String? city,
  }) onApply;

  const FeedFilterSheet({
    super.key,
    this.selectedCategory,
    this.selectedState,
    this.selectedCity,
    required this.onApply,
  });

  @override
  State<FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends State<FeedFilterSheet> {
  late String? _category = widget.selectedCategory;
  late String? _state = widget.selectedState;
  late String? _city = widget.selectedCity;

  void _apply() {
    widget.onApply(category: _category, state: _state, city: _city);
    Navigator.of(context).pop();
  }

  void _clear() {
    widget.onApply(category: null, state: null, city: null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    FButton(
                      variant: FButtonVariant.ghost,
                      onPress: _clear,
                      child: const Text('Clear'),
                    ),
                    Expanded(
                      child: Text(
                        'Filters',
                        textAlign: TextAlign.center,
                        style: typography.lg.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FButton(
                      onPress: _apply,
                      child: const Text('Apply'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                FSelect<String>(
                  items: {for (final c in postCategories) c: c},
                  control: FSelectControl.lifted(
                    value: _category,
                    onChange: (value) => setState(() => _category = value),
                  ),
                  autoHide: true,
                  label: const Text('Category'),
                  hint: 'All categories',
                ),
                const SizedBox(height: AppSpacing.lg),
                FSelect<String>(
                  items: {for (final s in UsLocations.states) s: s},
                  control: FSelectControl.lifted(
                    value: _state,
                    onChange: (value) {
                      setState(() {
                        _state = value;
                        _city = null;
                      });
                    },
                  ),
                  autoHide: true,
                  label: const Text('State'),
                  hint: 'All states',
                ),
                const SizedBox(height: AppSpacing.lg),
                FSelect<String>(
                  items: _state != null
                      ? {
                          for (final c in UsLocations.citiesFor(_state!)) c: c,
                        }
                      : const {},
                  control: FSelectControl.lifted(
                    value: _city,
                    onChange: (value) => setState(() => _city = value),
                  ),
                  autoHide: true,
                  label: const Text('City'),
                  hint: _state != null ? 'All cities' : 'Select a state first',
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
