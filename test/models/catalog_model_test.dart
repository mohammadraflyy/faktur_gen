import 'package:flutter_test/flutter_test.dart';
import 'package:faktur_gen/models/catalog_model.dart';

void main() {
  group('CatalogItem', () {
    test('default values', () {
      final c = CatalogItem(id: '1');
      expect(c.nama, '');
      expect(c.deskripsi, '');
      expect(c.satuan, 'Unit');
      expect(c.hargaSatuan, 0);
    });

    test('serialization roundtrip', () {
      final c = CatalogItem(
        id: 'cat-1',
        nama: 'Jasa Cuci AC',
        deskripsi: 'Pembersihan unit indoor + outdoor',
        satuan: 'unit',
        hargaSatuan: 150000,
      );
      final map = c.toMap();
      final c2 = CatalogItem.fromMap(map);

      expect(c2.id, 'cat-1');
      expect(c2.nama, 'Jasa Cuci AC');
      expect(c2.deskripsi, 'Pembersihan unit indoor + outdoor');
      expect(c2.satuan, 'unit');
      expect(c2.hargaSatuan, 150000);
    });

    test('fromMap with missing fields uses defaults', () {
      final c = CatalogItem.fromMap({'id': 'x'});
      expect(c.nama, '');
      expect(c.satuan, 'Unit');
      expect(c.hargaSatuan, 0);
    });
  });
}
