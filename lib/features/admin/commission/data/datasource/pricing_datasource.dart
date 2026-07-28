import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/models/pricing_tier_model.dart';
import 'package:riderzz_app/core/models/pricing_rule_model.dart';

class PricingRemoteDataSource {
  final ApiClient _apiClient;

  PricingRemoteDataSource(this._apiClient);

  Future<List<PricingTierModel>> getPricingTiers(int vehicleTypeId, {int page = 0, int size = 20}) async {
    final response = await _apiClient.get(
      '/admin/pricing-tiers/vehicle-type/$vehicleTypeId',
      queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
      },
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final dynamic rawData = resBody['data'];
    List<dynamic> list = [];
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map && rawData['content'] is List) {
      list = rawData['content'] as List;
    }
    return list.map((json) => PricingTierModel.fromJson(Map<String, dynamic>.from(json))).toList();
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
    final Map<String, dynamic> body = {
      'vehicleTypeId': vehicleTypeId,
      'fromDistance': fromDistance,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'commission': commission,
      'fastDeliveryEnabled': fastDeliveryEnabled,
    };
    if (toDistance != null) {
      body['toDistance'] = toDistance;
    }
    if (fastDeliveryCharge != null) {
      body['fastDeliveryCharge'] = fastDeliveryCharge;
    }

    final response = await _apiClient.post(
      '/admin/pricing-tiers',
      data: body,
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return PricingTierModel.fromJson(data);
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
    final Map<String, dynamic> body = {
      'vehicleTypeId': vehicleTypeId,
      'fromDistance': fromDistance,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'commission': commission,
      'fastDeliveryEnabled': fastDeliveryEnabled,
    };
    if (toDistance != null) {
      body['toDistance'] = toDistance;
    }
    if (fastDeliveryCharge != null) {
      body['fastDeliveryCharge'] = fastDeliveryCharge;
    }

    final response = await _apiClient.put(
      '/admin/pricing-tiers/$tierId',
      data: body,
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return PricingTierModel.fromJson(data);
  }

  Future<void> deletePricingTier(int tierId) async {
    await _apiClient.delete('/admin/pricing-tiers/$tierId');
  }

  Future<PricingRuleModel> getPricingRule() async {
    final response = await _apiClient.get('/pricing/rule');
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return PricingRuleModel.fromJson(data);
  }

  Future<PricingRuleModel> updatePricingRule({
    required double rainMultiplier,
    required double nightMultiplier,
    required double heavyTrafficMultiplier,
    required double fuelMultiplier,
    required double waitingChargePerMinute,
    required bool dynamicPricingEnabled,
  }) async {
    final response = await _apiClient.put(
      '/pricing/rule',
      data: {
        'rainMultiplier': rainMultiplier,
        'nightMultiplier': nightMultiplier,
        'heavyTrafficMultiplier': heavyTrafficMultiplier,
        'fuelMultiplier': fuelMultiplier,
        'waitingChargePerMinute': waitingChargePerMinute,
        'dynamicPricingEnabled': dynamicPricingEnabled,
      },
    );
    final Map<String, dynamic> resBody = Map<String, dynamic>.from(response.data);
    final Map<String, dynamic> data = Map<String, dynamic>.from(resBody['data'] ?? {});
    return PricingRuleModel.fromJson(data);
  }
}
