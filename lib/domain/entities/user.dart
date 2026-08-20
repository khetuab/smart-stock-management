class UserEntity {
  final String id;
  final String username;
  final String password;
  final String createdAt;

  UserEntity({
    this.id = '',
    required this.username,
    required this.password,
    this.createdAt = '',
  });
}