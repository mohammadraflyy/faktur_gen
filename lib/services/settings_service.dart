import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/doc_template_config.dart';
import '../models/settings_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

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
  static const _kTemplateConfig = 's_template_config';
  static const _kQris = 's_qris_merchant';
  static const _kClientNumbering = 's_client_numbering';

  static const _kStrukDate = 's_struk_date';
  static const _kStrukCounter = 's_struk_counter';
  static const _kInvoiceDate = 's_inv_date';
  static const _kInvoiceCounter = 's_inv_counter';

  static Future<String> generateStrukNumber({String prefix = 'STR'}) async {
    final today = DateFormat('yyyyMMdd').format(DateTime.now());

    if (AuthService.isLoggedIn) {
      try {
        final ref = FirestoreService.metaDoc('counters');
        final result = await FirebaseFirestore.instance.runTransaction((tx) async {
          final doc = await tx.get(ref);
          final data = doc.data() ?? {};
          final lastDate = data['strukDate'] as String? ?? '';
          final lastCounter = data['strukCounter'] as int? ?? 0;
          final counter = lastDate == today ? lastCounter + 1 : 1;
          tx.set(ref, {
            ...data,
            'strukDate': today,
            'strukCounter': counter,
          });
          return counter;
        });
        return '$prefix-$today-${result.toString().padLeft(3, '0')}';
      } catch (e) {
        debugPrint('[SettingsService] Firestore counter error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_kStrukDate) ?? '';
    final lastCounter = prefs.getInt(_kStrukCounter) ?? 0;
    final counter = lastDate == today ? lastCounter + 1 : 1;
    await prefs.setString(_kStrukDate, today);
    await prefs.setInt(_kStrukCounter, counter);
    return '$prefix-$today-${counter.toString().padLeft(3, '0')}';
  }

  static Future<String> generateInvoiceNumber({String prefix = 'INV'}) async {
    final today = DateFormat('yyyyMMdd').format(DateTime.now());

    if (AuthService.isLoggedIn) {
      try {
        final ref = FirestoreService.metaDoc('counters');
        final result = await FirebaseFirestore.instance.runTransaction((tx) async {
          final doc = await tx.get(ref);
          final data = doc.data() ?? {};
          final lastDate = data['invoiceDate'] as String? ?? '';
          final lastCounter = data['invoiceCounter'] as int? ?? 0;
          final counter = lastDate == today ? lastCounter + 1 : 1;
          tx.set(ref, {
            ...data,
            'invoiceDate': today,
            'invoiceCounter': counter,
          });
          return counter;
        });
        return '$prefix-$today-${result.toString().padLeft(3, '0')}';
      } catch (e) {
        debugPrint('[SettingsService] Firestore counter error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_kInvoiceDate) ?? '';
    final lastCounter = prefs.getInt(_kInvoiceCounter) ?? 0;
    final counter = lastDate == today ? lastCounter + 1 : 1;
    await prefs.setString(_kInvoiceDate, today);
    await prefs.setInt(_kInvoiceCounter, counter);
    return '$prefix-$today-${counter.toString().padLeft(3, '0')}';
  }

  static Future<SettingsModel> load() async {
    if (AuthService.isLoggedIn) {
      try {
        final doc = await FirestoreService.userDoc('settings').get();
        if (doc.exists) {
          final data = doc.data()!;
          return _fromFirestoreData(data);
        }
      } catch (e) {
        debugPrint('[SettingsService] Firestore load error: $e');
      }
    }
    return _loadLocal();
  }

  static SettingsModel _fromFirestoreData(Map<String, dynamic> data) {
    Uint8List? logoBytes;
    final logoB64 = data['logoBase64'] as String?;
    if (logoB64 != null && logoB64.isNotEmpty) {
      logoBytes = base64Decode(logoB64);
    }

    Uint8List? signatureBytes;
    final sigB64 = data['signatureBase64'] as String?;
    if (sigB64 != null && sigB64.isNotEmpty) {
      signatureBytes = base64Decode(sigB64);
    }

    List<BankAccount> banks = [];
    final banksData = data['bankAccounts'];
    if (banksData is List) {
      banks = banksData
          .map((e) => BankAccount.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    DocTemplateConfig? templateConfig;
    try {
      final tplData = data['templateConfig'];
      if (tplData is Map<String, dynamic>) {
        templateConfig = DocTemplateConfig.fromMap(tplData);
      }
    } catch (_) {}

    return SettingsModel(
      namaToko: data['namaToko'] as String? ?? '',
      alamat: data['alamat'] as String? ?? '',
      telepon: data['telepon'] as String? ?? '',
      email: data['email'] as String? ?? '',
      website: data['website'] as String? ?? '',
      npwp: data['npwp'] as String? ?? '',
      footerStruk: data['footerStruk'] as String? ?? 'Terima kasih atas kunjungan Anda!',
      logoBytes: logoBytes,
      signatureBytes: signatureBytes,
      bankAccounts: banks,
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 11,
      currency: data['currency'] as String? ?? 'IDR',
      invoicePrefix: data['invoicePrefix'] as String? ?? 'INV',
      strukPrefix: data['strukPrefix'] as String? ?? 'STR',
      templateConfig: templateConfig,
      qrisMerchantId: data['qrisMerchantId'] as String? ?? '',
      useClientNumbering: data['useClientNumbering'] as bool? ?? false,
    );
  }

  static Future<SettingsModel> _loadLocal() async {
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

    DocTemplateConfig? templateConfig;
    try {
      final tplJson = prefs.getString(_kTemplateConfig);
      if (tplJson != null && tplJson.isNotEmpty) {
        final decoded = jsonDecode(tplJson);
        if (decoded is Map<String, dynamic>) {
          templateConfig = DocTemplateConfig.fromMap(decoded);
        }
      }
    } catch (_) {}

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
      templateConfig: templateConfig,
      qrisMerchantId: prefs.getString(_kQris) ?? '',
      useClientNumbering: prefs.getBool(_kClientNumbering) ?? false,
    );
  }

  static Future<void> save(SettingsModel s) async {
    // Always save locally
    await _saveLocal(s);

    // Also save to Firestore if logged in
    if (AuthService.isLoggedIn) {
      try {
        final data = <String, dynamic>{
          'namaToko': s.namaToko,
          'alamat': s.alamat,
          'telepon': s.telepon,
          'email': s.email,
          'website': s.website,
          'npwp': s.npwp,
          'footerStruk': s.footerStruk,
          'bankAccounts': s.bankAccounts.map((b) => b.toMap()).toList(),
          'taxRate': s.taxRate,
          'currency': s.currency,
          'invoicePrefix': s.invoicePrefix,
          'strukPrefix': s.strukPrefix,
          'templateConfig': s.templateConfig.toMap(),
          'logoBase64': s.logoBytes != null ? base64Encode(s.logoBytes!) : '',
          'signatureBase64': s.signatureBytes != null ? base64Encode(s.signatureBytes!) : '',
          'qrisMerchantId': s.qrisMerchantId,
          'useClientNumbering': s.useClientNumbering,
        };
        await FirestoreService.userDoc('settings').set(data);
      } catch (e) {
        debugPrint('[SettingsService] Firestore save error: $e');
      }
    }
  }

  static Future<void> _saveLocal(SettingsModel s) async {
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
    await prefs.setString(
        _kTemplateConfig, jsonEncode(s.templateConfig.toMap()));
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
    await prefs.setString(_kQris, s.qrisMerchantId);
    await prefs.setBool(_kClientNumbering, s.useClientNumbering);
  }

  /// Generate invoice number per client (Pro feature).
  static Future<String> generateClientInvoiceNumber({
    required String prefix,
    required String contactId,
    required String clientCode,
  }) async {
    final key = 's_client_counter_$contactId';
    final prefs = await SharedPreferences.getInstance();
    final counter = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, counter);

    if (AuthService.isLoggedIn) {
      try {
        final ref = FirestoreService.userCollection('client_counters').doc(contactId);
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final doc = await tx.get(ref);
          final c = (doc.data()?['counter'] as int? ?? 0) + 1;
          tx.set(ref, {'counter': c, 'clientCode': clientCode});
        });
      } catch (e) {
        debugPrint('[SettingsService] Client counter error: $e');
      }
    }

    return '$prefix-$clientCode-${counter.toString().padLeft(3, '0')}';
  }
}
