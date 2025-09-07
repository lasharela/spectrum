import 'dart:async';
import 'dart:convert';
// Uncomment the following line when you're ready to use real HTTP calls
// import 'package:http/http.dart' as http;

/// Authentication service for handling user login and signup
class AuthService {
  static final AuthService _instance = AuthService._internal();
  
  // Base URL for your API - update this with your actual API URL
  static const String baseUrl = 'https://your-api-url.com/api';
  
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal();
  
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _authToken;
  
  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get authToken => _authToken;
  
  /// Signup method that sends data to /signup endpoint
  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
  }) async {
    try {
      // Uncomment this block when you have a real API endpoint
      /*
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isAuthenticated = true;
        _userEmail = email;
        _authToken = responseData['token'];
        
        return {
          'success': true,
          'message': responseData['message'] ?? 'Signup successful',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 
                     responseData['message'] ?? 
                     'Signup failed',
        };
      }
      */
      
      // Mock implementation for testing
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful signup
      if (email.isNotEmpty && password.length >= 8) {
        _isAuthenticated = true;
        _userEmail = email;
        _authToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
        
        return {
          'success': true,
          'message': 'Account created successfully',
          'data': {
            'email': email,
            'token': _authToken,
          },
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid email or password',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
  
  /// Login method
  Future<bool> login(String email, String password) async {
    try {
      // Uncomment this block when you have a real API endpoint
      /*
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _isAuthenticated = true;
        _userEmail = email;
        _authToken = responseData['token'];
        return true;
      }
      return false;
      */
      
      // Mock implementation for testing
      await Future.delayed(const Duration(seconds: 1));
      
      if (email.isNotEmpty && password.length >= 6) {
        _isAuthenticated = true;
        _userEmail = email;
        _authToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
        return true;
      }
      
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
  
  /// Logout method
  Future<void> logout() async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    _isAuthenticated = false;
    _userEmail = null;
    _authToken = null;
  }
  
  /// Check if user session is valid
  Future<bool> checkSession() async {
    // Simulate checking stored session
    await Future.delayed(const Duration(milliseconds: 500));
    
    // For demo, session is valid if authenticated
    return _isAuthenticated && _authToken != null;
  }
  
  /// Reset password method
  Future<Map<String, dynamic>> resetPassword({
    required String email,
  }) async {
    try {
      // Uncomment this block when you have a real API endpoint
      /*
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Reset instructions sent',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 
                     responseData['message'] ?? 
                     'Failed to send reset instructions',
        };
      }
      */
      
      // Mock implementation for testing
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful password reset email
      if (email.isNotEmpty && email.contains('@')) {
        return {
          'success': true,
          'message': 'Password reset instructions sent to $email',
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid email address',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
  
  /// Confirm password reset with new password
  Future<Map<String, dynamic>> confirmPasswordReset({
    required String token,
    required String newPassword,
    required String email,
  }) async {
    try {
      // Uncomment this block when you have a real API endpoint
      /*
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'password': newPassword,
          'email': email,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 
                     responseData['message'] ?? 
                     'Failed to reset password',
        };
      }
      */
      
      // Mock implementation for testing
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful password reset
      if (token.isNotEmpty && newPassword.length >= 6) {
        return {
          'success': true,
          'message': 'Password has been reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid token or password',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}