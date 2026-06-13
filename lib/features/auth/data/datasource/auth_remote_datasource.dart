import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<String> sendOtp(String phone) async {
    final response = await _apiClient.post(
      ApiConstants.sendOtp,
      data: {'phone': phone},
    );
    return response.data?.toString() ?? 'OTP Sent Successfully';
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
      ApiConstants.loginSendOtp,
      data: {'phone': phone},
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

  Future<UserModel> fetchCurrentUser() async {
    final response = await _apiClient.get(ApiConstants.me);
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    return UserModel.fromJson(data);
  }
}
