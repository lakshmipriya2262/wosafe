import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const String _userStorageKey = 'homesafe_active_user_v1';

  AuthProvider() {
    _loadUserFromStorage();
  }

  /// Automatically restore saved user profile from persistent storage
  Future<void> _loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString(_userStorageKey);

      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        final Map<String, dynamic> userMap = json.decode(userJsonStr);
        _currentUser = UserModel.fromJson(userMap);
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Error loading user from SharedPreferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new account with complete medical profile and 2 emergency contacts
  Future<bool> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String bloodGroup,
    required String bloodPressure,
    required bool hasDiabetes,
    required bool hasAsthma,
    required double height,
    required double weight,
    required List<EmergencyContact> emergencyContacts,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create user model with exact details entered by user
      final newUser = UserModel(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        password: password,
        bloodGroup: bloodGroup,
        bloodPressure: bloodPressure,
        hasDiabetes: hasDiabetes,
        hasAsthma: hasAsthma,
        height: height,
        weight: weight,
        emergencyContacts: emergencyContacts,
      );

      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(newUser.toJson());
      await prefs.setString(_userStorageKey, userJson);

      _currentUser = null; // Cleared until user logs in
      _isAuthenticated = false; // Requires explicit login!
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with email or phone and password
  Future<bool> loginUser({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString(_userStorageKey);

      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        final Map<String, dynamic> userMap = json.decode(userJsonStr);
        final savedUser = UserModel.fromJson(userMap);

        final cleanIdentifier = identifier.trim().toLowerCase();
        final matchesEmail = savedUser.email.toLowerCase() == cleanIdentifier;
        final matchesPhone = savedUser.phone == identifier.trim();

        if ((matchesEmail || matchesPhone) && savedUser.password == password) {
          _currentUser = savedUser;
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Invalid email/phone or password. Please check your credentials.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // If no user was ever registered, advise them to create an account
        _errorMessage = 'No account found. Please sign up first to register your profile.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update medical profile or emergency contacts
  Future<void> updateProfile(UserModel updatedUser) async {
    _currentUser = updatedUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userStorageKey, json.encode(updatedUser.toJson()));
    notifyListeners();
  }

  /// Logout and clear active session
  Future<void> logout() async {
    _isAuthenticated = false;
    notifyListeners();
  }
}