import 'package:flutter_test/flutter_test.dart';
import 'package:faktur_gen/models/struk_model.dart';

void main() {
  group('MetodeBayar', () {
    test('labels are correct', () {
      expect(MetodeBayar.tunai.label, 'Tunai');
      expect(MetodeBayar.transfer.label, 'Transfer');
      expect(MetodeBayar.debit.label, 'Kartu Debit');
      expect(MetodeBayar.kredit.label, 'Kartu Kredit');
      expect(MetodeBayar.qris.label, 'QRIS');
    });
  });

  group('ItemStruk', () {
    test('default values', () {
      final item = ItemStruk();
      expect(item.nama, '');
      expect(item.kuantitas, 1);
      expect(item.satuan, 'pcs');
      expect(item.hargaSatuan, 0);
      expect(item.diskon, 0);
      expect(item.subtotal, 0);
    });

    test('subtotal = (qty * harga) - diskon', () {
      final item = ItemStruk(kuantitas: 3, hargaSatuan: 25000, diskon: 5000);
      expect(item.subtotal, 70000); // 75000 - 5000
    });

    test('subtotal without discount', () {
      final item = ItemStruk(kuantitas: 2, hargaSatuan: 50000);
      expect(item.subtotal, 100000);
    });

    test('subtotal can go negative with large discount', () {
      final item = ItemStruk(kuantitas: 1, hargaSatuan: 10000, diskon: 15000);
      expect(item.subtotal, -5000);
    });
  });

  group('StrukModel', () {
    test('default values', () {
      final s = StrukModel();
      expect(s.namaToko, '');
      expect(s.nomorStruk, '');
      expect(s.tanggal, isA<DateTime>());
      expect(s.items.length, 1);
      expect(s.diskon, 0);
      expect(s.metodeBayar, MetodeBayar.tunai);
      expect(s.jumlahBayar, 0);
    });

    test('subtotal sums all item subtotals', () {
      final s = StrukModel(items: [
        ItemStruk(kuantitas: 2, hargaSatuan: 30000),
        ItemStruk(kuantitas: 1, hargaSatuan: 50000, diskon: 5000),
      ]);
      expect(s.subtotal, 105000); // 60000 + 45000
    });

    test('total = subtotal - global diskon', () {
      final s = StrukModel(
        items: [ItemStruk(kuantitas: 1, hargaSatuan: 100000)],
        diskon: 10000,
      );
      expect(s.subtotal, 100000);
      expect(s.total, 90000);
    });

    test('kembalian for tunai when bayar >= total', () {
      final s = StrukModel(
        items: [ItemStruk(kuantitas: 1, hargaSatuan: 75000)],
        metodeBayar: MetodeBayar.tunai,
        jumlahBayar: 100000,
      );
      expect(s.total, 75000);
      expect(s.kembalian, 25000);
    });

    test('kembalian is 0 when bayar < total', () {
      final s = StrukModel(
        items: [ItemStruk(kuantitas: 1, hargaSatuan: 75000)],
        metodeBayar: MetodeBayar.tunai,
        jumlahBayar: 50000,
      );
      expect(s.kembalian, 0);
    });

    test('kembalian is 0 for non-tunai methods', () {
      for (final method in [
        MetodeBayar.transfer,
        MetodeBayar.debit,
        MetodeBayar.kredit,
      ]) {
        final s = StrukModel(
          items: [ItemStruk(kuantitas: 1, hargaSatuan: 50000)],
          metodeBayar: method,
          jumlahBayar: 100000,
        );
        expect(s.kembalian, 0, reason: '${method.label} should have 0 kembalian');
      }
    });

    test('kembalian exact payment', () {
      final s = StrukModel(
        items: [ItemStruk(kuantitas: 2, hargaSatuan: 25000)],
        metodeBayar: MetodeBayar.tunai,
        jumlahBayar: 50000,
      );
      expect(s.kembalian, 0);
    });

    test('total with item discount + global discount', () {
      final s = StrukModel(
        items: [
          ItemStruk(kuantitas: 2, hargaSatuan: 50000, diskon: 10000),
          ItemStruk(kuantitas: 1, hargaSatuan: 30000),
        ],
        diskon: 5000,
      );
      // item1: (2*50000) - 10000 = 90000
      // item2: (1*30000) = 30000
      // subtotal = 120000
      // total = 120000 - 5000 = 115000
      expect(s.subtotal, 120000);
      expect(s.total, 115000);
    });

    test('empty items give zero totals', () {
      final s = StrukModel(items: []);
      expect(s.subtotal, 0);
      expect(s.total, 0);
      expect(s.kembalian, 0);
    });
  });

  group('cashChange', () {
    test('null until an amount is entered', () {
      expect(cashChange(total: 85000, paid: 0), isNull);
    });

    test('change when paid more than the total', () {
      expect(cashChange(total: 85000, paid: 100000), 15000);
    });

    test('zero for the exact amount', () {
      expect(cashChange(total: 85000, paid: 85000), 0);
    });

    test('negative when the payment is short', () {
      expect(cashChange(total: 85000, paid: 50000), -35000);
    });
  });

  group('paymentSegment', () {
    test('both card values highlight the card segment', () {
      expect(paymentSegment(MetodeBayar.debit), MetodeBayar.debit);
      expect(paymentSegment(MetodeBayar.kredit), MetodeBayar.debit);
    });

    test('other methods map to themselves', () {
      expect(paymentSegment(MetodeBayar.tunai), MetodeBayar.tunai);
      expect(paymentSegment(MetodeBayar.transfer), MetodeBayar.transfer);
      expect(paymentSegment(MetodeBayar.qris), MetodeBayar.qris);
    });
  });
}
