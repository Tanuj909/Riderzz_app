import 'package:flutter/material.dart';
import 'package:riderzz_app/core/models/driver_profile_model.dart';
import 'package:riderzz_app/core/models/driver_wallet_model.dart';
import 'package:riderzz_app/core/models/available_vehicle_model.dart';
import 'package:riderzz_app/core/models/bank_account_model.dart';
import 'package:riderzz_app/core/network/api_exception.dart';
import 'package:riderzz_app/features/driver/home/data/repositories/driver_repository.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/core/models/driver_earnings_model.dart';

class DriverHomeProvider extends ChangeNotifier {
  final DriverRepository _driverRepository;

  DriverProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  // Wallet properties
  DriverWalletModel? _wallet;
  bool _isWalletLoading = false;
  String? _walletError;
  bool _isWalletNotCreated = false;

  // Bank Accounts properties
  List<BankAccountModel> _bankAccounts = [];
  BankAccountModel? _primaryBankAccount;
  bool _isBankAccountsLoading = false;
  String? _bankAccountsError;

  // Booking states
  BookingModel? _activeBooking;
  List<BookingModel> _pendingBookings = [];
  bool _isBookingsLoading = false;
  String? _bookingsError;

  // Earnings properties
  DriverEarningsModel? _earnings;
  bool _isEarningsLoading = false;
  String? _earningsError;

  DriverHomeProvider(this._driverRepository);

  DriverProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Wallet getters
  DriverWalletModel? get wallet => _wallet;
  bool get isWalletLoading => _isWalletLoading;
  String? get walletError => _walletError;
  bool get isWalletNotCreated => _isWalletNotCreated;

  // Bank Accounts getters
  List<BankAccountModel> get bankAccounts => _bankAccounts;
  BankAccountModel? get primaryBankAccount => _primaryBankAccount;
  bool get isBankAccountsLoading => _isBankAccountsLoading;
  String? get bankAccountsError => _bankAccountsError;

  // Booking getters
  BookingModel? get activeBooking => _activeBooking;
  List<BookingModel> get pendingBookings => _pendingBookings;
  bool get isBookingsLoading => _isBookingsLoading;
  String? get bookingsError => _bookingsError;

  // Earnings getters
  DriverEarningsModel? get earnings => _earnings;
  bool get isEarningsLoading => _isEarningsLoading;
  String? get earningsError => _earningsError;

