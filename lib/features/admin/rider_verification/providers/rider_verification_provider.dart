import 'package:flutter/material.dart';
import 'package:riderzz_app/core/models/admin_driver_model.dart';
import 'package:riderzz_app/features/admin/rider_verification/data/repositories/rider_verification_repository.dart';

class RiderVerificationProvider extends ChangeNotifier {
  final RiderVerificationRepository _repository;

  List<AdminDriverModel> _drivers = [];
  bool _isLoading = false;
  bool _isLoadMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLastPage = false;
  String _currentStatusFilter = 'PENDING';
  int _totalApprovedOnlineDrivers = 0;
  bool _isLoadingApprovedOnlineDrivers = false;

  RiderVerificationProvider(this._repository);

  List<AdminDriverModel> get drivers => _drivers;
  bool get isLoading => _isLoading;
  bool get isLoadMore => _isLoadMore;
  String? get errorMessage => _errorMessage;
  String get currentStatusFilter => _currentStatusFilter;
  bool get isLastPage => _isLastPage;
  int get totalApprovedOnlineDrivers => _totalApprovedOnlineDrivers;
  bool get isLoadingApprovedOnlineDrivers => _isLoadingApprovedOnlineDrivers;

  /// Fetches the count of drivers with status=APPROVED and online=true.
  Future<void> fetchOnlineApprovedDriverCount() async {
    _isLoadingApprovedOnlineDrivers = true;
    notifyListeners();

    try {
      final result = await _repository.getDrivers(
        page: 0,
        size: 20,
        status: 'APPROVED',
        online: true,
      );
      _totalApprovedOnlineDrivers = result['totalElements'] as int? ?? 0;
    } catch (_) {
      // Keep previous value if request fails
    } finally {
      _isLoadingApprovedOnlineDrivers = false;
      notifyListeners();
    }
  }

  void resetState() {
    _drivers = [];
    _isLoading = false;
    _isLoadMore = false;
    _errorMessage = null;
    _currentPage = 0;
    _isLastPage = false;
    notifyListeners();
  }

  /// Sets the current status filter and fetches drivers from page 0.
  Future<void> setStatusFilter(String status) async {
    if (_currentStatusFilter == status && _drivers.isNotEmpty) return;
    _currentStatusFilter = status;
    await fetchDrivers(isRefresh: true);
  }

  /// Fetches paginated drivers from the remote server.
  Future<void> fetchDrivers({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _isLastPage = false;
      _drivers = [];
    }

    if (_isLastPage) return;

    if (isRefresh || _drivers.isEmpty) {
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
        status: _currentStatusFilter,
      );

      final List<AdminDriverModel> newDrivers = result['drivers'] as List<AdminDriverModel>;
      _isLastPage = result['isLast'] as bool? ?? true;
      
      if (isRefresh) {
        _drivers = newDrivers;
      } else {
        _drivers.addAll(newDrivers);
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

  /// Fetches full driver details by user ID and updates local list.
  Future<AdminDriverModel?> fetchDriverById(int userId) async {
    try {
      final driver = await _repository.getDriverById(userId);
      // Update the local list with full details
      final index = _drivers.indexWhere((d) => d.userId == userId || d.id == userId);
      if (index != -1) {
        _drivers[index] = driver;
        notifyListeners();
      }
      return driver;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
  /// Updates a driver profile from the admin view.
  Future<AdminDriverModel?> updateDriverProfileAdmin({
    required int userId,
    required Map<String, dynamic> updateData,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedDriver = await _repository.updateDriverProfileAdmin(
        userId: userId,
        updateData: updateData,
      );

      final index = _drivers.indexWhere((d) => d.userId == userId || d.id == userId);
      if (index != -1) {
        _drivers[index] = updatedDriver;
        notifyListeners();
      }
      return updatedDriver;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
  /// Updates the approval status of a driver.
  Future<bool> updateDriverStatus(int driverId, String status, {String? rejectionReason}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateDriverStatus(
        driverId: driverId,
        status: status,
        rejectionReason: rejectionReason,
      );

      final targetLocalStatus = (status == 'ACTIVATED') ? 'APPROVED' : status;

      // If the filter status doesn't match the new status, remove it from list
      if (_currentStatusFilter != targetLocalStatus) {
        _drivers.removeWhere((d) => d.id == driverId);
      } else {
        // Otherwise, update the local model's status
        final index = _drivers.indexWhere((d) => d.id == driverId);
        if (index != -1) {
          final old = _drivers[index];
          _drivers[index] = AdminDriverModel(
            id: old.id,
            userId: old.userId,
            name: old.name,
            phone: old.phone,
            userStatus: old.userStatus,
            approvalStatus: targetLocalStatus,
            licenseNumber: old.licenseNumber,
            vehicleNumber: old.vehicleNumber,
            isOnline: old.isOnline,
            rating: old.rating,
            totalTrips: old.totalTrips,
            vehicle: old.vehicle,
            documents: old.documents,
            createdAt: old.createdAt,
          );
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Verifies a specific driver document.
  Future<bool> verifyDriverDocument(int driverId, int documentId, String status, {String? rejectionReason}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.verifyDriverDocument(
        driverId: driverId,
        documentId: documentId,
        status: status,
        rejectionReason: rejectionReason,
      );

      // Locally update the driver's document status in our list
      final driverIndex = _drivers.indexWhere((d) => d.id == driverId);
      if (driverIndex != -1) {
        final driver = _drivers[driverIndex];
        final docList = List<AdminDriverDocumentModel>.from(driver.documents);
        final docIndex = docList.indexWhere((doc) => doc.id == documentId);
        if (docIndex != -1) {
          final oldDoc = docList[docIndex];
          docList[docIndex] = AdminDriverDocumentModel(
            id: oldDoc.id,
            docType: oldDoc.docType,
            fileUrl: oldDoc.fileUrl,
            status: status,
            rejectionReason: rejectionReason,
            uploadedAt: oldDoc.uploadedAt,
          );
          
          _drivers[driverIndex] = AdminDriverModel(
            id: driver.id,
            userId: driver.userId,
            name: driver.name,
            phone: driver.phone,
            userStatus: driver.userStatus,
            approvalStatus: driver.approvalStatus,
            licenseNumber: driver.licenseNumber,
            vehicleNumber: driver.vehicleNumber,
            isOnline: driver.isOnline,
            rating: driver.rating,
            totalTrips: driver.totalTrips,
            vehicle: driver.vehicle,
            documents: docList,
            createdAt: driver.createdAt,
          );
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Sends a custom message/notification to a driver.
  Future<bool> sendMessageToDriver({
    required int driverId,
    required String subject,
    required String message,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.sendMessageToDriver(
        driverId: driverId,
        subject: subject,
        message: message,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
