import 'package:faktur_gen/models/faktur_model.dart';
import 'package:faktur_gen/widgets/item_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

final _fmt =
    NumberFormat.currency(locale: 'en_US', symbol: 'Rp ', decimalDigits: 0);

/// Opens the sheet on a phone-sized screen; the returned function reads
/// the result once the sheet has closed.
Future<ItemEditResult? Function()> _open(WidgetTester tester, ItemFaktur item,
    {bool isNew = false, double? discount}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  ItemEditResult? result;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              result = await showItemEditSheet(context,
                  item: item, currency: _fmt, isNew: isNew, discount: discount);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => result;
}

void main() {
  testWidgets('save returns the edited item with stepped quantity',
      (tester) async {
    final read =
        await _open(tester, ItemFaktur(namaBarang: 'Desain', hargaSatuan: 1000));

    await tester.tap(find.byTooltip('Tambah jumlah'));
    await tester.pump();
    expect(find.text('Simpan · Rp 2,000'), findsOneWidget);

    await tester.tap(find.text('Simpan · Rp 2,000'));
    await tester.pumpAndSettle();
    final result = read();
    expect(result, isNotNull);
    expect(result!.deleted, isFalse);
    expect(result.item!.namaBarang, 'Desain');
    expect(result.item!.kuantitas, 2);
    expect(result.item!.hargaSatuan, 1000);
  });

  testWidgets('quantity cannot go below 1', (tester) async {
    await _open(tester, ItemFaktur(namaBarang: 'A', hargaSatuan: 10));
    final less = tester.widget<IconButton>(find.ancestor(
        of: find.byIcon(Icons.remove), matching: find.byType(IconButton)));
    expect(less.onPressed, isNull);
  });

  testWidgets('typing a price updates the subtotal on the button',
      (tester) async {
    await _open(tester, ItemFaktur(namaBarang: 'A'), isNew: true);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Harga satuan'), '2500');
    await tester.pump();
    expect(find.text('Simpan · Rp 2,500'), findsOneWidget);
  });

  testWidgets('dotted price is read as digits', (tester) async {
    await _open(tester, ItemFaktur(namaBarang: 'A'), isNew: true);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Harga satuan'), '2.500');
    await tester.pump();
    expect(find.text('Simpan · Rp 2,500'), findsOneWidget);
  });

  testWidgets('fractional price is prefilled rounded', (tester) async {
    await _open(tester, ItemFaktur(namaBarang: 'A', hargaSatuan: 1500.5));
    expect(find.text('Simpan · Rp 1,501'), findsOneWidget);
  });

  testWidgets('empty name blocks save', (tester) async {
    final read = await _open(tester, ItemFaktur(), isNew: true);
    await tester.tap(find.text('Simpan · Rp 0'));
    await tester.pumpAndSettle();
    expect(find.text('Nama item wajib diisi'), findsOneWidget);
    expect(read(), isNull);
  });

  testWidgets('delete returns a deleted result', (tester) async {
    final read = await _open(tester, ItemFaktur(namaBarang: 'A'));
    await tester.tap(find.text('Hapus item'));
    await tester.pumpAndSettle();
    expect(read()?.deleted, isTrue);
  });

  testWidgets('new items have no delete button', (tester) async {
    await _open(tester, ItemFaktur(), isNew: true);
    expect(find.text('Hapus item'), findsNothing);
  });

  testWidgets('no discount field unless the caller asks for one',
      (tester) async {
    await _open(tester, ItemFaktur(namaBarang: 'A', hargaSatuan: 10));
    expect(find.text('Diskon item'), findsNothing);
  });

  testWidgets('discount lowers the subtotal and is returned', (tester) async {
    final read = await _open(
        tester, ItemFaktur(namaBarang: 'Kopi', hargaSatuan: 25000),
        discount: 0);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Diskon item'), '5000');
    await tester.pump();
    await tester.tap(find.text('Simpan · Rp 20,000'));
    await tester.pumpAndSettle();

    final result = read();
    expect(result!.discount, 5000);
    expect(result.item!.hargaSatuan, 25000);
  });
}