  Future<void> fetchDriverProfile({bool force = false}) async {
    if (!force && _profile != null) {
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _driverRepository.getDriverProfile();
      _profile = profile;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _isLoading = false;
      if (e.statusCode == 404 ||
          e.message.toLowerCase().contains('not found')) {
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

  Future<void> fetchDriverWallet({bool force = false}) async {
    if (!force && _wallet != null) {
      return;
    }
    _isWalletLoading = true;
    _walletError = null;
    _isWalletNotCreated = false;
    notifyListeners();

    try {
      _wallet = await _driverRepository.getDriverWallet();
      _isWalletLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 404 ||
          e.message.toLowerCase().contains('not found')) {
        _isWalletNotCreated = true;
        _isWalletLoading = false;
        notifyListeners();
      } else {
        _isWalletLoading = false;
        _walletError = e.message;
        notifyListeners();
      }
    } catch (e) {
      _isWalletLoading = false;
      _walletError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> fetchDriverEarnings({bool force = false}) async {
    if (!force && _earnings != null) {
      return;
    }
    _isEarningsLoading = true;
    _earningsError = null;
    notifyListeners();

    try {
      _earnings = await _driverRepository.getDriverEarnings();
    } catch (e) {
      _earningsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isEarningsLoading = false;
      notifyListeners();
    }
  }

  Future<void> createDriverWallet() async {
    _isWalletLoading = true;
    _walletError = null;
    notifyListeners();

    try {
      _wallet = await _driverRepository.createDriverWallet();
      _isWalletNotCreated = false;
      _isWalletLoading = false;
      notifyListeners();
    } catch (e) {
      _isWalletLoading = false;
      _walletError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<RechargeInitiateResponse?> initiateRecharge(double amount) async {
    _isWalletLoading = true;
    _walletError = null;
    notifyListeners();

    try {
      final res = await _driverRepository.initiateWalletRecharge(amount);
      _isWalletLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _isWalletLoading = false;
      _walletError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyRecharge(int rechargeId, String orderId, String paymentId, String signature) async {
    _isWalletLoading = true;
    _walletError = null;
    notifyListeners();

    try {
      await _driverRepository.verifyWalletRecharge(rechargeId, orderId, paymentId, signature);
      // Re-fetch wallet to get updated balance
      await fetchDriverWallet(force: true);
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
        color: _profile!.color,
        manufacturingYear: _profile!.manufacturingYear,
        vehicleStatus: _profile!.vehicleStatus,
        licenseExpiry: _profile!.licenseExpiry,
        insuranceExpiry: _profile!.insuranceExpiry,
        bio: _profile!.bio,
        gender: _profile!.gender,
        dob: _profile!.dob,
        approvedAt: _profile!.approvedAt,
        vehicleTypeName: _profile!.vehicleTypeName,
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
    required String aadharFrontPath,
    required String aadharBackPath,
    required String panCardPath,
    required String dlFrontPath,
    required String dlBackPath,
    required String rcBookPath,
    required String insurancePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Register driver and vehicle details
      await _driverRepository.applyDriver(body);

      // 2. Upload documents to /driver/documents sequentially
      if (aadharFrontPath.isNotEmpty) {
        try {
          await _driverRepository.uploadDriverDocument(
            "AADHAAR_FRONT",
            aadharFrontPath,
          );
        } catch (e) {
          debugPrint('Failed to upload Aadhar Front: $e');
        }
      }
      if (aadharBackPath.isNotEmpty) {
        try {
          await _driverRepository.uploadDriverDocument(
            "AADHAAR_BACK",
            aadharBackPath,
          );
        } catch (e) {
          debugPrint('Failed to upload Aadhar Back: $e');
        }
      }
      if (panCardPath.isNotEmpty) {
        try {
          await _driverRepository.uploadDriverDocument("PAN_CARD", panCardPath);
        } catch (e) {
          debugPrint('Failed to upload PAN Card: $e');
        }
      }
      if (dlFrontPath.isNotEmpty) {
        try {
          await _driverRepository.uploadDriverDocument(
            "DRIVING_LICENSE_FRONT",
            dlFrontPath,
          );
        } catch (e) {
          debugPrint('Failed to upload DL Front: $e');
        }
      }
      if (dlBackPath.isNotEmpty) {
        try {
          await _driverRepository.uploadDriverDocument(
            "DRIVING_LICENSE_BACK",
            dlBackPath,
          );
        } catch (e) {
          debugPrint('Failed to upload DL Back: $e');
        }
      }
      if (rcBookPath.isNotEmpty) {
        try {
          await _driverRepository.uploadDriverDocument("RC_BOOK", rcBookPath);
        } catch (e) {
          debugPrint('Failed to upload RC Book: $e');
        }
      }
      if (insurancePath.isNotEmpty) {
        try {
          await _driverRepository.uploadDriverDocument(
            "INSURANCE",
            insurancePath,
          );
        } catch (e) {
          debugPrint('Failed to upload Insurance: $e');
        }
      }

      // 3. Re-fetch profile to load state immediately
      await fetchDriverProfile(force: true);

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

  Future<bool> uploadDocument(String docType, String filePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _driverRepository.uploadDriverDocument(docType, filePath);
      await fetchDriverProfile(force: true);
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

  Future<bool> updateProfile({
    required String licenseNumber,
    required String bio,
    required String gender,
    required String dob,
    String? upiId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _driverRepository.updateDriverProfile(
        licenseNumber: licenseNumber,
        bio: bio,
        gender: gender,
        dob: dob,
        upiId: upiId,
      );
      _profile = updatedProfile;
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

  // Bank Accounts operations
  Future<void> fetchBankAccounts() async {
    _isBankAccountsLoading = true;
    _bankAccountsError = null;
    notifyListeners();

    try {
      _bankAccounts = await _driverRepository.getBankAccounts();
      // Update _primaryBankAccount locally based on the list
      final primary = _bankAccounts.firstWhere(
        (acc) => acc.primaryAccount,
        orElse: () => BankAccountModel(
          id: 0,
          accountHolderName: '',
          bankName: '',
          accountNumber: '',
          ifscCode: '',
          primaryAccount: false,
        ),
      );
      _primaryBankAccount = primary.id != 0 ? primary : null;
      _isBankAccountsLoading = false;
      notifyListeners();
    } catch (e) {
      _isBankAccountsLoading = false;
      _bankAccountsError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> addBankAccount(Map<String, dynamic> data) async {
    _isBankAccountsLoading = true;
    _bankAccountsError = null;
    notifyListeners();

    try {
      await _driverRepository.addBankAccount(data);
      await fetchBankAccounts(); // Refresh the list
      return true;
    } catch (e) {
      _isBankAccountsLoading = false;
      _bankAccountsError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBankAccount(int id, Map<String, dynamic> data) async {
    _isBankAccountsLoading = true;
    _bankAccountsError = null;
    notifyListeners();

    try {
      await _driverRepository.updateBankAccount(id, data);
      await fetchBankAccounts(); // Refresh the list
      return true;
    } catch (e) {
      _isBankAccountsLoading = false;
      _bankAccountsError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBankAccount(int id) async {
    _isBankAccountsLoading = true;
    _bankAccountsError = null;
    notifyListeners();

    try {
      await _driverRepository.deleteBankAccount(id);
      await fetchBankAccounts(); // Refresh the list
      return true;
    } catch (e) {
      _isBankAccountsLoading = false;
      _bankAccountsError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchPrimaryBankAccount() async {
    _isBankAccountsLoading = true;
    _bankAccountsError = null;
    notifyListeners();

    try {
      _primaryBankAccount = await _driverRepository.getPrimaryBankAccount();
      _isBankAccountsLoading = false;
      notifyListeners();
    } catch (e) {
      _isBankAccountsLoading = false;
      _bankAccountsError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> fetchHomeBookings() async {
    _isBookingsLoading = true;
    _bookingsError = null;
    notifyListeners();

    try {
      // 1. Fetch My Driver Bookings first
      final driverBookings = await _driverRepository.getDriverBookings(page: 0, size: 20);
      
      BookingModel? active;
      if (driverBookings.isNotEmpty) {
        final latest = driverBookings.first;
        final statusUpper = latest.status.toUpperCase();
        if (statusUpper != 'DELIVERED' && 
            statusUpper != 'COMPLETED' && 
            statusUpper != 'CANCELLED' && 
            statusUpper != 'PENDING') {
          active = latest;
        }
      }

      _activeBooking = active;

      // 2. If no active booking, fetch pending broadcasts
      if (_activeBooking == null) {
        _pendingBookings = await _driverRepository.getPendingBroadcasts();
      } else {
        _pendingBookings = [];
      }
    } catch (e) {
      _bookingsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isBookingsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtpForBooking(int bookingId, String otp) async {
    _isBookingsLoading = true;
    _bookingsError = null;
    notifyListeners();

    try {
      await _driverRepository.verifyOtp(bookingId, otp);
      await fetchHomeBookings();
      return true;
    } catch (e) {
      _bookingsError = e.toString().replaceFirst('Exception: ', '');
      _isBookingsLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatusForBooking(int bookingId, String status) async {
    _isBookingsLoading = true;
    _bookingsError = null;
    notifyListeners();

    try {
      await _driverRepository.updateBookingStatus(bookingId, status);
      await fetchHomeBookings();
      return true;
    } catch (e) {
      _bookingsError = e.toString().replaceFirst('Exception: ', '');
      _isBookingsLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptBookingForDriver(int bookingId) async {
    _isBookingsLoading = true;
    _bookingsError = null;
    notifyListeners();

    try {
      await _driverRepository.acceptBooking(bookingId);
      await fetchHomeBookings();
      return true;
    } catch (e) {
      _bookingsError = e.toString().replaceFirst('Exception: ', '');
      _isBookingsLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectBookingForDriver(int bookingId, String reason) async {
    _isBookingsLoading = true;
    _bookingsError = null;
    notifyListeners();

    try {
      await _driverRepository.rejectBooking(bookingId, reason);
      await fetchHomeBookings();
      return true;
    } catch (e) {
      _bookingsError = e.toString().replaceFirst('Exception: ', '');
      _isBookingsLoading = false;
      notifyListeners();
      return false;
    }
  }
}
