import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class StorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainItemAccessibility.first_unlock_this_device,
    ),
  );

  // Token methods
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secureStorage.write(key: ApiConfig.accessTokenKey, value: accessToken),
      _secureStorage.write(key: ApiConfig.refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: ApiConfig.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: ApiConfig.refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: ApiConfig.accessTokenKey),
      _secureStorage.delete(key: ApiConfig.refreshTokenKey),
    ]);
  }

  // User data methods
  Future<void> saveUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _secureStorage.write(key: ApiConfig.userKey, value: userJson);
  }

  Future<User?> getUser() async {
    final userJson = await _secureStorage.read(key: ApiConfig.userKey);
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      } catch (e) {
        // If parsing fails, clear the stored user data
        await clearUser();
        return null;
      }
    }
    return null;
  }

  Future<void> clearUser() async {
    await _secureStorage.delete(key: ApiConfig.userKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  // Clear all stored data
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }

  // Generic storage methods for other data
  Future<void> write(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<Map<String, String>> readAll() async {
    return await _secureStorage.readAll();
  }

  Future<bool> containsKey(String key) async {
    return await _secureStorage.containsKey(key: key);
  }
}