import 'package:flutter/material.dart';
import 'package:riderzz_app/features/admin/commission/data/repositories/commission_repository.dart';
import 'package:riderzz_app/core/models/commission_config_model.dart';

class CommissionProvider extends ChangeNotifier {
  final CommissionRepository _repository;

  CommissionProvider(this._repository);

  List<CommissionConfigModel> _configs = [];
  List<CommissionConfigModel> get configs => _configs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCommissionConfigs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _configs = await _repository.getCommissionConfigs();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCommissionConfig({
    required int vehicleTypeId,
    required double commissionPercent,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newConfig = await _repository.createCommissionConfig(
        vehicleTypeId: vehicleTypeId,
        commissionPercent: commissionPercent,
      );
      _configs.add(newConfig);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> updateCommissionConfig({
    required int configId,
    required int vehicleTypeId,
    required double commissionPercent,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateCommissionConfig(
        configId: configId,
        vehicleTypeId: vehicleTypeId,
        commissionPercent: commissionPercent,
      );
      final index = _configs.indexWhere((c) => c.id == configId);
      if (index != -1) {
        _configs[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> deleteCommissionConfig(int configId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteCommissionConfig(configId);
      _configs.removeWhere((c) => c.id == configId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }
}
