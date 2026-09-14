import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'auth_api_service.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    await AuthApiService.instance.loadStoredToken();
    try {
      _currentUser = await AuthApiService.instance.fetchCurrentUser();
    } on AuthApiException catch (e) {
      debugPrint('Auth restore failed: $e');
      _currentUser = null;
    } catch (e) {
      debugPrint('Auth restore failed: $e');
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<User> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      _currentUser = await AuthApiService.instance.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      notifyListeners();
      return _currentUser!;
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw const AuthException(
        'Could not reach FabriCare API. Start fabricare_api.py and check MySQL (.env).',
      );
    }
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      _currentUser = await AuthApiService.instance.login(
        email: email,
        password: password,
      );
      notifyListeners();
      return _currentUser!;
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw const AuthException(
        'Could not reach FabriCare API. Start fabricare_api.py and check MySQL (.env).',
      );
    }
  }

  Future<void> logout() async {
    await AuthApiService.instance.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    String? phone,
    String? location,
  }) async {
    if (_currentUser == null) throw const AuthException('Not logged in.');

    try {
      _currentUser = await AuthApiService.instance.updateProfile(
        fullName: fullName,
        email: email,
        phone: phone,
        location: location,
      );
      notifyListeners();
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) throw const AuthException('Not logged in.');

    try {
      await AuthApiService.instance.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    }
  }
}
