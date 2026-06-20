import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<String> sendOtp(String phone) async {
    final response = await _apiClient.post(
      ApiConstants.sendOtp,
      data: {
        'destination': phone,
        'type': 'MOBILE',
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
        'name': name,
        'phone': phone,
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
        'destination': phone,
        'type': 'MOBILE',
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
        'destination': phone,
        'otp': otp,
        'type': 'MOBILE',
      },
    );
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    return UserModel.fromJson(data, phone: phone);
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
}
