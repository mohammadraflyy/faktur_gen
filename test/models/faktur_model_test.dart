import 'package:flutter_test/flutter_test.dart';
import 'package:faktur_gen/models/faktur_model.dart';
import 'package:faktur_gen/models/settings_model.dart';

void main() {
  group('ItemFaktur', () {
    test('default values', () {
      final item = ItemFaktur();
      expect(item.namaBarang, '');
      expect(item.kuantitas, 1);
      expect(item.satuan, 'Unit');
      expect(item.hargaSatuan, 0);
      expect(item.jumlah, 0);
    });

    test('jumlah = kuantitas * hargaSatuan', () {
      final item = ItemFaktur(kuantitas: 3, hargaSatuan: 50000);
      expect(item.jumlah, 150000);
    });

    test('jumlah with fractional quantity', () {
      final item = ItemFaktur(kuantitas: 2.5, hargaSatuan: 10000);
      expect(item.jumlah, 25000);
    });

    test('jumlah is zero when price is zero', () {
      final item = ItemFaktur(kuantitas: 10, hargaSatuan: 0);
      expect(item.jumlah, 0);
    });
  });

  group('FakturModel', () {
    test('default values', () {
      final f = FakturModel();
      expect(f.nomorFaktur, '');
      expect(f.tanggal, isA<DateTime>());
      expect(f.jatuhTempo, isNull);
      expect(f.items.length, 1);
      expect(f.taxRate, 11);
      expect(f.currency, 'IDR');
      expect(f.bankAccounts, isEmpty);
    });

    test('totalDpp sums all item jumlah', () {
      final f = FakturModel(items: [
        ItemFaktur(kuantitas: 2, hargaSatuan: 100000),
        ItemFaktur(kuantitas: 1, hargaSatuan: 50000),
      ]);
      expect(f.totalDpp, 250000);
    });

    test('totalPpn with 11% tax', () {
      final f = FakturModel(
        taxRate: 11,
        items: [ItemFaktur(kuantitas: 1, hargaSatuan: 1000000)],
      );
      expect(f.totalDpp, 1000000);
      expect(f.totalPpn, 110000);
      expect(f.totalTagihan, 1110000);
    });

    test('totalPpn with 0% tax', () {
      final f = FakturModel(
        taxRate: 0,
        items: [ItemFaktur(kuantitas: 1, hargaSatuan: 500000)],
      );
      expect(f.totalPpn, 0);
      expect(f.totalTagihan, 500000);
    });

    test('totalPpn with custom tax rate', () {
      final f = FakturModel(
        taxRate: 12,
        items: [ItemFaktur(kuantitas: 1, hargaSatuan: 1000000)],
      );
      expect(f.totalPpn, 120000);
      expect(f.totalTagihan, 1120000);
    });

    test('totalDpp with empty items returns 0', () {
      final f = FakturModel(items: []);
      expect(f.totalDpp, 0);
      expect(f.totalPpn, 0);
      expect(f.totalTagihan, 0);
    });

    test('multiple items accumulation', () {
      final f = FakturModel(
        taxRate: 10,
        items: [
          ItemFaktur(namaBarang: 'A', kuantitas: 5, hargaSatuan: 20000),
          ItemFaktur(namaBarang: 'B', kuantitas: 3, hargaSatuan: 15000),
          ItemFaktur(namaBarang: 'C', kuantitas: 1, hargaSatuan: 100000),
        ],
      );
      // 100000 + 45000 + 100000 = 245000
      expect(f.totalDpp, 245000);
      expect(f.totalPpn, 24500);
      expect(f.totalTagihan, 269500);
    });
  });
}
