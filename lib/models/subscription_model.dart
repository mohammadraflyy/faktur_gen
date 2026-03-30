enum SubscriptionTier { free, pro }

class SubscriptionModel {
  SubscriptionTier tier;
  DateTime? expiresAt;
  String? purchaseToken;
  int monthlyDocCount;
  String monthKey; // "2026-03" format

  SubscriptionModel({
    this.tier = SubscriptionTier.free,
    this.expiresAt,
    this.purchaseToken,
    this.monthlyDocCount = 0,
    String? monthKey,
  }) : monthKey = monthKey ?? _currentMonthKey();

  static String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  bool get isPro =>
      tier == SubscriptionTier.pro &&
      expiresAt != null &&
      expiresAt!.isAfter(DateTime.now());

  bool get isExpired =>
      tier == SubscriptionTier.pro &&
      expiresAt != null &&
      expiresAt!.isBefore(DateTime.now());

  /// Reset doc count if month changed
  void checkMonthReset() {
    final current = _currentMonthKey();
    if (monthKey != current) {
      monthKey = current;
      monthlyDocCount = 0;
    }
  }

  Map<String, dynamic> toMap() => {
        'tier': tier.index,
        'expiresAt': expiresAt?.millisecondsSinceEpoch,
        'purchaseToken': purchaseToken,
        'monthlyDocCount': monthlyDocCount,
        'monthKey': monthKey,
      };

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) =>
      SubscriptionModel(
        tier: SubscriptionTier.values[map['tier'] as int? ?? 0],
        expiresAt: map['expiresAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int)
            : null,
        purchaseToken: map['purchaseToken'] as String?,
        monthlyDocCount: map['monthlyDocCount'] as int? ?? 0,
        monthKey: map['monthKey'] as String?,
      );
}
