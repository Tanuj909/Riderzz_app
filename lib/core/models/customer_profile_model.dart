class CustomerProfileModel {
  final int userId;
  final String fullName;
  final String phone;
  final String email;
  final String? profileImage;
  final String role;
  final double rating;
  final int totalBookings;
  final String? gender;
  final String? dob;
  final String? bio;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  CustomerProfileModel({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.email,
    this.profileImage,
    required this.role,
    required this.rating,
    required this.totalBookings,
    this.gender,
    this.dob,
    this.bio,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> targetJson = json;
    if (json['data'] != null && json['data'] is Map) {
      targetJson = Map<String, dynamic>.from(json['data'] as Map);
    }

    double ratingVal = 0.0;
    if (targetJson['rating'] != null) {
      ratingVal = double.tryParse(targetJson['rating'].toString()) ?? 0.0;
    }

    return CustomerProfileModel(
      userId: targetJson['userId'] as int? ?? targetJson['id'] as int? ?? 0,
      fullName: targetJson['fullName'] as String? ?? targetJson['name'] as String? ?? '',
      phone: targetJson['phone'] as String? ?? '',
      email: targetJson['email'] as String? ?? '',
      profileImage: targetJson['profileImage'] as String?,
      role: targetJson['role'] as String? ?? 'CUSTOMER',
      rating: ratingVal,
      totalBookings: targetJson['totalBookings'] as int? ?? 0,
      gender: targetJson['gender'] as String?,
      dob: targetJson['dob'] as String?,
      bio: targetJson['bio'] as String?,
      emergencyContactName: targetJson['emergencyContactName'] as String?,
      emergencyContactPhone: targetJson['emergencyContactPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'profileImage': profileImage,
      'role': role,
      'rating': rating,
      'totalBookings': totalBookings,
      'gender': gender,
      'dob': dob,
      'bio': bio,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }
}
