class User {
  final int id;
  final String? username;
  final String? email;
  final String? fullName;
  final bool isActive;
  final bool isAdmin;
  final bool phoneVerified;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    this.username,
    this.email,
    this.fullName,
    this.isActive = true,
    this.isAdmin = false,
    this.phoneVerified = false,
    this.emailVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'] as int? ?? 0,
        username: json['username'] as String?,
        email: json['email'] as String?,
        fullName: json['full_name'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        isAdmin: json['is_admin'] as bool? ?? false,
        phoneVerified: json['phone_verified'] as bool? ?? false,
        emailVerified: json['email_verified'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null && json['updated_at'] != "null"
            ? DateTime.parse(json['updated_at'].toString())
            : null,
      );
    } catch (e, stackTrace) {
      print('Error parsing User from JSON: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (fullName != null) 'full_name': fullName,
      'is_active': isActive,
      'is_admin': isAdmin,
      'phone_verified': phoneVerified,
      'email_verified': emailVerified,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User? user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class UserRegistration {
  final String username;
  final String email;
  final String password;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;

  UserRegistration({
    required this.username,
    required this.email,
    required this.password,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}
