class AuthModel {
  final String access;
  final String refresh;
  final int id;
  final String username;
  final String name;
  final String email;

  const AuthModel({
    required this.access,
    required this.refresh,
    required this.id,
    required this.username,
    required this.name,
    required this.email,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      id: json['id'] as int,
      username: json['username'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}
