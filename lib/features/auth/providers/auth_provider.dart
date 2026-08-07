import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:riderzz_app/core/models/user_model.dart';
import 'package:riderzz_app/core/models/customer_profile_model.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/core/utils/jwt_helper.dart';
import 'package:riderzz_app/core/services/firebase_notification_service.dart';
import 'package:riderzz_app/features/auth/data/repositories/auth_repository.dart';
import 'package:riderzz_app/features/notification/data/repositories/notification_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SecureStorageService _storageService;
  final NotificationRepository _notificationRepository;

  UserModel? _currentUser;
  CustomerProfileModel? _customerProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOtpSent = false;

  AuthProvider({
    required AuthRepository authRepository,
    required SecureStorageService storageService,
    required NotificationRepository notificationRepository,
  })  : _authRepository = authRepository,
        _storageService = storageService,
        _notificationRepository = notificationRepository;

  UserModel? get currentUser => _currentUser;
  CustomerProfileModel? get customerProfile => _customerProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOtpSent => _isOtpSent;

  void resetState() {
    _isLoading = false;
    _errorMessage = null;
    _isOtpSent = false;
    _customerProfile = null;
    notifyListeners();
  }

  // ── FCM Token Upload Helper ─────────────────────────────────────────────
  // Called after every successful login / registration.
  // Never throws — login must never fail because of this.
  Future<void> _uploadFcmTokenAfterLogin() async {
    try {
      final fcmToken = FirebaseNotificationService.instance.fcmToken;
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('[FCM] No FCM token available, skipping upload.');
        return;
      }
      debugPrint('[FCM] Login successful — uploading device token...');
      await _notificationRepository.registerDeviceToken(fcmToken);
    } catch (e) {
      debugPrint('[FCM] ❌ Post-login token upload failed: $e');
    }
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
        refreshToken: user.refreshToken,
        role: user.role,
        userId: user.userId,
      );

      // Phase 2: Upload FCM token after registration
      await _uploadFcmTokenAfterLogin();

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

  /// Complete registration without OTP
  Future<bool> registerUserNoOtp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.registerNoOtp(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
      );

      _currentUser = user;
      await _storageService.saveAuthData(
        token: user.token ?? '',
        refreshToken: user.refreshToken,
        role: user.role,
        userId: user.userId,
      );

      // Phase 2: Upload FCM token after registration
      await _uploadFcmTokenAfterLogin();

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
    final refreshToken = await _storageService.getRefreshToken();

    if (token != null && role != null && userIdStr != null) {
      final userId = int.tryParse(userIdStr);
      if (userId != null) {
        _currentUser = UserModel(
          userId: userId,
          role: role,
          token: token,
          refreshToken: refreshToken,
        );
        try {
          fetchUserProfile();
        } catch (_) {}

        // Phase 2: Upload FCM token on auto-login (duplicate check inside)
        _uploadFcmTokenAfterLogin();

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
        refreshToken: _currentUser?.refreshToken,
        name: user.name,
        phone: user.phone,
        status: user.status,
        profileImage: user.profileImage,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch user profile: $e');
    }
  }

  /// Sign out
  Future<void> logout() async {
    // Stop foreground location service on logout
    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {}

    // Phase 2: Unregister FCM device token before clearing auth
    try {
      final fcmToken = FirebaseNotificationService.instance.fcmToken;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        debugPrint('[FCM] Logout — removing device token...');
        await _notificationRepository.unregisterDeviceToken(fcmToken);
      }
    } catch (e) {
      debugPrint('[FCM] ❌ Logout token removal failed: $e');
    }

    await _storageService.clearAuthData();
    _currentUser = null;
    resetState();
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
        refreshToken: user.refreshToken,
        role: user.role,
        userId: user.userId,
      );

      // Phase 2: Upload FCM token after OTP login
      await _uploadFcmTokenAfterLogin();

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

  /// Login with Password
  Future<bool> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.loginWithPassword(
        phone: phone,
        password: password,
      );

      _currentUser = user;
      await _storageService.saveAuthData(
        token: user.token ?? '',
        refreshToken: user.refreshToken,
        role: user.role,
        userId: user.userId,
      );

      // Phase 2: Upload FCM token after password login
      await _uploadFcmTokenAfterLogin();

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

  /// Request OTP for Forgot Password
  Future<bool> forgotPasswordSendOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Reusing the sendOtp logic endpoint
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

  /// Reset Password using OTP
  Future<bool> forgotPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.forgotPassword(
        phone: phone,
        otp: otp,
        newPassword: newPassword,
      );
      _isLoading = false;
      _isOtpSent = false;
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
        refreshToken: user.refreshToken,
        role: user.role,
        userId: user.userId,
      );

      // Phase 2: Upload FCM token after admin login
      await _uploadFcmTokenAfterLogin();

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
        refreshToken: _currentUser!.refreshToken,
        role: newRole,
        userId: _currentUser!.userId,
      );

      _currentUser = UserModel(
        userId: _currentUser!.userId,
        role: newRole,
        token: _currentUser!.token,
        refreshToken: _currentUser!.refreshToken,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        status: _currentUser!.status,
        profileImage: _currentUser!.profileImage,
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

  /// Fetch customer profile details
  Future<bool> fetchCustomerProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _authRepository.getCustomerProfile();
      _customerProfile = profile;
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

  /// Update customer profile details
  Future<bool> updateCustomerProfile({
    String? dob,
    String? gender,
    String? bio,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _authRepository.updateCustomerProfile(
        dob: dob,
        gender: gender,
        bio: bio,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      );
      _customerProfile = updatedProfile;
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

  /// Upload customer profile image and update local state
  Future<bool> updateProfileImage(String filePath, String fileName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final imageUrl = await _authRepository.uploadProfileImage(filePath, fileName);
      
      // Update local customer profile if loaded
      if (_customerProfile != null) {
        _customerProfile = CustomerProfileModel(
          userId: _customerProfile!.userId,
          fullName: _customerProfile!.fullName,
          phone: _customerProfile!.phone,
          email: _customerProfile!.email,
          profileImage: imageUrl,
          role: _customerProfile!.role,
          rating: _customerProfile!.rating,
          totalBookings: _customerProfile!.totalBookings,
          gender: _customerProfile!.gender,
          dob: _customerProfile!.dob,
          bio: _customerProfile!.bio,
          emergencyContactName: _customerProfile!.emergencyContactName,
          emergencyContactPhone: _customerProfile!.emergencyContactPhone,
        );
      }

      // Update local current user
      if (_currentUser != null) {
        _currentUser = UserModel(
          userId: _currentUser!.userId,
          role: _currentUser!.role,
          token: _currentUser!.token,
          refreshToken: _currentUser!.refreshToken,
          name: _currentUser!.name,
          phone: _currentUser!.phone,
          status: _currentUser!.status,
          profileImage: imageUrl,
        );
      }

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
