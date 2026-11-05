import 'package:flutter/material.dart';
import 'package:riderzz_app/core/models/vehicle_type_model.dart';
import 'package:riderzz_app/features/vehicle/data/repositories/vehicle_repository.dart';

class VehicleProvider extends ChangeNotifier {
  final VehicleRepository _repository;

  List<VehicleTypeModel> _vehicleTypes = [];
  bool _isLoading = false;
  String? _errorMessage;

  VehicleProvider(this._repository);

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
}

