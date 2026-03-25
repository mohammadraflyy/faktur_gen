import 'package:flutter_test/flutter_test.dart';
import 'package:faktur_gen/models/contact_model.dart';

void main() {
  group('ContactModel', () {
    test('default is empty', () {
      final c = ContactModel(id: '1');
      expect(c.isEmpty, isTrue);
    });

    test('not empty with name', () {
      final c = ContactModel(id: '1', nama: 'PT ABC');
      expect(c.isEmpty, isFalse);
    });

    test('isEmpty with whitespace-only name', () {
      final c = ContactModel(id: '1', nama: '   ');
      expect(c.isEmpty, isTrue);
    });

    test('matchesName case-insensitive', () {
      final c = ContactModel(id: '1', nama: 'PT Maju Jaya');
      expect(c.matchesName('PT Maju Jaya'), isTrue);
      expect(c.matchesName('pt maju jaya'), isTrue);
      expect(c.matchesName('PT MAJU JAYA'), isTrue);
      expect(c.matchesName('PT Maju'), isFalse);
    });

    test('matchesName trims whitespace', () {
      final c = ContactModel(id: '1', nama: '  Budi  ');
      expect(c.matchesName('Budi'), isTrue);
      expect(c.matchesName('  Budi  '), isTrue);
    });

    test('serialization roundtrip', () {
      final c = ContactModel(
        id: 'c-1',
        nama: 'CV Berkah',
        npwp: '12.345.678.9-012.000',
        alamat: 'Jl. Sudirman No. 1',
        telepon: '021-1234567',
      );
      final map = c.toMap();
      final c2 = ContactModel.fromMap(map);

      expect(c2.id, 'c-1');
      expect(c2.nama, 'CV Berkah');
      expect(c2.npwp, '12.345.678.9-012.000');
      expect(c2.alamat, 'Jl. Sudirman No. 1');
      expect(c2.telepon, '021-1234567');
    });
  });
}
