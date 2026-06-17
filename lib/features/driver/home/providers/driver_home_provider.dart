import 'package:flutter/material.dart';
import 'package:riderzz_app/core/models/driver_profile_model.dart';
import 'package:riderzz_app/core/models/driver_wallet_model.dart';
import 'package:riderzz_app/features/driver/home/data/repositories/driver_repository.dart';

class DriverHomeProvider extends ChangeNotifier {
  final DriverRepository _driverRepository;

  DriverProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  // Wallet properties
  DriverWalletModel? _wallet;
  bool _isWalletLoading = false;
  String? _walletError;

  DriverHomeProvider(this._driverRepository);

  DriverProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Wallet getters
  DriverWalletModel? get wallet => _wallet;
  bool get isWalletLoading => _isWalletLoading;
  String? get walletError => _walletError;

  Future<void> fetchDriverProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _driverRepository.getDriverProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> fetchDriverWallet() async {
    _isWalletLoading = true;
    _walletError = null;
    notifyListeners();

    try {
      _wallet = await _driverRepository.getDriverWallet();
      _isWalletLoading = false;
      notifyListeners();
    } catch (e) {
      _isWalletLoading = false;
      _walletError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> rechargeWallet(double amount) async {
    _isWalletLoading = true;
    _walletError = null;
    notifyListeners();

    try {
      _wallet = await _driverRepository.rechargeDriverWallet(amount);
      _isWalletLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isWalletLoading = false;
      _walletError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> setOnlineStatus(bool online) async {
    if (_profile == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = online 
          ? await _driverRepository.goOnline() 
          : await _driverRepository.goOffline();
      
      _profile = DriverProfileModel(
        id: _profile!.id,
        userId: _profile!.userId,
        name: _profile!.name,
        phone: _profile!.phone,
        userStatus: _profile!.userStatus,
        approvalStatus: _profile!.approvalStatus,
        licenseNumber: _profile!.licenseNumber,
        vehicleNumber: _profile!.vehicleNumber,
        isOnline: success,
        rating: _profile!.rating,
        totalTrips: _profile!.totalTrips,
        vehicle: _profile!.vehicle,
        documents: _profile!.documents,
        createdAt: _profile!.createdAt,
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

  Future<bool> toggleOnlineOffline() async {
    if (_profile == null) return false;
    return await setOnlineStatus(!_profile!.isOnline);
  }
}
