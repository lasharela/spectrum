import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/api/api_exceptions.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

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
    return FScaffold(
      header: FHeader.nested(
        title: const Text('Sign In'),
        prefixes: [
          FHeaderAction.back(onPress: () => context.go('/onboarding')),
        ],
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
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
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.disabled,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FButton(
                  variant: FButtonVariant.ghost,
                  onPress: () => context.go('/forgot-password'),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FButton(
                  onPress: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const FCircularProgress()
                      : const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: FButton(
                  variant: FButtonVariant.ghost,
                  onPress: () => context.go('/signup'),
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
