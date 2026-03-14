import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _nameError;
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    String? nameError;
    String? emailError;
    String? passwordError;
    String? confirmPasswordError;
    String? userTypeError;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Name validation
    if (name.isEmpty) {
      nameError = 'Name is required';
    } else if (name.length < 2) {
      nameError = 'Name must be at least 2 characters';
    }

    // Email validation
    if (email.isEmpty) {
      emailError = 'Email is required';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      emailError = 'Enter a valid email';
    }

    // Password validation
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

    // Confirm password validation
    if (confirmPassword.isEmpty) {
      confirmPasswordError = 'Please confirm your password';
    } else if (confirmPassword != password) {
      confirmPasswordError = 'Passwords do not match';
    }

    // User type validation
    if (_selectedUserType == null) {
      userTypeError = 'Please select your user type';
    }

    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
      _userTypeError = userTypeError;
    });

    return nameError == null &&
        emailError == null &&
        passwordError == null &&
        confirmPasswordError == null &&
        userTypeError == null;
  }

  void _handleSignup() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            userType: _selectedUserType!,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
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
                      color: AppColors.textDark,
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
                gradient: LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                        color: AppColors.textDark,
                      ),
                ),
                Text(
                  'Join the Spectrum community',
                  style: TextStyle(
                    color: AppColors.textGray,
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
            label: 'Full Name',
            hint: 'Enter your full name',
            controller: _nameController,
            keyboardType: TextInputType.name,
            error: _nameError != null ? Text(_nameError!) : null,
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
                color: AppColors.textDark,
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
            color: AppColors.textGray,
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
