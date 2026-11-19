import 'package:faktur_gen/widgets/total_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

final _fmt =
    NumberFormat.currency(locale: 'en_US', symbol: 'Rp ', decimalDigits: 0);

Widget _app(TotalBar bar) =>
    MaterialApp(home: Scaffold(bottomNavigationBar: bar));

void main() {
  testWidgets('shows the new total when the notifier changes', (tester) async {
    final total = ValueNotifier<double>(1000);
    await tester.pumpWidget(_app(TotalBar(
        total: total, currency: _fmt, actionLabel: 'Buat PDF', onAction: () {})));
    expect(find.text('Rp 1,000'), findsOneWidget);

    total.value = 2500;
    await tester.pumpAndSettle();
    expect(find.text('Rp 2,500'), findsOneWidget);
    expect(find.text('Rp 1,000'), findsNothing);
  });

  testWidgets('tapping the action calls onAction', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(TotalBar(
        total: ValueNotifier(0),
        currency: _fmt,
        actionLabel: 'Buat PDF',
        onAction: () => taps++)));
    await tester.tap(find.text('Buat PDF'));
    expect(taps, 1);
  });

  testWidgets('busy disables the action and shows progress', (tester) async {
    await tester.pumpWidget(_app(TotalBar(
        total: ValueNotifier(0),
        currency: _fmt,
        actionLabel: 'Buat PDF',
        onAction: () {},
        busy: true)));
    expect(find.text('Membuat…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
  });
}
