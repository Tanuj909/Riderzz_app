import 'package:dio/dio.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/network/api_exception.dart';
import 'package:riderzz_app/core/network/interceptors/auth_interceptor.dart';
import 'package:riderzz_app/core/network/interceptors/logger_interceptor.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({required SecureStorageService storageService}) {
    _dio = Dio(
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

    _dio.interceptors.addAll([
      AuthInterceptor(storageService),
      LoggerInterceptor(),
    ]);
  }

  /// GET request
  Future<Response> get(String url, {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.get(url, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException("Unexpected error occurred");
    }
  }

  /// POST request
  Future<Response> post(String url, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.post(url, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException("Unexpected error occurred");
    }
  }

  /// PUT request
  Future<Response> put(String url, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.put(url, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException("Unexpected error occurred");
    }
  }

  /// PATCH request
  Future<Response> patch(String url, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.patch(url, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException("Unexpected error occurred");
    }
  }

  /// DELETE request
  Future<Response> delete(String url, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.delete(url, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException("Unexpected error occurred");
    }
  }
}
