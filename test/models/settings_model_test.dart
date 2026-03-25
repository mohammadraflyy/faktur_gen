import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:faktur_gen/models/settings_model.dart';

void main() {
  group('BankAccount', () {
    test('default is empty', () {
      final b = BankAccount();
      expect(b.isEmpty, isTrue);
    });

    test('not empty when has data', () {
      final b = BankAccount(namaBank: 'BCA');
      expect(b.isEmpty, isFalse);
    });

    test('serialization roundtrip', () {
      final b = BankAccount(
        namaBank: 'Mandiri',
        nomorRekening: '1234567890',
        namaPemilik: 'John',
      );
      final map = b.toMap();
      final b2 = BankAccount.fromMap(map);
      expect(b2.namaBank, 'Mandiri');
      expect(b2.nomorRekening, '1234567890');
      expect(b2.namaPemilik, 'John');
    });
  });

  group('SettingsModel', () {
    test('default values', () {
      final s = SettingsModel();
      expect(s.namaToko, '');
      expect(s.taxRate, 11);
      expect(s.currency, 'IDR');
      expect(s.invoicePrefix, 'INV');
      expect(s.strukPrefix, 'STR');
      expect(s.footerStruk, 'Terima kasih atas kunjungan Anda!');
      expect(s.isEmpty, isTrue);
      expect(s.hasLogo, isFalse);
      expect(s.hasSignature, isFalse);
      expect(s.bankAccounts, isEmpty);
    });

    test('isEmpty is false when namaToko is set', () {
      final s = SettingsModel(namaToko: 'Toko Maju');
      expect(s.isEmpty, isFalse);
    });

    test('hasLogo with bytes', () {
      final s = SettingsModel(logoBytes: Uint8List.fromList([1, 2, 3]));
      expect(s.hasLogo, isTrue);
    });

    test('hasLogo false with empty bytes', () {
      final s = SettingsModel(logoBytes: Uint8List(0));
      expect(s.hasLogo, isFalse);
    });

    test('hasSignature with bytes', () {
      final s = SettingsModel(signatureBytes: Uint8List.fromList([1]));
      expect(s.hasSignature, isTrue);
    });

    test('currencySymbol for IDR', () {
      final s = SettingsModel(currency: 'IDR');
      expect(s.currencySymbol, 'Rp ');
      expect(s.currencyLocale, 'id_ID');
    });

    test('currencySymbol for USD', () {
      final s = SettingsModel(currency: 'USD');
      expect(s.currencySymbol, '\$ ');
      expect(s.currencyLocale, 'en_US');
    });

    test('currencySymbol for EUR', () {
      final s = SettingsModel(currency: 'EUR');
      expect(s.currencySymbol, '\u20AC ');
      expect(s.currencyLocale, 'de_DE');
    });

    test('activeBanks filters empty ones', () {
      final s = SettingsModel(bankAccounts: [
        BankAccount(namaBank: 'BCA', nomorRekening: '123', namaPemilik: 'A'),
        BankAccount(), // empty
        BankAccount(namaBank: 'BNI', nomorRekening: '456', namaPemilik: 'B'),
      ]);
      expect(s.activeBanks.length, 2);
      expect(s.activeBanks[0].namaBank, 'BCA');
      expect(s.activeBanks[1].namaBank, 'BNI');
    });
  });
}
