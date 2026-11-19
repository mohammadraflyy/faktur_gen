import 'dart:typed_data';

import 'package:faktur_gen/models/reminder_model.dart';
import 'package:faktur_gen/pages/document_ready_page.dart';
import 'package:faktur_gen/pages/pdf_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

DocumentReadyPage _page() => DocumentReadyPage(
      title: 'Invoice siap',
      summary: 'Klien A · Rp 1.000',
      shareMessage: 'Halo',
      reminderLabel: 'Ingatkan saya',
      reminder: ReminderModel(
        id: '1',
        contactName: 'Klien A',
        serviceName: 'Desain',
        reminderDate: DateTime(2030, 1, 1),
        reminderHour: 9,
      ),
      preview: PdfPreviewPage(
        title: 'Preview',
        filename: 'test.pdf',
        buildPdf: (_) async => Uint8List(0),
      ),
    );

Future<void> _openReady(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (ctx) => TextButton(
        onPressed: () => Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => _page())),
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('shows the summary and the reminder date, toggle off',
      (tester) async {
    await _openReady(tester);
    expect(find.text('Invoice siap'), findsOneWidget);
    expect(find.text('Klien A · Rp 1.000'), findsOneWidget);
    expect(find.text('1 Jan 2030, 09:00'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse);
  });

  testWidgets('Selesai closes only the ready screen', (tester) async {
    await _openReady(tester);
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(find.text('Invoice siap'), findsNothing);
  });

  testWidgets('Selesai in the PDF view returns to the ready screen',
      (tester) async {
    await _openReady(tester);
    await tester.tap(find.text('Lihat PDF'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Selesai'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Invoice siap'), findsOneWidget);
  });
}
