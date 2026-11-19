import 'dart:typed_data';

import 'package:faktur_gen/pages/pdf_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Selesai closes only the preview and returns true',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () async {
            result = await Navigator.push<bool>(
              ctx,
              MaterialPageRoute(
                builder: (_) => PdfPreviewPage(
                  title: 'Preview',
                  filename: 'test.pdf',
                  buildPdf: (_) async => Uint8List(0),
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Selesai'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('open'), findsOneWidget);
    expect(result, isTrue);
  });
}
