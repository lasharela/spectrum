/// Placeholder authentication service
/// In production, this would connect to a real authentication backend
class AuthService {
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal();
  
  bool _isAuthenticated = false;
  String? _userEmail;
  
  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  
  /// Simulates user login
  /// Returns true if login successful, false otherwise
  Future<bool> login(String email, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));
    
    // For demo purposes, accept any valid email format
    // In production, this would validate against a backend
    if (email.isNotEmpty && password.length >= 6) {
      _isAuthenticated = true;
      _userEmail = email;
      return true;
    }
    
    return false;
  }
  
  /// Simulates user logout
  Future<void> logout() async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    _isAuthenticated = false;
    _userEmail = null;
  }
  
  /// Check if user session is valid
  Future<bool> checkSession() async {
    // Simulate checking stored session
    await Future.delayed(const Duration(milliseconds: 500));
    
    // For demo, session is valid if authenticated
    return _isAuthenticated;
  }
}