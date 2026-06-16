class UserModel {
  final int userId;
  final String role;
  final String? token;
  final String? name;
  final String? phone;
  final String? status;

  UserModel({
    required this.userId,
    required this.role,
    this.token,
    this.name,
    this.phone,
    this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? name, String? phone, String? token}) {
    String? roleStr;
    if (json['role'] != null) {
      roleStr = json['role'] as String;
    } else if (json['roles'] != null) {
      if (json['roles'] is List && (json['roles'] as List).isNotEmpty) {
        roleStr = (json['roles'] as List).first.toString();
      } else if (json['roles'] is String) {
        roleStr = json['roles'] as String;
      }
    }
    roleStr ??= 'CUSTOMER';

    return UserModel(
      userId: (json['userId'] ?? json['id']) as int,
      role: roleStr,
      token: json['token'] as String? ?? token,
      name: json['name'] as String? ?? name,
      phone: json['phone'] as String? ?? phone,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'token': token,
      'name': name,
      'phone': phone,
      'status': status,
    };
  }
}
