import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/network/api_exception.dart';
import 'package:riderzz_app/features/user/coupons/data/models/customer_coupon_model.dart';

class CustomerCouponRemoteDataSource {
  final ApiClient _apiClient;

  CustomerCouponRemoteDataSource(this._apiClient);

  /// Fetch all coupons for the logged-in customer
  Future<List<CustomerCouponModel>> fetchCustomerCoupons() async {
    try {
      final response = await _apiClient.get(ApiConstants.customerCoupons);
      final rawData = response.data;

      List listData = [];
      if (rawData is List) {
        listData = rawData;
      } else if (rawData is Map) {
        if (rawData['data'] is List) {
          listData = rawData['data'] as List;
        } else if (rawData['coupons'] is List) {
          listData = rawData['coupons'] as List;
        }
      }

      return listData
          .map((item) => CustomerCouponModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  /// Claim a coupon by id
  /// Returns response map with 'message' and 'amount'
  Future<Map<String, dynamic>> claimCoupon(int id) async {
    try {
      final response = await _apiClient.post(ApiConstants.customerCouponClaim(id));
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return {'message': 'Coupon claimed successfully'};
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }
}
