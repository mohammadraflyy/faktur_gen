import 'dart:typed_data';
import 'doc_template_config.dart';

class BankAccount {
  String namaBank;
  String nomorRekening;
  String namaPemilik;

  BankAccount({
    this.namaBank = '',
    this.nomorRekening = '',
    this.namaPemilik = '',
  });

  bool get isEmpty =>
      namaBank.isEmpty && nomorRekening.isEmpty && namaPemilik.isEmpty;

  Map<String, String> toMap() => {
        'namaBank': namaBank,
        'nomorRekening': nomorRekening,
        'namaPemilik': namaPemilik,
      };

  factory BankAccount.fromMap(Map<String, dynamic> m) => BankAccount(
        namaBank: m['namaBank'] ?? '',
        nomorRekening: m['nomorRekening'] ?? '',
        namaPemilik: m['namaPemilik'] ?? '',
      );
}

class SettingsModel {
  String namaToko;
  String alamat;
  String telepon;
  String email;
  String website;
  String npwp;
  String footerStruk;
  Uint8List? logoBytes;
  Uint8List? signatureBytes;
  List<BankAccount> bankAccounts;

  // Tax & Currency
  double taxRate; // default 11%
  String currency; // IDR, USD, EUR

  // Custom numbering
  String invoicePrefix;
  String strukPrefix;

  // Document templates
  DocTemplateConfig templateConfig;

  SettingsModel({
    this.namaToko = '',
    this.alamat = '',
    this.telepon = '',
    this.email = '',
    this.website = '',
    this.npwp = '',
    this.footerStruk = 'Terima kasih atas kunjungan Anda!',
    this.logoBytes,
    this.signatureBytes,
    List<BankAccount>? bankAccounts,
    this.taxRate = 11,
    this.currency = 'IDR',
    this.invoicePrefix = 'INV',
    this.strukPrefix = 'STR',
    DocTemplateConfig? templateConfig,
  })  : bankAccounts = bankAccounts ?? [],
        templateConfig = templateConfig ?? DocTemplateConfig();

  bool get hasLogo => logoBytes != null && logoBytes!.isNotEmpty;
  bool get hasSignature => signatureBytes != null && signatureBytes!.isNotEmpty;
  bool get isEmpty => namaToko.isEmpty;
  List<BankAccount> get activeBanks =>
      bankAccounts.where((b) => !b.isEmpty).toList();

  String get currencySymbol {
    switch (currency) {
      case 'USD':
        return '\$ ';
      case 'EUR':
        return '\u20AC ';
      default:
        return 'Rp ';
    }
  }

  String get currencyLocale {
    switch (currency) {
      case 'USD':
        return 'en_US';
      case 'EUR':
        return 'de_DE';
      default:
        return 'id_ID';
    }
  }
}
