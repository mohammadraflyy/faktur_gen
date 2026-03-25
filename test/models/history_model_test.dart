import 'package:flutter_test/flutter_test.dart';
import 'package:faktur_gen/models/history_model.dart';

void main() {
  group('HistoryItem', () {
    test('serialization roundtrip', () {
      final item = HistoryItem(
        nama: 'Widget',
        deskripsi: 'A cool widget',
        kuantitas: 3,
        satuan: 'pcs',
        hargaSatuan: 15000,
        subtotal: 45000,
        diskon: 2000,
      );
      final map = item.toMap();
      final item2 = HistoryItem.fromMap(map);
      expect(item2.nama, 'Widget');
      expect(item2.deskripsi, 'A cool widget');
      expect(item2.kuantitas, 3);
      expect(item2.satuan, 'pcs');
      expect(item2.hargaSatuan, 15000);
      expect(item2.subtotal, 45000);
      expect(item2.diskon, 2000);
    });

    test('fromMap with missing fields uses defaults', () {
      final item = HistoryItem.fromMap({'nama': null});
      expect(item.nama, '');
      expect(item.kuantitas, 0);
      expect(item.diskon, 0);
    });
  });

  group('HistoryEntry', () {
    test('serialization roundtrip', () {
      final now = DateTime.now();
      final entry = HistoryEntry(
        id: '123',
        docType: DocType.invoice,
        nomorDokumen: 'INV-001',
        namaKlien: 'PT ABC',
        totalAmount: 1110000,
        tanggalDokumen: now,
        createdAt: now,
        paymentStatus: PaymentStatus.paid,
        items: [
          HistoryItem(
            nama: 'Service A',
            kuantitas: 1,
            satuan: 'Unit',
            hargaSatuan: 1000000,
            subtotal: 1000000,
          ),
        ],
        catatan: 'Test note',
        totalDpp: 1000000,
        totalPpn: 110000,
        taxRate: 11,
        currency: 'IDR',
      );

      final map = entry.toMap();
      final entry2 = HistoryEntry.fromMap(map);

      expect(entry2.id, '123');
      expect(entry2.docType, DocType.invoice);
      expect(entry2.nomorDokumen, 'INV-001');
      expect(entry2.namaKlien, 'PT ABC');
      expect(entry2.totalAmount, 1110000);
      expect(entry2.paymentStatus, PaymentStatus.paid);
      expect(entry2.items.length, 1);
      expect(entry2.items[0].nama, 'Service A');
      expect(entry2.catatan, 'Test note');
      expect(entry2.totalDpp, 1000000);
      expect(entry2.totalPpn, 110000);
      expect(entry2.taxRate, 11);
      expect(entry2.currency, 'IDR');
    });

    test('struk-specific fields serialize', () {
      final now = DateTime.now();
      final entry = HistoryEntry(
        id: '456',
        docType: DocType.struk,
        nomorDokumen: 'STR-001',
        namaKlien: 'Kasir',
        totalAmount: 50000,
        tanggalDokumen: now,
        createdAt: now,
        namaToko: 'Toko Maju',
        alamatToko: 'Jl. Sudirman',
        namaKasir: 'Budi',
        diskon: 5000,
        metodeBayar: 'Tunai',
        jumlahBayar: 100000,
        kembalian: 50000,
      );

      final map = entry.toMap();
      final entry2 = HistoryEntry.fromMap(map);

      expect(entry2.docType, DocType.struk);
      expect(entry2.namaToko, 'Toko Maju');
      expect(entry2.namaKasir, 'Budi');
      expect(entry2.diskon, 5000);
      expect(entry2.metodeBayar, 'Tunai');
      expect(entry2.jumlahBayar, 100000);
      expect(entry2.kembalian, 50000);
    });

    test('default payment status is unpaid', () {
      final entry = HistoryEntry(
        id: '1',
        docType: DocType.invoice,
        nomorDokumen: 'INV-001',
        namaKlien: '',
        totalAmount: 0,
        tanggalDokumen: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(entry.paymentStatus, PaymentStatus.unpaid);
    });

    test('jatuhTempo null serialization', () {
      final entry = HistoryEntry(
        id: '1',
        docType: DocType.invoice,
        nomorDokumen: 'INV-001',
        namaKlien: '',
        totalAmount: 0,
        tanggalDokumen: DateTime.now(),
        createdAt: DateTime.now(),
        jatuhTempo: null,
      );
      final map = entry.toMap();
      expect(map['jatuhTempo'], isNull);
      final entry2 = HistoryEntry.fromMap(map);
      expect(entry2.jatuhTempo, isNull);
    });

    test('jatuhTempo with value serializes', () {
      final jt = DateTime(2026, 4, 30);
      final entry = HistoryEntry(
        id: '1',
        docType: DocType.invoice,
        nomorDokumen: 'INV-001',
        namaKlien: '',
        totalAmount: 0,
        tanggalDokumen: DateTime.now(),
        createdAt: DateTime.now(),
        jatuhTempo: jt,
      );
      final map = entry.toMap();
      final entry2 = HistoryEntry.fromMap(map);
      expect(entry2.jatuhTempo!.year, 2026);
      expect(entry2.jatuhTempo!.month, 4);
      expect(entry2.jatuhTempo!.day, 30);
    });
  });
}
