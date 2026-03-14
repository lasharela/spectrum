import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_spacing.dart';

const _categories = [
  'General',
  'Sensory',
  'Education',
  'Support',
  'Resources',
  'Daily Life',
  'News',
  'Social',
];

class NewDiscussionModal extends StatefulWidget {
  final void Function({
    String? title,
    required String content,
    String? imageUrl,
    required String category,
  }) onSubmit;

  const NewDiscussionModal({super.key, required this.onSubmit});

  @override
  State<NewDiscussionModal> createState() => _NewDiscussionModalState();
}

class _NewDiscussionModalState extends State<NewDiscussionModal> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'General';
  String? _pickedImagePath;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final title = _titleController.text.trim();
    widget.onSubmit(
      title: title.isEmpty ? null : title,
      content: content,
      imageUrl: _pickedImagePath,
      category: _selectedCategory,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _pickedImagePath = picked.path);
    }
  }

  void _removeImage() {
    setState(() => _pickedImagePath = null);
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;
    final canSubmit = _contentController.text.trim().isNotEmpty;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
                      onPress: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    Expanded(
                      child: Text(
                        'New Discussion',
                        textAlign: TextAlign.center,
                        style: typography.lg.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FButton(
                      onPress: canSubmit ? _submit : null,
                      child: const Text('Post'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                FTextField(
                  control: FTextFieldControl.managed(
                    controller: _titleController,
                  ),
                  label: const Text('Title'),
                  hint: 'Give your discussion a title (optional)',
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.lg),
                FSelect<String>(
                  items: {for (final category in _categories) category: category},
                  control: FSelectControl.lifted(
                    value: _selectedCategory,
                    onChange: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  autoHide: true,
                  label: const Text('Category'),
                  hint: 'Choose a category',
                ),
                const SizedBox(height: AppSpacing.lg),
                FTextField.multiline(
                  control: FTextFieldControl.managed(
                    controller: _contentController,
                    onChange: (_) => setState(() {}),
                  ),
                  label: const Text('Discussion'),
                  hint: 'Share your thoughts, question, or experience...',
                  minLines: 4,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.md),
                // Image section
                if (_pickedImagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.asset(
                              _pickedImagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: colors.muted,
                                child: Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: GestureDetector(
                            onTap: _removeImage,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.xxs),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(150),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: _pickImage,
                  prefix: const Icon(Icons.image_outlined),
                  child: Text(
                    _pickedImagePath != null ? 'Change Image' : 'Add Image',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Start with a specific question or a short piece of context so replies can be more useful.',
                  style: typography.xs.copyWith(
                    color: colors.mutedForeground,
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
