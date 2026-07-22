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

  Future<bool> createVehicleType({
    required String name,
    required String iconUrl,
    required int maxWeightKg,
    required double minimumWalletBalance,
    required bool tollEnabled,
    required bool dynamicPricingEnabled,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newType = await _repository.createVehicleType(
        name: name,
        iconUrl: iconUrl,
        maxWeightKg: maxWeightKg,
        minimumWalletBalance: minimumWalletBalance,
        tollEnabled: tollEnabled,
        dynamicPricingEnabled: dynamicPricingEnabled,
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
    required String iconUrl,
    required int maxWeightKg,
    required double minimumWalletBalance,
    required bool tollEnabled,
    required bool dynamicPricingEnabled,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedType = await _repository.updateVehicleType(
        id: id,
        name: name,
        iconUrl: iconUrl,
        maxWeightKg: maxWeightKg,
        minimumWalletBalance: minimumWalletBalance,
        tollEnabled: tollEnabled,
        dynamicPricingEnabled: dynamicPricingEnabled,
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
}
