import 'package:riderzz_app/core/models/user_model.dart';
import 'package:riderzz_app/core/models/customer_profile_model.dart';
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

  Future<UserModel> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    return await _remoteDataSource.loginWithPassword(phone: phone, password: password);
  }

  Future<String> forgotPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    return await _remoteDataSource.forgotPassword(
      phone: phone,
      otp: otp,
      newPassword: newPassword,
    );
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

  Future<CustomerProfileModel> getCustomerProfile() async {
    return await _remoteDataSource.getCustomerProfile();
  }

  Future<CustomerProfileModel> updateCustomerProfile({
    String? dob,
    String? gender,
    String? bio,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    return await _remoteDataSource.updateCustomerProfile(
      dob: dob,
      gender: gender,
      bio: bio,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
    );
  }

  Future<String> uploadProfileImage(String filePath, String fileName) async {
    return await _remoteDataSource.uploadProfileImage(filePath, fileName);
  }
}
