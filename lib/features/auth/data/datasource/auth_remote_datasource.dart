import 'package:dio/dio.dart';
import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/models/user_model.dart';
import 'package:riderzz_app/core/models/customer_profile_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<String> sendOtp(String phone) async {
    final response = await _apiClient.post(
      ApiConstants.sendOtp,
      data: {
        'phone': phone,
        'otpType': 'REGISTRATION',
      },
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    return data['message'] ?? 'OTP Sent Successfully';
  }

  Future<UserModel> register({
    required String name,
    required String phone,
    required String password,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.register,
      data: {
        'fullName': name,
        'phone': phone,
        'email': '${phone.trim()}@riderzz.com',
        'password': password,
        'otp': otp,
      },
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    return UserModel.fromJson(data, name: name, phone: phone);
  }

  Future<String> loginSendOtp(String phone) async {
    final response = await _apiClient.post(
      ApiConstants.sendOtp,
      data: {
        'phone': phone,
        'otpType': 'LOGIN',
      },
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    return data['message'] ?? 'OTP Sent Successfully';
  }

  Future<UserModel> loginVerifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.loginVerifyOtp,
      data: {
        'phone': phone,
        'otp': otp,
      },
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    return UserModel.fromJson(data, phone: phone);
  }

  Future<UserModel> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.loginWithPassword,
      data: {
        'phone': phone,
        'password': password,
      },
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    return UserModel.fromJson(data, phone: phone);
  }

  Future<String> forgotPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.forgotPassword,
      data: {
        'phone': phone,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    return data['message'] ?? 'Password updated successfully';
  }

  Future<UserModel> fetchCurrentUser() async {
    final response = await _apiClient.get(ApiConstants.me);
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    return UserModel.fromJson(data);
  }

  Future<UserModel> adminLogin({
    required String phone,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.adminLogin,
      data: {
        'phone': phone,
        'password': password,
      },
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    final nestedData = data['data'] != null && data['data'] is Map
        ? Map<String, dynamic>.from(data['data'] as Map)
        : data;
    return UserModel.fromJson(
      data,
      phone: phone,
      token: nestedData['accessToken'] as String?,
    );
  }

  Future<CustomerProfileModel> getCustomerProfile() async {
    final response = await _apiClient.get(ApiConstants.customerProfileMe);
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    return CustomerProfileModel.fromJson(data);
  }

  Future<CustomerProfileModel> updateCustomerProfile({
    String? dob,
    String? gender,
    String? bio,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.customerProfileUpdate,
      data: {
        if (dob != null) 'dob': dob,
        if (gender != null) 'gender': gender,
        if (bio != null) 'bio': bio,
        if (emergencyContactName != null) 'emergencyContactName': emergencyContactName,
        if (emergencyContactPhone != null) 'emergencyContactPhone': emergencyContactPhone,
      },
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    return CustomerProfileModel.fromJson(data);
  }

  Future<String> uploadProfileImage(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _apiClient.post(
      ApiConstants.uploadProfileImage,
      data: formData,
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    return data['data'] as String;
  }
}
