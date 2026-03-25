import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsService {
  static const _kNama = 's_nama';
  static const _kAlamat = 's_alamat';
  static const _kTelepon = 's_telepon';
  static const _kEmail = 's_email';
  static const _kWebsite = 's_website';
  static const _kNpwp = 's_npwp';
  static const _kFooter = 's_footer';
  static const _kLogo = 's_logo';
  static const _kSignature = 's_signature';
  static const _kBankAccounts = 's_bank_accounts';
  static const _kTaxRate = 's_tax_rate';
  static const _kCurrency = 's_currency';
  static const _kInvPrefix = 's_inv_prefix';
  static const _kStrPrefix = 's_str_prefix';

  static const _kStrukDate = 's_struk_date';
  static const _kStrukCounter = 's_struk_counter';
  static const _kInvoiceDate = 's_inv_date';
  static const _kInvoiceCounter = 's_inv_counter';

  static Future<String> generateStrukNumber({String prefix = 'STR'}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    final lastDate = prefs.getString(_kStrukDate) ?? '';
    final lastCounter = prefs.getInt(_kStrukCounter) ?? 0;

    final counter = lastDate == today ? lastCounter + 1 : 1;
    await prefs.setString(_kStrukDate, today);
    await prefs.setInt(_kStrukCounter, counter);

    return '$prefix-$today-${counter.toString().padLeft(3, '0')}';
  }

  static Future<String> generateInvoiceNumber({String prefix = 'INV'}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    final lastDate = prefs.getString(_kInvoiceDate) ?? '';
    final lastCounter = prefs.getInt(_kInvoiceCounter) ?? 0;

    final counter = lastDate == today ? lastCounter + 1 : 1;
    await prefs.setString(_kInvoiceDate, today);
    await prefs.setInt(_kInvoiceCounter, counter);

    return '$prefix-$today-${counter.toString().padLeft(3, '0')}';
  }

  static Future<SettingsModel> load() async {
    final prefs = await SharedPreferences.getInstance();

    Uint8List? logoBytes;
    final logoB64 = prefs.getString(_kLogo);
    if (logoB64 != null && logoB64.isNotEmpty) {
      logoBytes = base64Decode(logoB64);
    }

    Uint8List? signatureBytes;
    final sigB64 = prefs.getString(_kSignature);
    if (sigB64 != null && sigB64.isNotEmpty) {
      signatureBytes = base64Decode(sigB64);
    }

    List<BankAccount> banks = [];
    final banksJson = prefs.getString(_kBankAccounts);
    if (banksJson != null && banksJson.isNotEmpty) {
      final decoded = jsonDecode(banksJson) as List;
      banks = decoded.map((e) => BankAccount.fromMap(e)).toList();
    }

    return SettingsModel(
      namaToko: prefs.getString(_kNama) ?? '',
      alamat: prefs.getString(_kAlamat) ?? '',
      telepon: prefs.getString(_kTelepon) ?? '',
      email: prefs.getString(_kEmail) ?? '',
      website: prefs.getString(_kWebsite) ?? '',
      npwp: prefs.getString(_kNpwp) ?? '',
      footerStruk:
          prefs.getString(_kFooter) ?? 'Terima kasih atas kunjungan Anda!',
      logoBytes: logoBytes,
      signatureBytes: signatureBytes,
      bankAccounts: banks,
      taxRate: prefs.getDouble(_kTaxRate) ?? 11,
      currency: prefs.getString(_kCurrency) ?? 'IDR',
      invoicePrefix: prefs.getString(_kInvPrefix) ?? 'INV',
      strukPrefix: prefs.getString(_kStrPrefix) ?? 'STR',
    );
  }

  static Future<void> save(SettingsModel s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNama, s.namaToko);
    await prefs.setString(_kAlamat, s.alamat);
    await prefs.setString(_kTelepon, s.telepon);
    await prefs.setString(_kEmail, s.email);
    await prefs.setString(_kWebsite, s.website);
    await prefs.setString(_kNpwp, s.npwp);
    await prefs.setString(_kFooter, s.footerStruk);
    await prefs.setString(
        _kBankAccounts, jsonEncode(s.bankAccounts.map((b) => b.toMap()).toList()));
    await prefs.setDouble(_kTaxRate, s.taxRate);
    await prefs.setString(_kCurrency, s.currency);
    await prefs.setString(_kInvPrefix, s.invoicePrefix);
    await prefs.setString(_kStrPrefix, s.strukPrefix);
    if (s.logoBytes != null) {
      await prefs.setString(_kLogo, base64Encode(s.logoBytes!));
    } else {
      await prefs.remove(_kLogo);
    }
    if (s.signatureBytes != null) {
      await prefs.setString(_kSignature, base64Encode(s.signatureBytes!));
    } else {
      await prefs.remove(_kSignature);
    }
  }
}
