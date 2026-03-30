import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

class SubscriptionService {
  static const _kTier = 's_sub_tier';
  static const _kExpires = 's_sub_expires';
  static const _kDocCount = 's_sub_doc_count';
  static const _kMonthKey = 's_sub_month_key';
  static const _kPurchaseToken = 's_sub_token';

  static const freeMonthlyLimit = 30;

  static Future<SubscriptionModel> load() async {
    if (AuthService.isLoggedIn) {
      try {
        final doc = await FirestoreService.metaDoc('subscription').get();
        if (doc.exists) {
          final model = SubscriptionModel.fromMap(doc.data()!);
          model.checkMonthReset();
          await _saveLocal(model);
          return model;
        }
      } catch (e) {
        debugPrint('[SubscriptionService] Firestore load error: $e');
      }
    }
    return _loadLocal();
  }

  static Future<SubscriptionModel> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final model = SubscriptionModel(
      tier: SubscriptionTier.values[prefs.getInt(_kTier) ?? 0],
      expiresAt: prefs.getInt(_kExpires) != null
          ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt(_kExpires)!)
          : null,
      purchaseToken: prefs.getString(_kPurchaseToken),
      monthlyDocCount: prefs.getInt(_kDocCount) ?? 0,
      monthKey: prefs.getString(_kMonthKey),
    );
    model.checkMonthReset();
    return model;
  }

  static Future<void> _save(SubscriptionModel model) async {
    await _saveLocal(model);
    if (AuthService.isLoggedIn) {
      try {
        await FirestoreService.metaDoc('subscription').set(model.toMap());
      } catch (e) {
        debugPrint('[SubscriptionService] Firestore save error: $e');
      }
    }
  }

  static Future<void> _saveLocal(SubscriptionModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTier, model.tier.index);
    if (model.expiresAt != null) {
      await prefs.setInt(_kExpires, model.expiresAt!.millisecondsSinceEpoch);
    }
    if (model.purchaseToken != null) {
      await prefs.setString(_kPurchaseToken, model.purchaseToken!);
    }
    await prefs.setInt(_kDocCount, model.monthlyDocCount);
    await prefs.setString(_kMonthKey, model.monthKey);
  }

  static Future<bool> isPro() async {
    final model = await load();
    return model.isPro;
  }

  static Future<bool> canCreateDocument() async {
    final model = await load();
    if (model.isPro) return true;
    return model.monthlyDocCount < freeMonthlyLimit;
  }

  static Future<int> remainingDocuments() async {
    final model = await load();
    if (model.isPro) return -1; // unlimited
    return freeMonthlyLimit - model.monthlyDocCount;
  }

  static Future<void> incrementDocCount() async {
    final model = await load();
    model.monthlyDocCount++;
    await _save(model);
  }

  static Future<void> setPro(String purchaseToken, DateTime expires) async {
    final model = await load();
    model.tier = SubscriptionTier.pro;
    model.purchaseToken = purchaseToken;
    model.expiresAt = expires;
    await _save(model);
  }

  static Future<void> setFree() async {
    final model = await load();
    model.tier = SubscriptionTier.free;
    model.expiresAt = null;
    model.purchaseToken = null;
    await _save(model);
  }

  /// Redeem a code for lifetime Pro.
  /// Returns true if the code is valid.
  static Future<bool> redeemCode(String code) async {
    // Valid codes stored in Firestore at redeemCodes/{code}
    // Each code has: { used: bool, type: 'lifetime' }
    if (!AuthService.isLoggedIn) return false;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('redeemCodes')
          .doc(code.trim().toUpperCase());
      final doc = await docRef.get();

      if (!doc.exists) return false;
      final data = doc.data()!;
      if (data['used'] == true) return false;

      // Mark code as used
      await docRef.update({
        'used': true,
        'usedBy': AuthService.uid,
        'usedAt': FieldValue.serverTimestamp(),
      });

      // Activate lifetime Pro (100 years)
      await setPro(
        'redeem_$code',
        DateTime.now().add(const Duration(days: 36500)),
      );
      return true;
    } catch (e) {
      debugPrint('[SubscriptionService] Redeem error: $e');
      return false;
    }
  }
}
