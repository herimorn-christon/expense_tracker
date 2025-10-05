import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:expense_tracker_mobile/core/network/api_client.dart';
import 'package:expense_tracker_mobile/data/models/user.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthService(this._apiClient, this._storage);

  Future<User> login(String email, String password) async {
    try {
      final response = await _apiClient.post('/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle Laravel API response structure
        final data = responseData is Map<String, dynamic> && responseData.containsKey('data')
            ? responseData['data'] as Map<String, dynamic>
            : responseData as Map<String, dynamic>;

        // Store token securely
        if (data['token'] != null) {
          await _storage.write(key: 'token', value: data['token']);
        }

        // Return user data
        return User.fromJson(data['user']);
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<User> register(String name, String email, String password, String passwordConfirmation) async {
    try {
      final response = await _apiClient.post('/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      if (response.statusCode == 201) {
        final responseData = response.data;

        // Handle Laravel API response structure
        final data = responseData is Map<String, dynamic> && responseData.containsKey('data')
            ? responseData['data'] as Map<String, dynamic>
            : responseData as Map<String, dynamic>;

        // Store token securely
        if (data['token'] != null) {
          await _storage.write(key: 'token', value: data['token']);
        }

        // Return user data
        return User.fromJson(data['user']);
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/logout');
    } catch (e) {
      // Even if logout fails on server, we should clear local token
      print('Logout error: $e');
    } finally {
      // Always clear local token
      await _storage.delete(key: 'token');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/user');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle Laravel API response structure
        final data = responseData is Map<String, dynamic> && responseData.containsKey('data')
            ? responseData['data'] as Map<String, dynamic>
            : responseData as Map<String, dynamic>;

        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;

    // Verify token is still valid by making a request
    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      // Token is invalid, remove it
      await _storage.delete(key: 'token');
      return false;
    }
  }

  Future<void> refreshToken() async {
    try {
      // Try to get current user to refresh token via interceptor
      await getCurrentUser();
    } catch (e) {
      throw Exception('Token refresh failed');
    }
  }
}