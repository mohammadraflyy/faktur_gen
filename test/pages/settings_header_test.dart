import 'package:faktur_gen/models/settings_model.dart';
import 'package:faktur_gen/models/subscription_model.dart';
import 'package:faktur_gen/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(SubscriptionModel sub, {VoidCallback? onUpgrade}) => MaterialApp(
      home: Scaffold(
        body: SettingsHeader(
          settings: SettingsModel(namaToko: 'Toko Maju'),
          sub: sub,
          onUpgrade: onUpgrade ?? () {},
        ),
      ),
    );

double? _barValue(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
    .value;

void main() {
  testWidgets('free plan shows usage, a thin bar and the Pro link',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
        _app(SubscriptionModel(monthlyDocCount: 12), onUpgrade: () => taps++));
    expect(find.text('Toko Maju'), findsOneWidget);
    expect(find.text('Gratis · 12 dari 30 dokumen bulan ini'), findsOneWidget);
    expect(_barValue(tester), closeTo(0.4, 1e-9));
    await tester.tap(find.text('Pro'));
    expect(taps, 1);
  });

  testWidgets('bar stays full past the limit', (tester) async {
    await tester.pumpWidget(_app(SubscriptionModel(monthlyDocCount: 45)));
    expect(_barValue(tester), 1);
  });

  testWidgets('pro plan hides the bar and the link', (tester) async {
    await tester.pumpWidget(_app(SubscriptionModel(
      tier: SubscriptionTier.pro,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    )));
    expect(find.text('Pro · dokumen tak terbatas'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Pro'), findsNothing);
  });
}
