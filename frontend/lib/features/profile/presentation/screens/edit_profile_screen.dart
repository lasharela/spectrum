import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/us_locations.dart';
import '../../../../shared/widgets/screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _cityController;
  String? _selectedState;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _middleNameController = TextEditingController(text: user?.middleName ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _selectedState = user?.state;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            middleName: _middleNameController.text.isEmpty
                ? null
                : _middleNameController.text,
            userState: _selectedState,
            city: _cityController.text.isEmpty ? null : _cityController.text,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Screen(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              FHeader.nested(
                title: const Text('Edit Profile'),
                prefixes: [
                  FHeaderAction.back(onPress: () => context.pop()),
                ],
                suffixes: [
                  FHeaderAction(
                    icon: const Icon(FIcons.check),
                    onPress: _saving ? null : _save,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FTextField(
                      control: FTextFieldControl.managed(
                        controller: _firstNameController,
                      ),
                      label: const Text('First Name'),
                      hint: 'First name',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FTextField(
                      control: FTextFieldControl.managed(
                        controller: _middleNameController,
                      ),
                      label: const Text('Middle Name'),
                      hint: 'Middle name (optional)',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FTextField(
                      control: FTextFieldControl.managed(
                        controller: _lastNameController,
                      ),
                      label: const Text('Last Name'),
                      hint: 'Last name',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FSelect<String>(
                      items: {for (final s in UsLocations.states) s: s},
                      control: FSelectControl.lifted(
                        value: _selectedState,
                        onChange: (value) {
                          setState(() {
                            _selectedState = value;
                            _cityController.clear();
                          });
                        },
                      ),
                      autoHide: true,
                      label: const Text('State'),
                      hint: 'Select your state',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FTextField(
                      control: FTextFieldControl.managed(
                        controller: _cityController,
                      ),
                      label: const Text('City'),
                      hint: _selectedState != null
                          ? 'Enter your city'
                          : 'Select a state first',
                      enabled: _selectedState != null,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: FButton(
                        onPress: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
