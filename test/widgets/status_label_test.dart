import 'package:faktur_gen/widgets/status_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a dot and the text in the status color', (tester) async {
    const red = Color(0xFFB91C1C);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatusLabel(text: 'lewat 5 hari', color: red)),
    ));

    final text = tester.widget<Text>(find.text('lewat 5 hari'));
    expect(text.style?.color, red);

    final dot = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).shape == BoxShape.circle &&
        (w.decoration as BoxDecoration).color == red);
    expect(dot, findsOneWidget);
  });
}
