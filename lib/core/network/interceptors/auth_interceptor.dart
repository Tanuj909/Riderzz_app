import 'package:dio/dio.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/core/network/api_constants.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  AuthInterceptor(this._storageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Determine if endpoint needs token. For instance, login/register don't need it.
    final noAuthEndpoints = [
      ApiConstants.loginSendOtp,
      ApiConstants.loginVerifyOtp,
      ApiConstants.sendOtp,
      ApiConstants.register,
    ];

    final isAuthRequired = !noAuthEndpoints.contains(options.path);

    if (isAuthRequired) {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }
}
