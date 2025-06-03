class User {
  final int id;
  final String username;
  final String email;
  final String phoneNumber;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? profilePictureUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.phoneNumber,
    this.phone,
    this.firstName,
    this.lastName,
    this.profilePictureUrl,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      phone: json['phone'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePictureUrl: json['profile_picture_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'profile_picture_url': profilePictureUrl,
      'created_at': createdAt.toIso8601String(),
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
