import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    String? emailError;
    String? passwordError;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      emailError = 'Email is required';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      emailError = 'Enter a valid email';
    }

    if (password.isEmpty) {
      passwordError = 'Password is required';
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    return emailError == null && passwordError == null;
  }

  void _handleLogin() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
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
                AppButton(
                  label: 'Sign In',
                  onPressed: _isLoading ? null : _handleLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                _buildAlternativeLogin(),
                const SizedBox(height: 24),
                _buildSignupLink(context),
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
              child: Icon(
                Icons.palette,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'Sign in to continue',
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
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'Forgot Password?',
              onPressed: () => context.go('/forgot-password'),
              variant: AppButtonVariant.ghost,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeLogin() {
    return Column(
      children: [
        Text(
          'Or continue with',
          style: TextStyle(
            color: AppColors.textGray,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: Icons.g_mobiledata,
              color: AppColors.coral,
              onTap: () {},
            ),
            const SizedBox(width: 16),
            _buildSocialButton(
              icon: Icons.apple,
              color: AppColors.navy,
              onTap: () {},
            ),
            const SizedBox(width: 16),
            _buildSocialButton(
              icon: Icons.facebook,
              color: AppColors.cyan,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildSignupLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: AppColors.textGray,
          ),
        ),
        TextButton(
          onPressed: () => context.go('/signup'),
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: AppColors.coral,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
