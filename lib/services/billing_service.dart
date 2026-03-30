import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'subscription_service.dart';

class BillingService {
  static const _kProductId = 'faktura_pro_monthly';
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static ProductDetails? _productDetails;

  static Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('[BillingService] Store not available');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (e) => debugPrint('[BillingService] Stream error: $e'),
    );

    // Load product details
    final response = await _iap.queryProductDetails({_kProductId});
    if (response.productDetails.isNotEmpty) {
      _productDetails = response.productDetails.first;
    }
  }

  static ProductDetails? get productDetails => _productDetails;

  static String get priceString =>
      _productDetails?.price ?? 'Rp 29.900/bulan';

  static Future<void> purchasePro() async {
    if (_productDetails == null) {
      debugPrint('[BillingService] Product not loaded');
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: _productDetails!);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  static Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  static void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Activate Pro — set expiry to 30 days from now
        final expires = DateTime.now().add(const Duration(days: 30));
        SubscriptionService.setPro(
          purchase.purchaseID ?? '',
          expires,
        );

        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('[BillingService] Purchase error: ${purchase.error}');
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  static void dispose() {
    _subscription?.cancel();
  }
}
