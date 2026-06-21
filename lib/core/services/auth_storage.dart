import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _keyAccess = 'auth_access_token';
  static const _keyRefresh = 'auth_refresh_token';
  static const _keyId = 'auth_id';
  static const _keyUsername = 'auth_username';
  static const _keyName = 'auth_name';
  static const _keyEmail = 'auth_email';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void> saveAuth({
    required String access,
    required String refresh,
    required int id,
    required String username,
    required String name,
    required String email,
  }) async {
    await _storage.write(key: _keyAccess, value: access);
    await _storage.write(key: _keyRefresh, value: refresh);
    await _storage.write(key: _keyId, value: id.toString());
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyName, value: name);
    await _storage.write(key: _keyEmail, value: email);
  }

  static Future<Map<String, dynamic>?> loadAuth() async {
    final access = await _storage.read(key: _keyAccess);
    if (access == null || access.isEmpty) return null;

    return {
      'access': access,
      'refresh': await _storage.read(key: _keyRefresh) ?? '',
      'id': int.tryParse(await _storage.read(key: _keyId) ?? '') ?? 0,
      'username': await _storage.read(key: _keyUsername) ?? '',
      'name': await _storage.read(key: _keyName) ?? '',
      'email': await _storage.read(key: _keyEmail) ?? '',
    };
  }

  static Future<void> clearAuth() async {
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
    await _storage.delete(key: _keyId);
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyName);
    await _storage.delete(key: _keyEmail);
  }

  static Future<String?> getAccessToken() {
    return _storage.read(key: _keyAccess);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
