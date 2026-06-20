import 'package:flutter/material.dart';
import 'package:riderzz_app/core/models/admin_driver_model.dart';
import 'package:riderzz_app/core/models/driver_wallet_model.dart';
import 'package:riderzz_app/features/admin/rider_verification/data/repositories/rider_verification_repository.dart';

class AdminWalletsProvider extends ChangeNotifier {
  final RiderVerificationRepository _repository;

  List<AdminDriverModel> _approvedDrivers = [];
  bool _isLoading = false;
  bool _isLoadMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLastPage = false;

  // Selected driver wallet state
  DriverWalletModel? _selectedDriverWallet;
  bool _isWalletLoading = false;
  String? _walletErrorMessage;

  AdminWalletsProvider(this._repository);

  List<AdminDriverModel> get approvedDrivers => _approvedDrivers;
  bool get isLoading => _isLoading;
  bool get isLoadMore => _isLoadMore;
  String? get errorMessage => _errorMessage;
  bool get isLastPage => _isLastPage;

  DriverWalletModel? get selectedDriverWallet => _selectedDriverWallet;
  bool get isWalletLoading => _isWalletLoading;
  String? get walletErrorMessage => _walletErrorMessage;

  void resetState() {
    _approvedDrivers = [];
    _isLoading = false;
    _isLoadMore = false;
    _errorMessage = null;
    _currentPage = 0;
    _isLastPage = false;
    _selectedDriverWallet = null;
    _isWalletLoading = false;
    _walletErrorMessage = null;
    notifyListeners();
  }

  /// Fetches approved drivers from the remote server.
  Future<void> fetchApprovedDrivers({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _isLastPage = false;
      _approvedDrivers = [];
    }

    if (_isLastPage && !isRefresh) return;

    if (isRefresh || _approvedDrivers.isEmpty) {
      _isLoading = true;
      _errorMessage = null;
    } else {
      _isLoadMore = true;
    }
    notifyListeners();

    try {
      final result = await _repository.getDrivers(
        page: _currentPage,
        size: _pageSize,
        status: 'APPROVED',
      );

      final List<AdminDriverModel> newDrivers = result['drivers'] as List<AdminDriverModel>;
      _isLastPage = result['isLast'] as bool? ?? true;

      if (isRefresh) {
        _approvedDrivers = newDrivers;
      } else {
        _approvedDrivers.addAll(newDrivers);
      }

      if (!_isLastPage) {
        _currentPage++;
      }

      _isLoading = false;
      _isLoadMore = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _isLoadMore = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Forces a driver offline and updates the local isOnline status to false.
  Future<bool> forceDriverOffline(int driverId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.forceDriverOffline(driverId);

      final index = _approvedDrivers.indexWhere((d) => d.id == driverId);
      if (index != -1) {
        final old = _approvedDrivers[index];
        _approvedDrivers[index] = AdminDriverModel(
          id: old.id,
          userId: old.userId,
          name: old.name,
          phone: old.phone,
          userStatus: old.userStatus,
          approvalStatus: old.approvalStatus,
          licenseNumber: old.licenseNumber,
          vehicleNumber: old.vehicleNumber,
          isOnline: false,
          rating: old.rating,
          totalTrips: old.totalTrips,
          vehicle: old.vehicle,
          documents: old.documents,
          createdAt: old.createdAt,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Fetches a specific driver's wallet.
  Future<void> fetchDriverWallet(int driverId) async {
    _isWalletLoading = true;
    _walletErrorMessage = null;
    _selectedDriverWallet = null;
    notifyListeners();

    try {
      final wallet = await _repository.getDriverWallet(driverId);
      _selectedDriverWallet = wallet;
      _isWalletLoading = false;
      notifyListeners();
    } catch (e) {
      _isWalletLoading = false;
      _walletErrorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Adjusts a driver's wallet and re-fetches the wallet upon success.
  Future<bool> adjustDriverWallet({
    required int driverId,
    required String type,
    required double amount,
    required String description,
  }) async {
    _walletErrorMessage = null;
    notifyListeners();

    try {
      await _repository.adjustDriverWallet(
        driverId: driverId,
        type: type,
        amount: amount,
        description: description,
      );

      // Re-fetch wallet details to get updated balance & transaction history
      await fetchDriverWallet(driverId);
      return true;
    } catch (e) {
      _walletErrorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
