import 'package:flutter/material.dart';
import 'package:riderzz_app/core/network/api_exception.dart';
import 'package:riderzz_app/features/user/saved_routes/data/repositories/saved_route_repository.dart';

class SavedRouteProvider extends ChangeNotifier {
  final SavedRouteRepository _savedRouteRepository;

  List<Map<String, dynamic>> _savedRoutes = [];
  bool _isLoading = false;
  String? _errorMessage;

  SavedRouteProvider(this._savedRouteRepository);

  List<Map<String, dynamic>> get savedRoutes => List.unmodifiable(_savedRoutes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSavedRoutes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _savedRouteRepository.fetchSavedRoutes();
      if (response.success) {
        _savedRoutes = response.data ?? [];
      } else {
        _errorMessage = response.message;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSavedRoute({
    required String routeName,
    required int pickupAddressId,
    required int dropAddressId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _savedRouteRepository.createSavedRoute(
        routeName: routeName,
        pickupAddressId: pickupAddressId,
        dropAddressId: dropAddressId,
      );

      if (response.success) {
        await fetchSavedRoutes();
        return true;
      } else {
        _errorMessage = response.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSavedRoute({
    required int id,
    required String routeName,
    required int pickupAddressId,
    required int dropAddressId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _savedRouteRepository.updateSavedRoute(
        id: id,
        routeName: routeName,
        pickupAddressId: pickupAddressId,
        dropAddressId: dropAddressId,
      );

      if (response.success) {
        await fetchSavedRoutes();
        return true;
      } else {
        _errorMessage = response.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSavedRoute(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _savedRouteRepository.deleteSavedRoute(id);

      if (response.success) {
        await fetchSavedRoutes();
        return true;
      } else {
        _errorMessage = response.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
