class ApiConfig {
  static const String baseUrl = 'https://ledboard.forcempower.com:8443/api/v1';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String requestOtp = '/auth/request-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh-token';
}
