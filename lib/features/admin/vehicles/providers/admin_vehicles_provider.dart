import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/features/admin/vehicles/data/repositories/admin_vehicles_repository.dart';

class AdminVehiclesProvider extends ChangeNotifier {
  final AdminVehiclesRepository _repository;

  List<VehicleTypeModel> _vehicleTypes = [];
  bool _isLoading = false;
  String? _errorMessage;

  AdminVehiclesProvider(this._repository);

  List<VehicleTypeModel> get vehicleTypes => _vehicleTypes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void resetState() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchVehicleTypes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vehicleTypes = await _repository.getAllVehicleTypes();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  final Map<String, List<VehicleTypeModel>> _categoryVehiclesCache = {};
  Map<String, List<VehicleTypeModel>> get categoryVehiclesCache => _categoryVehiclesCache;

  Future<List<VehicleTypeModel>> fetchVehiclesByCategory(String category, {bool forceRefresh = false}) async {
    if (!forceRefresh && _categoryVehiclesCache.containsKey(category) && _categoryVehiclesCache[category]!.isNotEmpty) {
      return _categoryVehiclesCache[category]!;
    }
    final list = await _repository.getVehicleTypesByCategory(category);
    _categoryVehiclesCache[category] = list;
    return list;
  }

  Future<bool> createVehicleType({
    required String name,
    File? icon,
    required int maxWeightKg,
    required double minimumWalletBalance,
    required bool tollEnabled,
    required bool dynamicPricingEnabled,
    bool active = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newType = await _repository.createVehicleType(
        name: name,
        icon: icon,
        maxWeightKg: maxWeightKg,
        minimumWalletBalance: minimumWalletBalance,
        tollEnabled: tollEnabled,
        dynamicPricingEnabled: dynamicPricingEnabled,
        active: active,
      );
      _vehicleTypes.add(newType);
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

  Future<bool> updateVehicleType({
    required int id,
    required String name,
    File? icon,
    required int maxWeightKg,
    required double minimumWalletBalance,
    required bool tollEnabled,
    required bool dynamicPricingEnabled,
    bool active = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedType = await _repository.updateVehicleType(
        id: id,
        name: name,
        icon: icon,
        maxWeightKg: maxWeightKg,
        minimumWalletBalance: minimumWalletBalance,
        tollEnabled: tollEnabled,
        dynamicPricingEnabled: dynamicPricingEnabled,
        active: active,
      );
      final index = _vehicleTypes.indexWhere((element) => element.id == id);
      if (index != -1) {
        _vehicleTypes[index] = updatedType;
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

  Future<bool> deleteVehicleType(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteVehicleType(id);
      _vehicleTypes.removeWhere((element) => element.id == id);
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

  // --- Registered Vehicles (Driver Vehicles) ---
  
  List<dynamic> _registeredVehicles = [];
  List<dynamic> get registeredVehicles => _registeredVehicles;

  int _regVehiclesPage = 0;
  bool _regVehiclesHasMore = true;
  bool get regVehiclesHasMore => _regVehiclesHasMore;
  bool _isLoadingRegVehicles = false;
  bool get isLoadingRegVehicles => _isLoadingRegVehicles;

  String? _regVehiclesStatusFilter = 'ALL';
  String? get regVehiclesStatusFilter => _regVehiclesStatusFilter;
  
  int? _regVehiclesTypeIdFilter;
  int? get regVehiclesTypeIdFilter => _regVehiclesTypeIdFilter;

  void setRegVehiclesStatusFilter(String status) {
    _regVehiclesStatusFilter = status;
    fetchRegisteredVehicles(isRefresh: true);
  }

  void setRegVehiclesTypeIdFilter(int? typeId) {
    _regVehiclesTypeIdFilter = typeId;
    fetchRegisteredVehicles(isRefresh: true);
  }

  Future<void> fetchRegisteredVehicles({bool isRefresh = false}) async {
    if (isRefresh) {
      _regVehiclesPage = 0;
      _regVehiclesHasMore = true;
      _registeredVehicles.clear();
    }

    if (!_regVehiclesHasMore || _isLoadingRegVehicles) return;

    _isLoadingRegVehicles = true;
    _errorMessage = null;
    // Don't notify listeners if we're just loading next page to avoid flickers,
    // but do notify if refresh to show indicator if needed. 
    if (isRefresh) notifyListeners();

    try {
      final response = await _repository.fetchRegisteredVehicles(
        status: _regVehiclesStatusFilter,
        vehicleTypeId: _regVehiclesTypeIdFilter,
        page: _regVehiclesPage,
        size: 20,
      );

      final List<dynamic> content = response['content'] ?? [];
      final bool last = response['last'] ?? true;

      _registeredVehicles.addAll(content);
      _regVehiclesHasMore = !last;
      _regVehiclesPage++;
      _isLoadingRegVehicles = false;
      notifyListeners();
    } catch (e) {
      _isLoadingRegVehicles = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> updateRegisteredVehicleStatus(int id, String newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateRegisteredVehicleStatus(id, newStatus);
      
      // Update local state if successful
      final index = _registeredVehicles.indexWhere((element) => element['id'] == id);
      if (index != -1) {
        // Since it's dynamic Map, we update it directly
        final Map<String, dynamic> updatedVehicle = Map<String, dynamic>.from(_registeredVehicles[index]);
        updatedVehicle['status'] = newStatus;
        _registeredVehicles[index] = updatedVehicle;
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
