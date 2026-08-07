import 'package:flutter/foundation.dart';
import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';

class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSource(this._apiClient);

  /// Register FCM device token with the backend.
  ///
  /// POST /api/notifications/device-token
  Future<void> registerDeviceToken({
    required String token,
    required String deviceType,
    required String appVersion,
  }) async {
    await _apiClient.post(
      ApiConstants.registerDeviceToken,
      data: {
        'token': token,
        'deviceType': deviceType,
        'appVersion': appVersion,
      },
    );
    debugPrint('[FCM] ✅ Device token registered via API.');
  }

  /// Unregister FCM device token from the backend.
  ///
  /// DELETE /api/notifications/device-token?token=<token>
  Future<void> unregisterDeviceToken(String token) async {
    await _apiClient.delete(
      ApiConstants.unregisterDeviceToken,
      queryParameters: {'token': token},
    );
    debugPrint('[FCM] ✅ Device token unregistered via API.');
  }
}
