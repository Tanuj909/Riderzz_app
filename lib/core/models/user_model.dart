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
    Map<String, dynamic> targetJson = json;
    if (json['data'] != null && json['data'] is Map) {
      targetJson = Map<String, dynamic>.from(json['data'] as Map);
    }

    String? roleStr;
    if (targetJson['role'] != null) {
      roleStr = targetJson['role'] as String;
    } else if (targetJson['roles'] != null) {
      if (targetJson['roles'] is List && (targetJson['roles'] as List).isNotEmpty) {
        roleStr = (targetJson['roles'] as List).first.toString();
      } else if (targetJson['roles'] is String) {
        roleStr = targetJson['roles'] as String;
      }
    }
    roleStr ??= 'CUSTOMER';

    final rawId = targetJson['userId'] ?? targetJson['id'] ?? json['userId'] ?? json['id'];
    int id = 0;
    if (rawId != null) {
      if (rawId is int) {
        id = rawId;
      } else {
        id = int.tryParse(rawId.toString()) ?? 0;
      }
    }

    return UserModel(
      userId: id,
      role: roleStr,
      token: targetJson['token'] as String? ??
          targetJson['accessToken'] as String? ??
          json['token'] as String? ??
          json['accessToken'] as String? ??
          token,
      name: targetJson['name'] as String? ?? json['name'] as String? ?? name,
      phone: targetJson['phone'] as String? ?? json['phone'] as String? ?? phone,
      status: targetJson['status'] as String? ?? json['status'] as String?,
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
