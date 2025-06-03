class ApiConfig {
  static const String baseUrl = 'https://api.example.com';
  
  // Auth endpoints
  static const String requestOtp = '/auth/request-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String register = '/auth/register';
  
  // User endpoints
  static const String currentUser = '/users/me';
  static const String updateProfile = '/users/update';
}
