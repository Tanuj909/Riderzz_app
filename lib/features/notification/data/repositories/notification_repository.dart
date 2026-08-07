import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/features/notification/data/datasource/notification_remote_datasource.dart';

class NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;
  final SecureStorageService _storageService;

  NotificationRepository(this._remoteDataSource, this._storageService);

  /// Register the FCM device token with the backend.
  ///
  /// Includes duplicate-upload prevention: skips the API call if the
  /// token has already been uploaded successfully.
  ///
  /// Returns `true` if the token was uploaded (or already up-to-date).
  /// Returns `false` on failure — **never throws**.
  Future<bool> registerDeviceToken(String fcmToken) async {
    try {
      // ── Duplicate check ──────────────────────────────────────────────
      final lastUploaded = await _storageService.getUploadedFcmToken();
      if (lastUploaded == fcmToken) {
        debugPrint('[FCM] Skipping upload (token unchanged).');
        return true;
      }

      // ── Detect device type ───────────────────────────────────────────
      final deviceType = Platform.isIOS ? 'IOS' : 'ANDROID';

      // ── Get app version ──────────────────────────────────────────────
      String appVersion = '1.0.0';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = packageInfo.version;
      } catch (_) {
        debugPrint('[FCM] Could not read app version, using default.');
      }

      // ── Upload ───────────────────────────────────────────────────────
      debugPrint('[FCM] Uploading device token...');
      debugPrint('[FCM] Token   : $fcmToken');
      debugPrint('[FCM] Device  : $deviceType');
      debugPrint('[FCM] Version : $appVersion');

      await _remoteDataSource.registerDeviceToken(
        token: fcmToken,
        deviceType: deviceType,
        appVersion: appVersion,
      );

      // ── Persist for duplicate prevention ─────────────────────────────
      await _storageService.saveUploadedFcmToken(fcmToken);
      debugPrint('[FCM] ✅ Device token uploaded successfully.');
      return true;
    } catch (e) {
      debugPrint('[FCM] ❌ Failed to upload device token: $e');
      return false;
    }
  }

  /// Unregister the FCM device token from the backend.
  ///
  /// Returns `true` on success, `false` on failure — **never throws**.
  Future<bool> unregisterDeviceToken(String fcmToken) async {
    try {
      debugPrint('[FCM] Removing device token...');
      await _remoteDataSource.unregisterDeviceToken(fcmToken);
      await _storageService.clearUploadedFcmToken();
      debugPrint('[FCM] ✅ Device token removed successfully.');
      return true;
    } catch (e) {
      debugPrint('[FCM] ❌ Failed to remove device token: $e');
      return false;
    }
  }
}
