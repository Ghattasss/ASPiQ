// lib/services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const String _tokenKey = 'auth_token'; // المفتاح المستخدم للتخزين
  static String? _cachedToken; // الكاش المؤقت

  /// حفظ التوكن
  static Future<void> saveToken(String token) async {
    if (token.isEmpty) {
       debugPrint("[AuthService.saveToken] Error: Attempted to save an empty token.");
       return;
    }
    _cachedToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      debugPrint("[AuthService.saveToken] Token saved successfully (Cache & SharedPreferences). Key: $_tokenKey");
    } catch (e) {
      debugPrint("[AuthService.saveToken] Error saving token to SharedPreferences: $e");
    }
  }

  /// جلب التوكن
  static Future<String?> getToken() async {
    debugPrint("[AuthService.getToken] Attempting to get token...");
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      debugPrint("[AuthService.getToken] Token found in cache.");
      return _cachedToken;
    }
    debugPrint("[AuthService.getToken] Token not in cache, trying SharedPreferences...");
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tokenFromStorage = prefs.getString(_tokenKey);
      if (tokenFromStorage != null && tokenFromStorage.isNotEmpty) {
        debugPrint("[AuthService.getToken] Token retrieved from SharedPreferences.");
        _cachedToken = tokenFromStorage;
        return tokenFromStorage;
      } else {
        debugPrint("[AuthService.getToken] Token not found in SharedPreferences for key '$_tokenKey'.");
        return null;
      }
    } catch (e) {
      debugPrint("[AuthService.getToken] Error reading token from SharedPreferences: $e");
      return null;
    }
  }

  /// مسح التوكن
  static Future<void> clearToken() async {
    _cachedToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      debugPrint("[AuthService.clearToken] Token cleared successfully (Cache & SharedPreferences).");
    } catch (e) {
      debugPrint("[AuthService.clearToken] Error clearing token from SharedPreferences: $e");
    }
  }
}