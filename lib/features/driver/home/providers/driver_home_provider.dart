import 'package:flutter/material.dart';
import 'package:riderzz_app/core/models/driver_profile_model.dart';
import 'package:riderzz_app/core/models/driver_wallet_model.dart';
import 'package:riderzz_app/core/models/available_vehicle_model.dart';
import 'package:riderzz_app/core/network/api_exception.dart';
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
      var profile = await _driverRepository.getDriverProfile();
      
      // Fetch documents from /driver/documents separately and attach them to the profile model
      try {
        final docs = await _driverRepository.getDriverDocuments();
        profile = DriverProfileModel(
          id: profile.id,
          userId: profile.userId,
          name: profile.name,
          phone: profile.phone,
          userStatus: profile.userStatus,
          approvalStatus: profile.approvalStatus,
          licenseNumber: profile.licenseNumber,
          vehicleNumber: profile.vehicleNumber,
          isOnline: profile.isOnline,
          rating: profile.rating,
          totalTrips: profile.totalTrips,
          vehicle: profile.vehicle,
          documents: docs,
          createdAt: profile.createdAt,
        );
      } catch (de) {
        debugPrint('Failed to fetch driver documents separately: $de');
      }

      _profile = profile;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _isLoading = false;
      if (e.statusCode == 404 || e.message.toLowerCase().contains('not found')) {
        _profile = null;
        _errorMessage = null;
      } else {
        _errorMessage = e.toString();
      }
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

  // Available Vehicles
  List<AvailableVehicleModel> _availableVehicles = [];
  List<AvailableVehicleModel> get availableVehicles => _availableVehicles;

  Future<void> fetchAvailableVehicles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _availableVehicles = await _driverRepository.getAvailableVehicles();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> applyAsDriver(
    Map<String, dynamic> body, {
    required String aadharUrl,
    required String panUrl,
    required String dlUrl,
    required String rcBookUrl,
    required String insuranceUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Register driver and vehicle details
      await _driverRepository.applyDriver(body);

      // 2. Upload documents to /driver/documents sequentially
      try {
        await _driverRepository.uploadDriverDocument("AADHAR", aadharUrl);
      } catch (e) {
        debugPrint('Failed to upload Aadhar: $e');
      }
      try {
        await _driverRepository.uploadDriverDocument("PAN", panUrl);
      } catch (e) {
        debugPrint('Failed to upload PAN: $e');
      }
      try {
        await _driverRepository.uploadDriverDocument("DRIVING_LICENSE", dlUrl);
      } catch (e) {
        debugPrint('Failed to upload Driving License: $e');
      }
      try {
        await _driverRepository.uploadDriverDocument("RC_BOOK", rcBookUrl);
      } catch (e) {
        debugPrint('Failed to upload RC Book: $e');
      }
      try {
        await _driverRepository.uploadDriverDocument("INSURANCE", insuranceUrl);
      } catch (e) {
        debugPrint('Failed to upload Insurance: $e');
      }
      
      // 3. Re-fetch profile to load state immediately
      await fetchDriverProfile();
      
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

  Future<bool> uploadDocument(String docType, String fileUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _driverRepository.uploadDriverDocument(docType, fileUrl);
      await fetchDriverProfile();
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

