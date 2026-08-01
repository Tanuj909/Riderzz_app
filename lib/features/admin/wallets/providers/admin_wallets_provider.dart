import 'package:flutter/material.dart';
import 'package:riderzz_app/core/models/admin_driver_model.dart';
import 'package:riderzz_app/core/models/driver_wallet_model.dart';
import 'package:riderzz_app/core/models/admin_wallet_model.dart';
import 'package:riderzz_app/core/models/admin_wallet_overview_model.dart';
import 'package:riderzz_app/core/models/admin_withdrawal_model.dart';
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

  // New Wallet Admin States
  AdminWalletOverviewModel? _overview;
  bool _isOverviewLoading = false;
  String? _overviewErrorMessage;

  List<AdminWalletModel> _wallets = [];
  bool _isWalletsLoading = false;
  bool _isWalletsLoadMore = false;
  String? _walletsErrorMessage;
  int _walletsCurrentPage = 0;
  bool _isWalletsLastPage = false;

  List<DriverWalletTransactionModel> _driverTransactions = [];
  bool _isTxLoading = false;
  bool _isTxLoadMore = false;
  String? _txErrorMessage;
  int _txCurrentPage = 0;
  bool _isTxLastPage = false;

  List<AdminWithdrawalModel> _pendingWithdrawals = [];
  List<AdminWithdrawalModel> _allWithdrawals = [];


  AdminWalletsProvider(this._repository);

  List<AdminDriverModel> get approvedDrivers => _approvedDrivers;
  bool get isLoading => _isLoading;
  bool get isLoadMore => _isLoadMore;
  String? get errorMessage => _errorMessage;
  bool get isLastPage => _isLastPage;

  DriverWalletModel? get selectedDriverWallet => _selectedDriverWallet;
  bool get isWalletLoading => _isWalletLoading;
  String? get walletErrorMessage => _walletErrorMessage;

  AdminWalletOverviewModel? get overview => _overview;
  bool get isOverviewLoading => _isOverviewLoading;
  String? get overviewErrorMessage => _overviewErrorMessage;

  List<AdminWalletModel> get wallets => _wallets;
  bool get isWalletsLoading => _isWalletsLoading;
  bool get isWalletsLoadMore => _isWalletsLoadMore;
  String? get walletsErrorMessage => _walletsErrorMessage;
  bool get isWalletsLastPage => _isWalletsLastPage;

  List<DriverWalletTransactionModel> get driverTransactions => _driverTransactions;
  bool get isTxLoading => _isTxLoading;
  bool get isTxLoadMore => _isTxLoadMore;
  String? get txErrorMessage => _txErrorMessage;
  bool get isTxLastPage => _isTxLastPage;

  List<AdminWithdrawalModel> get pendingWithdrawals => _pendingWithdrawals;
  List<AdminWithdrawalModel> get allWithdrawals => _allWithdrawals;


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

    _overview = null;
    _isOverviewLoading = false;
    _overviewErrorMessage = null;

    _wallets = [];
    _isWalletsLoading = false;
    _isWalletsLoadMore = false;
    _walletsErrorMessage = null;
    _walletsCurrentPage = 0;
    _isWalletsLastPage = false;

    _driverTransactions = [];
    _isTxLoading = false;
    _isTxLoadMore = false;
    _txErrorMessage = null;
    _txCurrentPage = 0;
    _isTxLastPage = false;

    _pendingWithdrawals = [];
    _allWithdrawals = [];
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
      await fetchDriverTransactions(driverId: driverId, isRefresh: true);
      return true;
    } catch (e) {
      _walletErrorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchWalletOverview() async {
    _isOverviewLoading = true;
    _overviewErrorMessage = null;
    notifyListeners();

    try {
      _overview = await _repository.getWalletOverview();
      _isOverviewLoading = false;
      notifyListeners();
    } catch (e) {
      _isOverviewLoading = false;
      _overviewErrorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> fetchWallets({bool isRefresh = false}) async {
    if (isRefresh) {
      _walletsCurrentPage = 0;
      _isWalletsLastPage = false;
      _wallets = [];
    }

    if (_isWalletsLastPage && !isRefresh) return;

    if (isRefresh || _wallets.isEmpty) {
      _isWalletsLoading = true;
      _walletsErrorMessage = null;
    } else {
      _isWalletsLoadMore = true;
    }
    notifyListeners();

    try {
      final result = await _repository.getAllWallets(
        page: _walletsCurrentPage,
        size: _pageSize,
      );

      final List<AdminWalletModel> newWallets = result['wallets'] as List<AdminWalletModel>;
      _isWalletsLastPage = result['isLast'] as bool? ?? true;

      if (isRefresh) {
        _wallets = newWallets;
      } else {
        _wallets.addAll(newWallets);
      }

      if (!_isWalletsLastPage) {
        _walletsCurrentPage++;
      }

      _isWalletsLoading = false;
      _isWalletsLoadMore = false;
      notifyListeners();
    } catch (e) {
      _isWalletsLoading = false;
      _isWalletsLoadMore = false;
      _walletsErrorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> fetchDriverTransactions({required int driverId, bool isRefresh = false}) async {
    if (isRefresh) {
      _txCurrentPage = 0;
      _isTxLastPage = false;
      _driverTransactions = [];
    }

    if (_isTxLastPage && !isRefresh) return;

    if (isRefresh || _driverTransactions.isEmpty) {
      _isTxLoading = true;
      _txErrorMessage = null;
    } else {
      _isTxLoadMore = true;
    }
    notifyListeners();

    try {
      final result = await _repository.getDriverTransactions(
        driverId: driverId,
        page: _txCurrentPage,
        size: _pageSize,
      );

      final List<DriverWalletTransactionModel> newTxs = result['transactions'] as List<DriverWalletTransactionModel>;
      _isTxLastPage = result['isLast'] as bool? ?? true;

      if (isRefresh) {
        _driverTransactions = newTxs;
      } else {
        _driverTransactions.addAll(newTxs);
      }

      if (!_isTxLastPage) {
        _txCurrentPage++;
      }

      _isTxLoading = false;
      _isTxLoadMore = false;
      notifyListeners();
    } catch (e) {
      _isTxLoading = false;
      _isTxLoadMore = false;
      _txErrorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> fetchPendingWithdrawals({required int page, required int size}) async {
    try {
      final result = await _repository.getPendingWithdrawals(page: page, size: size);
      _pendingWithdrawals = result['withdrawals'] as List<AdminWithdrawalModel>;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchAllWithdrawals({required int page, required int size}) async {
    try {
      final result = await _repository.getAllWithdrawals(page: page, size: size);
      _allWithdrawals = result['withdrawals'] as List<AdminWithdrawalModel>;
      notifyListeners();
    } catch (_) {}
  }
}
