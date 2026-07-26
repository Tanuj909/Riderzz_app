import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:riderzz_app/app/routes/app_routes.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/utils/jwt_helper.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  AuthInterceptor(this._storageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Determine if endpoint needs token. For instance, login/register don't need it.
    final noAuthEndpoints = [
      ApiConstants.loginVerifyOtp,
      ApiConstants.sendOtp,
      ApiConstants.register,
      ApiConstants.registerNoOtp,
      ApiConstants.adminLogin,
    ];

    final isAuthRequired = !noAuthEndpoints.contains(options.path);

    if (isAuthRequired) {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        if (JwtHelper.isTokenExpired(token)) {
          debugPrint('AuthInterceptor: Token is expired on request to ${options.path}. Auto-logging out.');
          await _storageService.clearAuthData();
          
          AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );

          return handler.reject(
            DioException(
              requestOptions: options,
              error: 'Session expired. Please log in again.',
              type: DioExceptionType.cancel,
            ),
          );
        }
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      // TODO: Implement Refresh Token Flow in the future:
      // 1. Call Refresh Token API.
      // 2. If success, save new access token & retry original request.
      // 3. If failure, clear secure storage, logout user, and redirect to login screen.
    }
    return handler.next(err);
  }
}
