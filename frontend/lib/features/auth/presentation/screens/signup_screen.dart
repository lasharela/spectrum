import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/api/api_exceptions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _userTypeError;
  String? _selectedUserType;

  final List<Map<String, dynamic>> _userTypes = [
    {
      'value': 'autistic_individual',
      'label': 'Person with Autism',
      'icon': Icons.accessibility_new,
    },
    {
      'value': 'parent',
      'label': 'Parent/Caregiver',
      'icon': Icons.family_restroom,
    },
    {
      'value': 'professional',
      'label': 'Professional',
      'icon': Icons.medical_services,
    },
    {
      'value': 'educator',
      'label': 'Educator',
      'icon': Icons.school,
    },
    {
      'value': 'therapist',
      'label': 'Therapist',
      'icon': Icons.psychology,
    },
    {
      'value': 'supporter',
      'label': 'Supporter',
      'icon': Icons.volunteer_activism,
    },
  ];

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

  bool _validate() {
    String? firstNameError;
    String? lastNameError;
    String? emailError;
    String? passwordError;
    String? confirmPasswordError;
    String? userTypeError;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (firstName.isEmpty) {
      firstNameError = 'First name is required';
    } else if (firstName.length < 2) {
      firstNameError = 'Must be at least 2 characters';
    }

    if (lastName.isEmpty) {
      lastNameError = 'Last name is required';
    } else if (lastName.length < 2) {
      lastNameError = 'Must be at least 2 characters';
    }

    if (email.isEmpty) {
      emailError = 'Email is required';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      emailError = 'Enter a valid email';
    }

    if (password.isEmpty) {
      passwordError = 'Password is required';
    } else if (password.length < 8) {
      passwordError = 'Password must be at least 8 characters';
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      passwordError = 'Password must contain an uppercase letter';
    } else if (!RegExp(r'[a-z]').hasMatch(password)) {
      passwordError = 'Password must contain a lowercase letter';
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      passwordError = 'Password must contain a number';
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordError = 'Please confirm your password';
    } else if (confirmPassword != password) {
      confirmPasswordError = 'Passwords do not match';
    }

    if (_selectedUserType == null) {
      userTypeError = 'Please select your user type';
    }

    setState(() {
      _firstNameError = firstNameError;
      _lastNameError = lastNameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
      _userTypeError = userTypeError;
    });

    return firstNameError == null &&
        lastNameError == null &&
        emailError == null &&
        passwordError == null &&
        confirmPasswordError == null &&
        userTypeError == null;
  }

  void _handleSignup() async {
    if (!_validate()) return;

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                IconButton(
                  onPressed: () => context.go('/onboarding'),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildHeader(context),
                const SizedBox(height: 40),
                _buildForm(),
                const SizedBox(height: 24),
                _buildUserTypeSelector(),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Sign Up',
                  onPressed: _isLoading ? null : _handleSignup,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                _buildSignInLink(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_add,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  'Join the Spectrum community',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'First Name',
            hint: 'Enter your first name',
            controller: _firstNameController,
            keyboardType: TextInputType.name,
            error: _firstNameError != null ? Text(_firstNameError!) : null,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Middle Name (optional)',
            hint: 'Enter your middle name',
            controller: _middleNameController,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Last Name',
            hint: 'Enter your last name',
            controller: _lastNameController,
            keyboardType: TextInputType.name,
            error: _lastNameError != null ? Text(_lastNameError!) : null,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Email',
            hint: 'Enter your email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            error: _emailError != null ? Text(_emailError!) : null,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: _passwordController,
            isPassword: true,
            error: _passwordError != null ? Text(_passwordError!) : null,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            controller: _confirmPasswordController,
            isPassword: true,
            error: _confirmPasswordError != null
                ? Text(_confirmPasswordError!)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a...',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _userTypes.map((type) {
            final isSelected = _selectedUserType == type['value'];
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type['icon'] as IconData,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(type['label'] as String),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedUserType =
                      selected ? type['value'] as String : null;
                  _userTypeError = null;
                });
              },
            );
          }).toList(),
        ),
        if (_userTypeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _userTypeError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSignInLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        AppButton(
          label: 'Sign In',
          onPressed: () => context.go('/login'),
          variant: AppButtonVariant.ghost,
        ),
      ],
    );
  }
}
