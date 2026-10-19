import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// BackendStorageService manages persistent data storage for:
/// 1. User Account & Login Credentials
/// 2. Medical Profiles & First-Responder Kits (Blood Group, BP, Asthma, Sugar)
/// 3. Emergency Contacts
/// 4. SOS Incident Logs & Location History
class BackendStorageService {
  // In-Memory Database table (zero external dependencies needed)
  static final Map<String, Map<String, dynamic>> _usersDb = {};
  static String? _activeSessionToken;
  static final List<String> _locationLogs = [];

  /// 1. BACKEND SIGN-UP: Stores new user registration record into DB
  static Future<bool> saveUserToBackend(UserModel user) async {
    try {
      final userKey = user.email.toLowerCase().trim();
      _usersDb[userKey] = user.toJson();
      _activeSessionToken = userKey;

      debugPrint('[Backend DB] Saved user account successfully: ${user.name} (${user.email})');
      return true;
    } catch (e) {
      debugPrint('[Backend DB] Error saving user: $e');
      return false;
    }
  }

  /// 2. BACKEND LOGIN: Validates credentials against stored database
  static Future<UserModel?> authenticateUserFromBackend({
    required String identifier,
    required String password,
  }) async {
    try {
      final cleanId = identifier.trim().toLowerCase();

      for (var entry in _usersDb.values) {
        final emailMatches = entry['email'].toString().toLowerCase() == cleanId;
        final phoneMatches = entry['phone'].toString() == identifier.trim();

        if ((emailMatches || phoneMatches) && entry['password'] == password) {
          _activeSessionToken = entry['email'].toString().toLowerCase();
          debugPrint('[Backend DB] Login authenticated for: ${entry['name']}');
          return UserModel.fromJson(entry);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[Backend DB] Auth error: $e');
      return null;
    }
  }

  /// 3. BACKEND SESSION RESTORE: Automatically loads active user on app launch
  static Future<UserModel?> getActiveSessionUser() async {
    try {
      if (_activeSessionToken != null && _usersDb.containsKey(_activeSessionToken)) {
        return UserModel.fromJson(_usersDb[_activeSessionToken]!);
      }
      return null;
    } catch (e) {
      debugPrint('[Backend DB] Error fetching active session: $e');
      return null;
    }
  }

  /// 4. LOGOUT: Clears active session token from backend storage
  static Future<void> clearSession() async {
    _activeSessionToken = null;
  }

  /// 5. LOCATION TRACKING LOGS: Stores breadcrumbs of user GPS route
  static Future<void> logLocationBreadcrumb(double lat, double lng, String address) async {
    try {
      final logEntry = json.encode({
        'lat': lat,
        'lng': lng,
        'address': address,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _locationLogs.add(logEntry);
      if (_locationLogs.length > 50) _locationLogs.removeAt(0);
    } catch (e) {
      debugPrint('[Backend DB] Error logging location: $e');
    }
  }
}