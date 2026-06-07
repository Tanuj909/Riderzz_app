import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyToken = 'auth_token';
  static const String _keyRole = 'user_role';
  static const String _keyUserId = 'user_id';

  Future<void> saveAuthData({
    required String token,
    required String role,
    required int userId,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyRole, value: role);
    await _storage.write(key: _keyUserId, value: userId.toString());
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _keyRole);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  Future<void> clearAuthData() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRole);
    await _storage.delete(key: _keyUserId);
  }
}
