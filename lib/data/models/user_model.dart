class User {
  final String id;
  final String username;
  final String password;
  final String createdAt;
  final String? email;
  final String? fullName;
  final String? phone;
  final bool isActive;

  User({
    this.id = '',
    required this.username,
    required this.password,
    this.createdAt = '',
    this.email,
    this.fullName,
    this.phone,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      email: map['email'],
      fullName: map['fullName'],
      phone: map['phone'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] ?? '',
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? password,
    String? email,
    String? fullName,
    String? phone,
    bool? isActive,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}