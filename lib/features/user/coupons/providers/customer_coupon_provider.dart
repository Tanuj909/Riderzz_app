import 'package:flutter/material.dart';
import 'package:riderzz_app/features/user/coupons/data/models/customer_coupon_model.dart';
import 'package:riderzz_app/features/user/coupons/data/repositories/customer_coupon_repository.dart';
import 'package:riderzz_app/features/user/wallet/providers/customer_wallet_provider.dart';

class CustomerCouponProvider extends ChangeNotifier {
  final CustomerCouponRepository _repository;

  CustomerCouponProvider(this._repository);

  List<CustomerCouponModel> _coupons = [];
  bool _isLoading = false;
  int? _claimingCouponId;
  String? _errorMessage;
  String? _successMessage;
  double? _lastClaimedAmount;

  List<CustomerCouponModel> get coupons => _coupons;
  bool get isLoading => _isLoading;
  int? get claimingCouponId => _claimingCouponId;
  bool isClaiming(int id) => _claimingCouponId == id;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  double? get lastClaimedAmount => _lastClaimedAmount;

  /// All coupons where status == 'AVAILABLE' and claimedAt == null
  List<CustomerCouponModel> get availableCoupons =>
      _coupons.where((c) => c.isAvailable).toList();

  /// All coupons where status == 'CLAIMED' or claimedAt != null
  List<CustomerCouponModel> get claimedCoupons =>
      _coupons.where((c) => c.isClaimed).toList();

  /// Count of available coupons
  int get availableCouponsCount => availableCoupons.length;

  /// Fetch coupons from backend
  Future<void> fetchCoupons({bool force = false}) async {
    if (_coupons.isNotEmpty && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _repository.fetchCustomerCoupons();
      _coupons = fetched;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Claim a coupon
  Future<Map<String, dynamic>?> claimCoupon(
    int id, {
    CustomerWalletProvider? walletProvider,
  }) async {
    _claimingCouponId = id;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _repository.claimCoupon(id);
      final double claimedAmount = (result['amount'] as num?)?.toDouble() ?? 0.0;
      _lastClaimedAmount = claimedAmount;
      _successMessage = result['message']?.toString() ?? 'Reward claimed successfully';

      // Update local state for immediate reactive UI
      final index = _coupons.indexWhere((c) => c.id == id);
      if (index != -1) {
        _coupons[index] = _coupons[index].copyWith(
          status: 'CLAIMED',
          claimedAt: DateTime.now().toIso8601String(),
          rewardAmount: claimedAmount > 0 ? claimedAmount : _coupons[index].rewardAmount,
        );
      }

      // Automatically refresh customer wallet balance
      try {
        await walletProvider?.fetchCustomerWallet(force: true);
      } catch (_) {}

      _claimingCouponId = null;
      notifyListeners();
      return result;
    } catch (e) {
      _claimingCouponId = null;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }
}
