import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/api/api_exceptions.dart';
import '../../../../shared/widgets/screen.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _selectedUserType;

  static const _userTypeLabels = {
    'autistic_individual': 'Person with Autism',
    'parent': 'Parent/Caregiver',
    'professional': 'Professional',
    'educator': 'Educator',
    'therapist': 'Therapist',
    'supporter': 'Supporter',
  };

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final middleName = _middleNameController.text.trim();
      await ref.read(authProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            middleName: middleName.isEmpty ? null : middleName,
            lastName: _lastNameController.text.trim(),
            userType: _selectedUserType!,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message = 'Something went wrong';
        if (e is ApiException) {
          message = e.message;
        } else if (e is DioException && e.error is ApiException) {
          message = (e.error as ApiException).message;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Screen(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/onboarding'),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: colors.foreground,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Sign Up',
                        style: typography.xl2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FTextFormField(
                        control: FTextFieldControl.managed(
                          controller: _firstNameController,
                        ),
                        label: const Text('First Name'),
                        hint: 'Enter your first name',
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'First name is required';
                          }
                          if (value.length < 2) {
                            return 'Must be at least 2 characters';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.disabled,
                      ),
                      const SizedBox(height: 20),
                      FTextFormField(
                        control: FTextFieldControl.managed(
                          controller: _middleNameController,
                        ),
                        label: const Text('Middle Name (optional)'),
                        hint: 'Enter your middle name',
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      FTextFormField(
                        control: FTextFieldControl.managed(
                          controller: _lastNameController,
                        ),
                        label: const Text('Last Name'),
                        hint: 'Enter your last name',
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Last name is required';
                          }
                          if (value.length < 2) {
                            return 'Must be at least 2 characters';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.disabled,
                      ),
                      const SizedBox(height: 20),
                      FTextFormField(
                        control: FTextFieldControl.managed(
                          controller: _emailController,
                        ),
                        label: const Text('Email'),
                        hint: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.disabled,
                      ),
                      const SizedBox(height: 20),
                      FTextFormField.password(
                        control: FTextFieldControl.managed(
                          controller: _passwordController,
                        ),
                        label: const Text('Password'),
                        hint: 'Enter your password',
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 8) {
                            return 'Must be at least 8 characters';
                          }
                          if (!RegExp(r'[A-Z]').hasMatch(value)) {
                            return 'Must contain an uppercase letter';
                          }
                          if (!RegExp(r'[a-z]').hasMatch(value)) {
                            return 'Must contain a lowercase letter';
                          }
                          if (!RegExp(r'[0-9]').hasMatch(value)) {
                            return 'Must contain a number';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.disabled,
                      ),
                      const SizedBox(height: 20),
                      FTextFormField.password(
                        control: FTextFieldControl.managed(
                          controller: _confirmPasswordController,
                        ),
                        label: const Text('Confirm Password'),
                        hint: 'Re-enter your password',
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.disabled,
                      ),
                      const SizedBox(height: 20),
                      FSelect<String>.rich(
                        label: const Text('I am a...'),
                        hint: 'Select your role',
                        format: (value) => _userTypeLabels[value] ?? value,
                        autoHide: true,
                        control: FSelectControl.managed(
                          onChange: (value) {
                            setState(() => _selectedUserType = value);
                          },
                        ),
                        validator: (value) =>
                            value == null ? 'Please select your role' : null,
                        autovalidateMode: AutovalidateMode.disabled,
                        children: [
                          for (final entry in _userTypeLabels.entries)
                            FSelectItem<String>(
                              title: Text(entry.value),
                              value: entry.key,
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FButton(
                          onPress: _isLoading ? null : _handleSignup,
                          child: _isLoading
                              ? const FCircularProgress()
                              : const Text('Sign Up'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: FButton(
                          variant: FButtonVariant.ghost,
                          onPress: () => context.go('/login'),
                          child: const Text('Already a user? Sign In'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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
