import 'dart:io';
import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.cancel:
        return ApiException("Request to API server was cancelled");
      case DioExceptionType.connectionTimeout:
        return ApiException("Connection timeout with API server");
      case DioExceptionType.receiveTimeout:
        return ApiException("Receive timeout in connection with API server");
      case DioExceptionType.sendTimeout:
        return ApiException("Send timeout in connection with API server");
      case DioExceptionType.connectionError:
        if (dioError.error is SocketException) {
          return ApiException("No Internet connection");
        }
        return ApiException("Connection error with API server");
      case DioExceptionType.badCertificate:
        return ApiException("Bad certificate");
      case DioExceptionType.badResponse:
        return ApiException._handleError(
          dioError.response?.statusCode,
          dioError.response?.data,
        );
      case DioExceptionType.unknown:
        if (dioError.error is SocketException) {
          return ApiException("No Internet connection");
        }
        return ApiException("Unexpected error occurred");
    }
  }

  static ApiException _handleError(int? statusCode, dynamic data) {
    String message = "Something went wrong";
    if (data != null && data is Map<String, dynamic> && data['message'] != null) {
      message = data['message'];
    }

    switch (statusCode) {
      case 400:
        return ApiException(message.isNotEmpty ? message : 'Bad request', statusCode: statusCode);
      case 401:
        return ApiException(message.isNotEmpty ? message : 'Unauthorized', statusCode: statusCode);
      case 403:
        return ApiException(message.isNotEmpty ? message : 'Forbidden', statusCode: statusCode);
      case 404:
        return ApiException(message.isNotEmpty ? message : 'Not found', statusCode: statusCode);
      case 409:
        return ApiException(message.isNotEmpty ? message : 'Conflict', statusCode: statusCode);
      case 422:
        return ApiException(message.isNotEmpty ? message : 'Unprocessable Entity', statusCode: statusCode);
      case 500:
        return ApiException(
          (message.isNotEmpty && message != "Something went wrong")
              ? message
              : 'Internal server error',
          statusCode: statusCode,
        );
      case 502:
        return ApiException(
          (message.isNotEmpty && message != "Something went wrong")
              ? message
              : 'Bad gateway',
          statusCode: statusCode,
        );
      case 503:
        return ApiException(
          (message.isNotEmpty && message != "Something went wrong")
              ? message
              : 'Service unavailable',
          statusCode: statusCode,
        );
      default:
        return ApiException(message, statusCode: statusCode);
    }
  }

  @override
  String toString() => message;
}
