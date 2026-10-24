import 'package:riderzz_app/features/user/coupons/data/datasource/customer_coupon_remote_datasource.dart';
import 'package:riderzz_app/features/user/coupons/data/models/customer_coupon_model.dart';

class CustomerCouponRepository {
  final CustomerCouponRemoteDataSource _remoteDataSource;

  CustomerCouponRepository(this._remoteDataSource);

  Future<List<CustomerCouponModel>> fetchCustomerCoupons() {
    return _remoteDataSource.fetchCustomerCoupons();
  }

  Future<Map<String, dynamic>> claimCoupon(int id) {
    return _remoteDataSource.claimCoupon(id);
  }
}
