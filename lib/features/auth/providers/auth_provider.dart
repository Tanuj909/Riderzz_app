import 'package:flutter/material.dart';
import 'package:riderzz_app/core/models/user_model.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/core/utils/jwt_helper.dart';
import 'package:riderzz_app/features/auth/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SecureStorageService _storageService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOtpSent = false;
  bool _isLoginOtpSent = false;

  AuthProvider({
    required AuthRepository authRepository,
    required SecureStorageService storageService,
  })  : _authRepository = authRepository,
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
      await _authRepository.sendOtp(phone);
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
      final user = await _authRepository.register(
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
    if (token != null && JwtHelper.isTokenExpired(token)) {
      debugPrint('Token has expired, logging out user.');
      await logout();
      return false;
    }

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
      final user = await _authRepository.fetchCurrentUser();
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
      await _authRepository.loginSendOtp(phone);
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
      final user = await _authRepository.loginVerifyOtp(
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

  /// Admin Login
  Future<bool> adminLogin({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.adminLogin(
        phone: phone,
        password: password,
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

  /// Update current user's role and save to secure storage
  Future<bool> updateUserRole(String newRole) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _storageService.saveAuthData(
        token: _currentUser!.token ?? '',
        role: newRole,
        userId: _currentUser!.userId,
      );

      _currentUser = UserModel(
        userId: _currentUser!.userId,
        role: newRole,
        token: _currentUser!.token,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        status: _currentUser!.status,
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
