import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/constants/us_locations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FeedFilterSheet extends ConsumerStatefulWidget {
  final String? selectedCategory;
  final String? selectedState;
  final String? selectedCity;
  final String? defaultState;
  final String? defaultCity;
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
    this.defaultState,
    this.defaultCity,
    required this.onApply,
  });

  @override
  ConsumerState<FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends ConsumerState<FeedFilterSheet> {
  late String? _category = widget.selectedCategory;
  late String? _state = widget.selectedState ?? widget.defaultState;
  late String? _city = widget.selectedCity ?? widget.defaultCity;
  late final TextEditingController _cityController;

  List<String> _citySuggestions = [];
  bool _loadingCities = false;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: _city ?? '');
    if (_state != null) _fetchCities(_state!);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchCities(String state) async {
    setState(() => _loadingCities = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final cities = await repo.getCities(state);
      if (mounted) {
        setState(() {
          _citySuggestions = cities;
          _loadingCities = false;
        });
      }
    } catch (_) {
      // Fallback to hardcoded cities if API fails
      if (mounted) {
        setState(() {
          _citySuggestions = UsLocations.citiesFor(state);
          _loadingCities = false;
        });
      }
    }
  }

  List<String> get _filteredCities {
    final query = _cityController.text.toLowerCase();
    if (query.isEmpty) return _citySuggestions;
    return _citySuggestions
        .where((c) => c.toLowerCase().contains(query))
        .toList();
  }

  void _apply() {
    final cityText = _cityController.text.trim();
    widget.onApply(
      category: _category,
      state: _state,
      city: cityText.isEmpty ? null : cityText,
    );
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
                        _cityController.clear();
                        _citySuggestions = [];
                      });
                      if (value != null) _fetchCities(value);
                    },
                  ),
                  autoHide: true,
                  label: const Text('State'),
                  hint: 'All states',
                ),
                const SizedBox(height: AppSpacing.lg),
                FTextField(
                  control: FTextFieldControl.managed(
                    controller: _cityController,
                    onChange: (value) {
                      setState(() => _city = value.text);
                    },
                  ),
                  label: const Text('City'),
                  hint: _state != null ? 'Type to search cities' : 'Select a state first',
                  enabled: _state != null,
                ),
                if (_state != null && _cityController.text.isNotEmpty && _filteredCities.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    margin: const EdgeInsets.only(top: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: colors.background,
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = _filteredCities[index];
                        return ListTile(
                          dense: true,
                          title: Text(city, style: typography.sm),
                          onTap: () {
                            setState(() {
                              _city = city;
                              _cityController.text = city;
                            });
                          },
                        );
                      },
                    ),
                  ),
                if (_loadingCities)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: Center(child: FCircularProgress()),
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
