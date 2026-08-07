import 'package:riderzz_app/features/admin/commission/data/datasource/pricing_datasource.dart';
import 'package:riderzz_app/core/models/pricing_tier_model.dart';
import 'package:riderzz_app/core/models/pricing_rule_model.dart';
import 'package:riderzz_app/core/models/time_based_pricing_model.dart';

class PricingRepository {
  final PricingRemoteDataSource _remoteDataSource;

  PricingRepository(this._remoteDataSource);

  Future<List<PricingTierModel>> getPricingTiers(int vehicleTypeId, {int page = 0, int size = 20}) async {
    return await _remoteDataSource.getPricingTiers(vehicleTypeId, page: page, size: size);
  }

  Future<PricingTierModel> createPricingTier({
    required int vehicleTypeId,
    required double fromDistance,
    double? toDistance,
    required double baseFare,
    required double perKmRate,
    required double commission,
    bool fastDeliveryEnabled = false,
    double? fastDeliveryCharge,
  }) async {
    return await _remoteDataSource.createPricingTier(
      vehicleTypeId: vehicleTypeId,
      fromDistance: fromDistance,
      toDistance: toDistance,
      baseFare: baseFare,
      perKmRate: perKmRate,
      commission: commission,
      fastDeliveryEnabled: fastDeliveryEnabled,
      fastDeliveryCharge: fastDeliveryCharge,
    );
  }

  Future<PricingTierModel> updatePricingTier({
    required int tierId,
    required int vehicleTypeId,
    required double fromDistance,
    double? toDistance,
    required double baseFare,
    required double perKmRate,
    required double commission,
    bool fastDeliveryEnabled = false,
    double? fastDeliveryCharge,
  }) async {
    return await _remoteDataSource.updatePricingTier(
      tierId: tierId,
      vehicleTypeId: vehicleTypeId,
      fromDistance: fromDistance,
      toDistance: toDistance,
      baseFare: baseFare,
      perKmRate: perKmRate,
      commission: commission,
      fastDeliveryEnabled: fastDeliveryEnabled,
      fastDeliveryCharge: fastDeliveryCharge,
    );
  }

  Future<void> deletePricingTier(int tierId) async {
    await _remoteDataSource.deletePricingTier(tierId);
  }

  Future<PricingRuleModel> getPricingRule() async {
    return await _remoteDataSource.getPricingRule();
  }

  Future<PricingRuleModel> updatePricingRule({
    required double rainMultiplier,
    required double nightMultiplier,
    required double heavyTrafficMultiplier,
    required double fuelMultiplier,
    required double waitingChargePerMinute,
    required bool dynamicPricingEnabled,
  }) async {
    return await _remoteDataSource.updatePricingRule(
      rainMultiplier: rainMultiplier,
      nightMultiplier: nightMultiplier,
      heavyTrafficMultiplier: heavyTrafficMultiplier,
      fuelMultiplier: fuelMultiplier,
      waitingChargePerMinute: waitingChargePerMinute,
      dynamicPricingEnabled: dynamicPricingEnabled,
    );
  }

  Future<List<TimeBasedPricingModel>> getTimeBasedPricingRules() async {
    return await _remoteDataSource.getTimeBasedPricingRules();
  }

  Future<TimeBasedPricingModel> saveTimeBasedPricingRule({
    required String timeSlot,
    required String startTime,
    required String endTime,
    required double extraCharge,
    required bool enabled,
  }) async {
    return await _remoteDataSource.saveTimeBasedPricingRule(
      timeSlot: timeSlot,
      startTime: startTime,
      endTime: endTime,
      extraCharge: extraCharge,
      enabled: enabled,
    );
  }

  Future<void> deleteTimeBasedPricingRule(int id) async {
    await _remoteDataSource.deleteTimeBasedPricingRule(id);
  }
}

