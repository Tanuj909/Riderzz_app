import 'package:flutter/material.dart';
import 'package:riderzz_app/features/admin/vehicles/data/models/admin_vehicle_model.dart';
import 'package:riderzz_app/features/admin/vehicles/data/repositories/admin_vehicles_list_repository.dart';

class AdminVehiclesListProvider extends ChangeNotifier {
  final AdminVehiclesListRepository _repository;

  AdminVehiclesListProvider(this._repository);

  List<AdminVehicleModel> _vehicles = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AdminVehicleModel> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchVehicles({String? status, int? vehicleTypeId, bool isRefresh = false}) async {
    if (!isRefresh && _vehicles.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    if (isRefresh) {
      _vehicles.clear();
    }
    notifyListeners();

    try {
      final list = await _repository.getAllVehicles(status: status, vehicleTypeId: vehicleTypeId);
      _vehicles = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<AdminVehicleModel?> fetchVehicleById(int id) async {
    try {
      return await _repository.getVehicleById(id);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
