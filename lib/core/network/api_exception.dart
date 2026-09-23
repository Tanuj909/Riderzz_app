import 'dart:convert';
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
    if (data != null) {
      if (data is Map) {
        if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
          message = data['message'].toString().trim();
        } else if (data['error'] != null && data['error'].toString().trim().isNotEmpty) {
          message = data['error'].toString().trim();
        } else if (data['msg'] != null && data['msg'].toString().trim().isNotEmpty) {
          message = data['msg'].toString().trim();
        }
      } else if (data is String && data.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            if (decoded['message'] != null && decoded['message'].toString().trim().isNotEmpty) {
              message = decoded['message'].toString().trim();
            } else if (decoded['error'] != null && decoded['error'].toString().trim().isNotEmpty) {
              message = decoded['error'].toString().trim();
            } else if (decoded['msg'] != null && decoded['msg'].toString().trim().isNotEmpty) {
              message = decoded['msg'].toString().trim();
            }
          } else {
            message = data.trim();
          }
        } catch (_) {
          message = data.trim();
        }
      }
    }

    if (message.isNotEmpty && message != "Something went wrong") {
      return ApiException(message, statusCode: statusCode);
    }

    switch (statusCode) {
      case 400:
        return ApiException('Bad request', statusCode: statusCode);
      case 401:
        return ApiException('Unauthorized', statusCode: statusCode);
      case 403:
        return ApiException('Forbidden', statusCode: statusCode);
      case 404:
        return ApiException('Not found', statusCode: statusCode);
      case 409:
        return ApiException('Conflict', statusCode: statusCode);
      case 422:
        return ApiException('Unprocessable Entity', statusCode: statusCode);
      case 500:
        return ApiException('Internal server error', statusCode: statusCode);
      case 502:
        return ApiException('Bad gateway', statusCode: statusCode);
      case 503:
        return ApiException('Service unavailable', statusCode: statusCode);
      default:
        return ApiException(message, statusCode: statusCode);
    }
  }

  @override
  String toString() => message;
}
