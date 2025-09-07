import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token; // Reset token from email link
  final String? email; // Email from the reset request

  const ResetPasswordScreen({
    super.key,
    this.token,
    this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _passwordReset = false;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _authService.confirmPasswordReset(
          token: widget.token ?? 'demo_token',
          newPassword: _newPasswordController.text,
          email: widget.email ?? '',
        );

        if (mounted) {
          if (result['success'] == true) {
            setState(() {
              _passwordReset = true;
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password reset successfully!'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );
            
            // Navigate to login after a delay
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to reset password'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleResendCode() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.resetPassword(
        email: widget.email ?? '',
      );

      if (mounted) {
        if (result['success'] == true) {
          // Start cooldown timer
          setState(() {
            _resendCooldown = 60; // 60 seconds cooldown
          });
          
          // Countdown timer
          _startCooldownTimer();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New reset code sent to your email'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to resend code'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startCooldownTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
        return true;
      }
      return false;
    });
  }

  void _navigateToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _passwordReset ? Icons.check_circle_outline : Icons.lock_reset,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    _passwordReset ? 'Password Reset!' : 'Reset Password',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    _passwordReset
                        ? 'Your password has been reset successfully. You can now login with your new password.'
                        : 'Enter your new password below. Make sure it\'s at least 6 characters long.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Password fields (only show if not reset)
                  if (!_passwordReset) ...[
                    // New Password field
                    CustomTextField(
                      controller: _newPasswordController,
                      labelText: 'New Password',
                      hintText: 'Enter new password',
                      obscureText: _obscureNewPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      validator: _validatePassword,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password field
                    CustomTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter new password',
                      obscureText: _obscureConfirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: _validateConfirmPassword,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    CustomButton(
                      text: 'Reset Password',
                      onPressed: _handleResetPassword,
                      isLoading: _isLoading,
                      height: 56,
                    ),
                    const SizedBox(height: 24),

                    // Resend code section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Didn\'t receive the code? ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: (_isLoading || _resendCooldown > 0)
                              ? null
                              : _handleResendCode,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _resendCooldown > 0
                                ? 'Resend in ${_resendCooldown}s'
                                : 'Resend Code',
                            style: TextStyle(
                              color: (_resendCooldown > 0)
                                  ? AppColors.textDisabled
                                  : AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Success state - Return to login button
                  if (_passwordReset) ...[
                    CustomButton(
                      text: 'Go to Login',
                      onPressed: _navigateToLogin,
                      height: 56,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Back to login link (only show if not reset)
                  if (!_passwordReset)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Remember your password? ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _navigateToLogin,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}