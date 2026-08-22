import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:riderzz_app/app/routes/app_routes.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/utils/jwt_helper.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  // Shared future to prevent concurrent refresh token API calls
  static Future<String?>? _refreshTokenFuture;

  AuthInterceptor(this._storageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final noAuthEndpoints = [
      ApiConstants.loginVerifyOtp,
      ApiConstants.sendOtp,
      ApiConstants.register,
      ApiConstants.registerNoOtp,
      ApiConstants.adminLogin,
      ApiConstants.loginWithPassword,
      ApiConstants.refreshToken,
    ];

    final isAuthRequired = !noAuthEndpoints.contains(options.path);

    if (isAuthRequired) {
      String? token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        if (JwtHelper.isTokenExpired(token)) {
          debugPrint('AuthInterceptor: Access token is expired locally. Attempting refresh.');
          try {
            final newToken = await _refreshAccessToken();
            if (newToken != null && newToken.isNotEmpty) {
              token = newToken;
            } else {
              debugPrint('AuthInterceptor: Refresh failed locally. Logging out.');
              await _handleLogout();
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Session expired. Please log in again.',
                  type: DioExceptionType.cancel,
                ),
              );
            }
          } catch (e) {
            debugPrint('AuthInterceptor: Error refreshing token locally: $e. Logging out.');
            await _handleLogout();
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Session expired. Please log in again.',
                type: DioExceptionType.cancel,
              ),
            );
          }
        }
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    final noAuthEndpoints = [
      ApiConstants.loginVerifyOtp,
      ApiConstants.sendOtp,
      ApiConstants.register,
      ApiConstants.registerNoOtp,
      ApiConstants.adminLogin,
      ApiConstants.loginWithPassword,
      ApiConstants.refreshToken,
    ];

    final isAuthRequired = !noAuthEndpoints.contains(err.requestOptions.path);

    if ((statusCode == 401 || statusCode == 403) &&
        isAuthRequired &&
        err.requestOptions.extra['isRetry'] != true) {
      
      err.requestOptions.extra['isRetry'] = true;
      debugPrint('AuthInterceptor: Received 401/403 for protected endpoint ${err.requestOptions.path}. Retrying after token refresh.');

      try {
        final newToken = await _refreshAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';

          final retryDio = Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: options.connectTimeout,
              receiveTimeout: options.receiveTimeout,
              sendTimeout: options.sendTimeout,
            ),
          );

          final response = await retryDio.request(
            options.path,
            data: options.data,
            queryParameters: options.queryParameters,
            options: Options(
              method: options.method,
              headers: options.headers,
              contentType: options.contentType,
              extra: options.extra,
            ),
          );

          return handler.resolve(response);
        } else {
          debugPrint('AuthInterceptor: Refresh failed on 401. Logging out.');
          await _handleLogout();
          return handler.next(err);
        }
      } catch (e) {
        debugPrint('AuthInterceptor: Error during retry flow: $e');
        await _handleLogout();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  Future<String?> _refreshAccessToken() async {
    if (_refreshTokenFuture != null) {
      debugPrint('AuthInterceptor: A refresh operation is already in progress. Waiting for it to complete.');
      return _refreshTokenFuture;
    }

    _refreshTokenFuture = () async {
      try {
        final refreshToken = await _storageService.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          debugPrint('AuthInterceptor: No refresh token stored. Cannot refresh.');
          return null;
        }

        debugPrint('AuthInterceptor: Requesting token refresh from backend.');
        final refreshDio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        final response = await refreshDio.post(
          ApiConstants.refreshToken,
          data: {'refreshToken': refreshToken},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final resData = response.data;
          final data = resData['data'];
          if (data != null) {
            final newAccessToken = data['accessToken'] as String?;
            final newRefreshToken = data['refreshToken'] as String?;
            
            final existingRole = await _storageService.getRole();
            final existingUserIdStr = await _storageService.getUserId();
            final existingUserId = int.tryParse(existingUserIdStr ?? '') ?? 0;

            final role = data['role']?.toString() ?? existingRole ?? 'CUSTOMER';
            
            final rawUserId = data['userId'];
            int userId = existingUserId;
            if (rawUserId != null) {
              if (rawUserId is int) {
                userId = rawUserId;
              } else {
                userId = int.tryParse(rawUserId.toString()) ?? existingUserId;
              }
            }

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              debugPrint('AuthInterceptor: Token refresh succeeded.');
              await _storageService.saveAuthData(
                token: newAccessToken,
                refreshToken: newRefreshToken ?? refreshToken,
                role: role,
                userId: userId,
              );
              return newAccessToken;
            }
          }
        }
        return null;
      } catch (e) {
        debugPrint('AuthInterceptor: Token refresh API error: $e');
        return null;
      } finally {
        _refreshTokenFuture = null;
      }
    }();

    return _refreshTokenFuture;
  }

  Future<void> _handleLogout() async {
    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {}

    await _storageService.clearAuthData();

    AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}
