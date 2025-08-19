class User {
  final int id;
  final String phoneNumber;
  final String? username;
  final String? email;
  final String? fullName;
  final bool isActive;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.phoneNumber,
    this.username,
    this.email,
    this.fullName,
    required this.isActive,
    required this.isAdmin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      phoneNumber: json['phone_number'] as String,
      username: json['username'] as String?,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      isActive: json['is_active'] as bool,
      isAdmin: json['is_admin'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'username': username,
      'email': email,
      'full_name': fullName,
      'is_active': isActive,
      'is_admin': isAdmin,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
