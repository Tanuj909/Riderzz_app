import 'package:flutter/material.dart';
import 'package:riderzz_app/features/admin/commission/data/repositories/pricing_repository.dart';
import 'package:riderzz_app/core/models/pricing_tier_model.dart';
import 'package:riderzz_app/core/models/pricing_rule_model.dart';

class PricingProvider extends ChangeNotifier {
  final PricingRepository _repository;

  PricingProvider(this._repository);

  List<PricingTierModel> _tiers = [];
  List<PricingTierModel> get tiers => _tiers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPricingTiers(int vehicleTypeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tiers = await _repository.getPricingTiers(vehicleTypeId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPricingTier({
    required int vehicleTypeId,
    required double fromDistance,
    double? toDistance,
    required double baseFare,
    required double perKmRate,
    required double commission,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTier = await _repository.createPricingTier(
        vehicleTypeId: vehicleTypeId,
        fromDistance: fromDistance,
        toDistance: toDistance,
        baseFare: baseFare,
        perKmRate: perKmRate,
        commission: commission,
      );
      _tiers.add(newTier);
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

  Future<bool> updatePricingTier({
    required int tierId,
    required int vehicleTypeId,
    required double fromDistance,
    double? toDistance,
    required double baseFare,
    required double perKmRate,
    required double commission,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updatePricingTier(
        tierId: tierId,
        vehicleTypeId: vehicleTypeId,
        fromDistance: fromDistance,
        toDistance: toDistance,
        baseFare: baseFare,
        perKmRate: perKmRate,
        commission: commission,
      );
      final index = _tiers.indexWhere((t) => t.id == tierId);
      if (index != -1) {
        _tiers[index] = updated;
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

  Future<bool> deletePricingTier(int tierId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deletePricingTier(tierId);
      _tiers.removeWhere((t) => t.id == tierId);
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

  PricingRuleModel? _rule;
  PricingRuleModel? get rule => _rule;

  Future<void> fetchPricingRule() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rule = await _repository.getPricingRule();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePricingRule({
    required double rainMultiplier,
    required double nightMultiplier,
    required double heavyTrafficMultiplier,
    required double fuelMultiplier,
    required double waitingChargePerMinute,
    required bool dynamicPricingEnabled,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rule = await _repository.updatePricingRule(
        rainMultiplier: rainMultiplier,
        nightMultiplier: nightMultiplier,
        heavyTrafficMultiplier: heavyTrafficMultiplier,
        fuelMultiplier: fuelMultiplier,
        waitingChargePerMinute: waitingChargePerMinute,
        dynamicPricingEnabled: dynamicPricingEnabled,
      );
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
