import 'package:flutter/material.dart';
import 'package:riderzz_app/core/models/user_model.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/features/auth/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SecureStorageService _storageService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOtpSent = false;
  bool _isLoginOtpSent = false;

  AuthProvider({
    required AuthService authService,
    required SecureStorageService storageService,
  })  : _authService = authService,
        _storageService = storageService;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOtpSent => _isOtpSent;
  bool get isLoginOtpSent => _isLoginOtpSent;

  void resetState() {
    _isLoading = false;
    _errorMessage = null;
    _isOtpSent = false;
    _isLoginOtpSent = false;
    notifyListeners();
  }

  /// Request OTP for a phone number
  Future<bool> requestOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendOtp(phone);
      _isOtpSent = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Complete registration with user inputs
  Future<bool> registerUser({
    required String name,
    required String phone,
    required String password,
    required String otp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        name: name,
        phone: phone,
        password: password,
        otp: otp,
      );

      _currentUser = user;
      await _storageService.saveAuthData(
        token: user.token ?? '',
        role: user.role,
        userId: user.userId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Try local storage login auto recovery
  Future<bool> tryAutoLogin() async {
    final token = await _storageService.getToken();
    final role = await _storageService.getRole();
    final userIdStr = await _storageService.getUserId();

    if (token != null && role != null && userIdStr != null) {
      final userId = int.tryParse(userIdStr);
      if (userId != null) {
        _currentUser = UserModel(
          userId: userId,
          role: role,
          token: token,
        );
        try {
          await fetchUserProfile();
        } catch (_) {}
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Fetches the full user profile from the server
  Future<void> fetchUserProfile() async {
    try {
      final user = await _authService.fetchCurrentUser();
      _currentUser = UserModel(
        userId: user.userId,
        role: user.role,
        token: _currentUser?.token,
        name: user.name,
        phone: user.phone,
        status: user.status,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch user profile: $e');
    }
  }

  /// Sign out
  Future<void> logout() async {
    await _storageService.clearAuthData();
    _currentUser = null;
    resetState();
  }

  /// Request OTP for login
  Future<bool> loginRequestOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.loginSendOtp(phone);
      _isLoginOtpSent = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP for login and sign in
  Future<bool> loginVerifyOtp({
    required String phone,
    required String otp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.loginVerifyOtp(
        phone: phone,
        otp: otp,
      );

      _currentUser = user;
      await _storageService.saveAuthData(
        token: user.token ?? '',
        role: user.role,
        userId: user.userId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
