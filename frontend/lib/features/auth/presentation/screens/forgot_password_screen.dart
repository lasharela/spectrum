import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    String? emailError;

    if (email.isEmpty) {
      emailError = 'Email is required';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      emailError = 'Enter a valid email';
    }

    setState(() {
      _emailError = emailError;
    });

    return emailError == null;
  }

  void _handleSendReset() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.forgotPassword(email: _emailController.text.trim());
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: ${e.toString()}')),
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
            child: _emailSent ? _buildSuccessState(context) : _buildFormState(context),
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
          'Forgot Password?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          "Enter your email and we'll send you a reset link",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        AppTextField(
          label: 'Email',
          hint: 'Enter your email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          error: _emailError != null ? Text(_emailError!) : null,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Send Reset Instructions',
          onPressed: _isLoading ? null : _handleSendReset,
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
    final email = _emailController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Check Your Email',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          "We've sent password reset instructions to $email",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        AppButton(
          label: 'Return to Login',
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Try another email',
          onPressed: () => setState(() => _emailSent = false),
          variant: AppButtonVariant.ghost,
        ),
      ],
    );
  }
}
