import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../data/events_repository.dart';
import '../providers/events_provider.dart';

class CreateEventModal extends ConsumerStatefulWidget {
  const CreateEventModal({super.key});

  @override
  ConsumerState<CreateEventModal> createState() => _CreateEventModalState();
}

class _CreateEventModalState extends ConsumerState<CreateEventModal> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategory;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isOnline = false;
  bool _isFree = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _selectedCategory != null &&
      !_isSubmitting;

  DateTime get _combinedStartDate {
    return DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    final repo = ref.read(eventsRepositoryProvider);
    final event = await repo.createEvent(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _selectedCategory!,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      startDate: _combinedStartDate,
      isOnline: _isOnline,
      isFree: _isFree,
      price: !_isFree && _priceController.text.trim().isNotEmpty
          ? _priceController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (event != null) {
      ref.read(eventsProvider.notifier).refresh();
      ref.invalidate(myEventsProvider);
      Navigator.of(context).pop();
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final categoriesAsync = ref.watch(eventFilterOptionsProvider);
    final dateFormat = DateFormat('MMM d, yyyy');

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
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg + bottomInset,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
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

                // Header
                Row(
                  children: [
                    FButton(
                      variant: FButtonVariant.ghost,
                      onPress: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    Expanded(
                      child: Text(
                        'New Event',
                        textAlign: TextAlign.center,
                        style: typography.lg.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FButton(
                      onPress: _canSubmit ? _submit : null,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title
                FTextField(
                  control: FTextFieldControl.managed(
                    controller: _titleController,
                    onChange: (_) => setState(() {}),
                  ),
                  label: const Text('Title'),
                  hint: 'Event title',
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Category
                categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (options) {
                    final categories = options.categories;
                    return FSelect<String>.rich(
                      label: const Text('Category'),
                      hint: 'Choose a category',
                      format: (s) => s,
                      control: FSelectControl.lifted(
                        value: _selectedCategory,
                        onChange: (value) {
                          if (value != null) {
                            setState(() => _selectedCategory = value);
                          }
                        },
                      ),
                      children: [
                        for (final cat in categories)
                          FSelectItem(title: Text(cat.name), value: cat.name),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Description
                FTextField.multiline(
                  control: FTextFieldControl.managed(
                    controller: _descriptionController,
                    onChange: (_) => setState(() {}),
                  ),
                  label: const Text('Description'),
                  hint: 'Describe your event...',
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Date & time row
                Text(
                  'Date & Time',
                  style: typography.sm.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FButton(
                        variant: FButtonVariant.outline,
                        onPress: _pickDate,
                        prefix: const Icon(Icons.calendar_today_outlined),
                        child: Text(dateFormat.format(_startDate)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FButton(
                        variant: FButtonVariant.outline,
                        onPress: _pickTime,
                        prefix: const Icon(Icons.access_time_outlined),
                        child: Text(_startTime.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Online toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Online Event',
                          style: typography.sm
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'This event takes place virtually',
                          style: typography.xs
                              .copyWith(color: colors.mutedForeground),
                        ),
                      ],
                    ),
                    FSwitch(
                      value: _isOnline,
                      onChange: (value) {
                        setState(() => _isOnline = value);
                        if (value) _locationController.clear();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Location
                FTextField(
                  enabled: !_isOnline,
                  control: FTextFieldControl.managed(
                    controller: _locationController,
                  ),
                  label: const Text('Location'),
                  hint: _isOnline ? 'Online event' : 'Event address',
                  prefixBuilder: (context, style, variants) => Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: IconTheme(
                      data: style.iconStyle.resolve(variants),
                      child: Icon(
                        _isOnline
                            ? Icons.computer_outlined
                            : Icons.location_on_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Free toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Free Event',
                          style: typography.sm
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'No charge for attendees',
                          style: typography.xs
                              .copyWith(color: colors.mutedForeground),
                        ),
                      ],
                    ),
                    FSwitch(
                      value: _isFree,
                      onChange: (value) => setState(() => _isFree = value),
                    ),
                  ],
                ),

                // Price field (only when not free)
                if (!_isFree) ...[
                  const SizedBox(height: AppSpacing.lg),
                  FTextField(
                    control: FTextFieldControl.managed(
                      controller: _priceController,
                    ),
                    label: const Text('Price'),
                    hint: 'e.g. \$25',
                  ),
                ],

                const SizedBox(height: AppSpacing.md),
                Text(
                  'Events require admin approval before they appear publicly.',
                  style: typography.xs.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
