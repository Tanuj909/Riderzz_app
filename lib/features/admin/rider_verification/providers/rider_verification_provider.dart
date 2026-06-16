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

  RiderVerificationProvider(this._repository);

  List<AdminDriverModel> get drivers => _drivers;
  bool get isLoading => _isLoading;
  bool get isLoadMore => _isLoadMore;
  String? get errorMessage => _errorMessage;
  String get currentStatusFilter => _currentStatusFilter;
  bool get isLastPage => _isLastPage;

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

      // If the filter status doesn't match the new status, remove it from list
      if (_currentStatusFilter != status) {
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
            approvalStatus: status,
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
}
