class User {
  final String userId;
  final String username;
  final String role;
  
  User({
    required this.userId,
    required this.username,
    required this.role,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'user',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'role': role,
    };
  }
}