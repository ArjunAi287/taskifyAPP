import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Abstracted storage keys
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  // Save tokens
  static Future<void> storeTokens(String accessToken, String refreshToken) async {
    print("StorageService: Storing tokens...");
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      print("StorageService: Web storage complete. Key set: ${prefs.containsKey(_accessTokenKey)}");
    } else {
      const storage = FlutterSecureStorage();
      await storage.write(key: _accessTokenKey, value: accessToken);
      await storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  // Get Access Token
  static Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } else {
      const storage = FlutterSecureStorage();
      return await storage.read(key: _accessTokenKey);
    }
  }

  // Get Refresh Token
  static Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } else {
      const storage = FlutterSecureStorage();
      return await storage.read(key: _refreshTokenKey);
    }
  }

  // Clear tokens (Logout)
  static Future<void> clearTokens() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
    } else {
      const storage = FlutterSecureStorage();
      await storage.delete(key: _accessTokenKey);
      await storage.delete(key: _refreshTokenKey);
    }
  }
}
