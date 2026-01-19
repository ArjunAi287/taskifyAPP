import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  final ApiService _apiService = ApiService();

  AuthStatus get status => _status;
  User? get user => _user;

  Future<void> initAuth() async {
    print("AuthProvider: initAuth called");
    final token = await StorageService.getAccessToken();
    print("AuthProvider: Token from storage: $token");
    
    if (token != null) {
      try {
        // Validation: Get current user
        print("AuthProvider: Validating token with /auth/me");
        final response = await _apiService.dio.get('/auth/me');
        print("AuthProvider: /auth/me success: ${response.data}");
        _user = User.fromJson(response.data);
        _status = AuthStatus.authenticated;
      } catch (e) {
        print("AuthProvider: /auth/me failed: $e");
        // Token invalid or expired
        await StorageService.clearTokens();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      print("AuthProvider: No token found");
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    print("AuthProvider: Attempting login for $email");
    try {
      final response = await _apiService.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      print("AuthProvider: Login API success. Data: ${response.data}");
      final accessToken = response.data['accessToken'];
      final refreshToken = response.data['refreshToken'];
      
      print("AuthProvider: Storing tokens...");
      await StorageService.storeTokens(accessToken, refreshToken);

      _user = User.fromJson(response.data['user']);
      print("AuthProvider: User parsed: ${_user?.email}");
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      print("AuthProvider: Login failed: $e");
      _status = AuthStatus.unauthenticated;
      rethrow;
    }
  }

  Future<void> signup(String fullName, String email, String password, String confirmPassword) async {
    try {
      await _apiService.dio.post('/auth/signup', data: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      });
      
      // Auto-login after successful signup to set state and tokens
      await login(email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await StorageService.clearTokens();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
