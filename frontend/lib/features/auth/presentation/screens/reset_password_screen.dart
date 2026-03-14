import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;
  final String email;

  const ResetPasswordScreen({
    required this.token,
    required this.email,
    super.key,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isReset = false;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    String? passwordError;
    String? confirmError;

    if (password.length < 8) {
      passwordError = 'Password must be at least 8 characters';
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      passwordError = 'Password must contain an uppercase letter';
    } else if (!RegExp(r'[a-z]').hasMatch(password)) {
      passwordError = 'Password must contain a lowercase letter';
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      passwordError = 'Password must contain a number';
    }

    if (confirm != password) {
      confirmError = 'Passwords do not match';
    }

    setState(() {
      _passwordError = passwordError;
      _confirmPasswordError = confirmError;
    });

    return passwordError == null && confirmError == null;
  }

  void _handleReset() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.resetPassword(
        token: widget.token,
        newPassword: _passwordController.text,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isReset = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset password: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Screen(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isReset
                ? _buildSuccessState(context)
                : _buildFormState(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Reset Your Password',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Create a new password for ${widget.email}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        AppTextField(
          label: 'New Password',
          controller: _passwordController,
          isPassword: true,
          error: _passwordError != null ? Text(_passwordError!) : null,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          isPassword: true,
          error:
              _confirmPasswordError != null ? Text(_confirmPasswordError!) : null,
        ),
        const SizedBox(height: 8),
        Text(
          '8+ characters, uppercase, lowercase, number',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Reset Password',
          onPressed: _isLoading ? null : _handleReset,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Back to Login',
          onPressed: () => context.go('/login'),
          variant: AppButtonVariant.ghost,
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0x1A4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 40,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Password Reset!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your password has been successfully reset',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        AppButton(
          label: 'Go to Login',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
