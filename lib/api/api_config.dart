class ApiConfig {
  static const String baseUrl = 'http://ledboard.forcempower.com:8000/api/v1';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String requestOtp = '/auth/request-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String completeRegistration = '/auth/register/complete';
  static const String refreshToken = '/auth/refresh-token';

  // User endpoints
  static const String currentUser = '/users/me';
  static const String updateProfile = '/users/me/profile';

  // Dashboard endpoints
  static const String dashboard = '/dashboard';

  // Practice endpoints
  static const String drills = '/drills';
  static const String drillGroups = '/drill-groups';
  static const String practiceSession = '/practice/sessions';

  // Challenge endpoints
  static const String challenges = '/challenge';
  static const String acceptChallenge = '/challenge/{id}/accept';
}
