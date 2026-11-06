import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
  );

  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyRole = 'user_role';
  static const String _keyUserId = 'user_id';
  static const String _keyUploadedFcmToken = 'fcm_uploaded_token';

  Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('[SecureStorage] Error reading key $key (resetting): $e');
      try {
        await _storage.delete(key: key);
      } catch (_) {}
      return null;
    }
  }

  Future<void> saveAuthData({
    required String token,
    String? refreshToken,
    required String role,
    required int userId,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
    await _storage.write(key: _keyRole, value: role);
    await _storage.write(key: _keyUserId, value: userId.toString());
  }

  Future<String?> getToken() async => _safeRead(_keyToken);

  Future<String?> getRefreshToken() async => _safeRead(_keyRefreshToken);

  Future<String?> getRole() async => _safeRead(_keyRole);

  Future<String?> getUserId() async => _safeRead(_keyUserId);

  // ── FCM Token Persistence (Duplicate Upload Prevention) ───────────────

  Future<void> saveUploadedFcmToken(String token) async {
    try {
      await _storage.write(key: _keyUploadedFcmToken, value: token);
    } catch (e) {
      debugPrint('[SecureStorage] Error saving FCM token: $e');
    }
  }

  Future<String?> getUploadedFcmToken() async => _safeRead(_keyUploadedFcmToken);

  Future<void> clearUploadedFcmToken() async {
    try {
      await _storage.delete(key: _keyUploadedFcmToken);
    } catch (_) {}
  }

  Future<void> clearAuthData() async {
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyRole);
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyUploadedFcmToken);
    } catch (e) {
      debugPrint('[SecureStorage] Error clearing auth data: $e');
    }
  }
}
