import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyRole = 'user_role';
  static const String _keyUserId = 'user_id';
  static const String _keyUploadedFcmToken = 'fcm_uploaded_token';

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

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _keyRole);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  // ── FCM Token Persistence (Duplicate Upload Prevention) ───────────────

  Future<void> saveUploadedFcmToken(String token) async {
    await _storage.write(key: _keyUploadedFcmToken, value: token);
  }

  Future<String?> getUploadedFcmToken() async {
    return await _storage.read(key: _keyUploadedFcmToken);
  }

  Future<void> clearUploadedFcmToken() async {
    await _storage.delete(key: _keyUploadedFcmToken);
  }

  Future<void> clearAuthData() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyRole);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUploadedFcmToken);
  }
}
