import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('====================================');
      debugPrint('➡️ REQUEST[${options.method}] => PATH: ${options.path}');
      debugPrint('Headers: ${options.headers}');
      debugPrint('Query: ${options.queryParameters}');
      if (options.data != null) {
        debugPrint('Body: ${_prettyPrint(options.data)}');
      }
      debugPrint('====================================');
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('====================================');
      debugPrint('⬅️ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      debugPrint('Data: ${_prettyPrint(response.data)}');
      debugPrint('====================================');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('====================================');
      debugPrint('🛑 ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
      debugPrint('Message: ${err.message}');
      debugPrint('Error Data: ${_prettyPrint(err.response?.data)}');
      debugPrint('====================================');
    }
    return handler.next(err);
  }

  String _prettyPrint(dynamic data) {
    if (data == null) return 'null';
    if (data is Map || data is List) {
      try {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(data);
      } catch (e) {
        return data.toString();
      }
    }
    return data.toString();
  }
}
