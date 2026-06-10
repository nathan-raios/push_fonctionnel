// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isOrganisateur => 
      _currentUser?.role == UserRole.organisateur;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> initialize() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        _currentUser = await _authService.getUserById(user.uid);
        notifyListeners();
      } catch (e) {
        _currentUser = null;
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _authService.login(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    UserRole role = UserRole.participant,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _authService.register(
        nom: nom,
        prenom: prenom,
        email: email,
        password: password,
        role: role,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile(UserModel user) async {
    await _authService.updateProfile(user);
    _currentUser = user;
    notifyListeners();
  }
}