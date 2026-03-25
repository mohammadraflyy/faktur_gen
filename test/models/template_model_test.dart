import 'package:flutter_test/flutter_test.dart';
import 'package:faktur_gen/models/template_model.dart';

void main() {
  group('TemplateItem', () {
    test('serialization roundtrip', () {
      final item = TemplateItem(
        nama: 'Jasa Konsultasi',
        deskripsi: 'Per jam',
        kuantitas: 2,
        satuan: 'jam',
        hargaSatuan: 500000,
      );
      final map = item.toMap();
      final item2 = TemplateItem.fromMap(map);
      expect(item2.nama, 'Jasa Konsultasi');
      expect(item2.deskripsi, 'Per jam');
      expect(item2.kuantitas, 2);
      expect(item2.satuan, 'jam');
      expect(item2.hargaSatuan, 500000);
    });

    test('fromMap with missing fields', () {
      final item = TemplateItem.fromMap({});
      expect(item.nama, '');
      expect(item.kuantitas, 1);
      expect(item.satuan, 'Unit');
      expect(item.hargaSatuan, 0);
    });
  });

  group('TemplateModel', () {
    test('serialization roundtrip', () {
      final t = TemplateModel(
        id: 't-1',
        name: 'Invoice Bulanan',
        namaPembeli: 'PT XYZ',
        npwpPembeli: '00.000.000.0-000.000',
        alamatPembeli: 'Jakarta',
        teleponPembeli: '08111',
        catatan: 'Pembayaran 30 hari',
        items: [
          TemplateItem(
            nama: 'Maintenance',
            kuantitas: 1,
            satuan: 'paket',
            hargaSatuan: 2000000,
          ),
        ],
      );

      final map = t.toMap();
      final t2 = TemplateModel.fromMap(map);

      expect(t2.id, 't-1');
      expect(t2.name, 'Invoice Bulanan');
      expect(t2.namaPembeli, 'PT XYZ');
      expect(t2.catatan, 'Pembayaran 30 hari');
      expect(t2.items.length, 1);
      expect(t2.items[0].nama, 'Maintenance');
      expect(t2.items[0].hargaSatuan, 2000000);
    });

    test('empty items list', () {
      final t = TemplateModel(id: 'x', name: 'Empty');
      final map = t.toMap();
      final t2 = TemplateModel.fromMap(map);
      expect(t2.items, isEmpty);
    });
  });
}
