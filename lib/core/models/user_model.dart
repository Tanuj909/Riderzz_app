class UserModel {
  final int userId;
  final String role;
  final String token;
  final String? name;
  final String? phone;

  UserModel({
    required this.userId,
    required this.role,
    required this.token,
    this.name,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? name, String? phone}) {
    return UserModel(
      userId: json['userId'] as int,
      role: json['role'] as String,
      token: json['token'] as String,
      name: name,
      phone: phone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'token': token,
      'name': name,
      'phone': phone,
    };
  }
}
