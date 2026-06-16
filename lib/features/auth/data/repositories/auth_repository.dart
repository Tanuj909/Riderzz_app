import 'package:riderzz_app/core/models/user_model.dart';
import 'package:riderzz_app/features/auth/data/datasource/auth_remote_datasource.dart';

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepository(this._remoteDataSource);

  Future<String> sendOtp(String phone) async {
    return await _remoteDataSource.sendOtp(phone);
  }

  Future<UserModel> register({
    required String name,
    required String phone,
    required String password,
    required String otp,
  }) async {
    return await _remoteDataSource.register(
      name: name,
      phone: phone,
      password: password,
      otp: otp,
    );
  }

  Future<String> loginSendOtp(String phone) async {
    return await _remoteDataSource.loginSendOtp(phone);
  }

  Future<UserModel> loginVerifyOtp({
    required String phone,
    required String otp,
  }) async {
    return await _remoteDataSource.loginVerifyOtp(phone: phone, otp: otp);
  }

  Future<UserModel> fetchCurrentUser() async {
    return await _remoteDataSource.fetchCurrentUser();
  }

  Future<UserModel> adminLogin({
    required String phone,
    required String password,
  }) async {
    return await _remoteDataSource.adminLogin(phone: phone, password: password);
  }
}
