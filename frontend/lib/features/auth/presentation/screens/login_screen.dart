import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleLogin() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signIn(
        email: values['email'] as String,
        password: values['password'] as String,
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
                _buildForm(context),
                const SizedBox(height: 24),
                _buildLoginButton(context),
                const SizedBox(height: 24),
                _buildAlternativeLogin(context),
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

  Widget _buildForm(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'email',
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(color: AppColors.textGray.withValues(alpha: 0.5)),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.cyan,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cyan, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                Text(
                  'Password',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'password',
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: AppColors.textGray.withValues(alpha: 0.5)),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.coral,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textGray,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.coral, width: 2),
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Sign In',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildAlternativeLogin(BuildContext context) {
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