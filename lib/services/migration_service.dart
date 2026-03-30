import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/catalog_model.dart';
import '../models/contact_model.dart';
import '../models/history_model.dart';
import '../models/reminder_model.dart';
import '../models/template_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'settings_service.dart';

class MigrationService {
  static Future<void> migrateIfNeeded() async {
    if (!AuthService.isLoggedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final uid = AuthService.uid!;
    final flagKey = 's_migrated_to_cloud_$uid';

    if (prefs.getBool(flagKey) == true) return;

    try {
      // Check if cloud already has data (logged in on another device)
      final settingsDoc = await FirestoreService.userDoc('settings').get();
      if (settingsDoc.exists) {
        // Cloud has data — just mark as migrated, don't overwrite
        await prefs.setBool(flagKey, true);
        return;
      }

      // Migrate local data to cloud
      await _migrateSettings(prefs);
      await _migrateCollection<HistoryEntry>(
        prefs, 's_history', 'history', HistoryEntry.fromMap,
      );
      await _migrateCollection<ContactModel>(
        prefs, 's_contacts', 'contacts', ContactModel.fromMap,
      );
      await _migrateCollection<ReminderModel>(
        prefs, 's_reminders', 'reminders', ReminderModel.fromMap,
      );
      await _migrateCollection<CatalogItem>(
        prefs, 's_catalog', 'catalog', CatalogItem.fromMap,
      );
      await _migrateCollection<TemplateModel>(
        prefs, 's_templates', 'templates', TemplateModel.fromMap,
      );
      await _migrateCounters(prefs);

      await prefs.setBool(flagKey, true);
      debugPrint('[MigrationService] Migration completed for $uid');
    } catch (e) {
      debugPrint('[MigrationService] Migration error: $e');
    }
  }

  static Future<void> _migrateSettings(SharedPreferences prefs) async {
    final settings = await SettingsService.load();
    final data = <String, dynamic>{
      'namaToko': settings.namaToko,
      'alamat': settings.alamat,
      'telepon': settings.telepon,
      'email': settings.email,
      'website': settings.website,
      'npwp': settings.npwp,
      'footerStruk': settings.footerStruk,
      'bankAccounts': settings.bankAccounts.map((b) => b.toMap()).toList(),
      'taxRate': settings.taxRate,
      'currency': settings.currency,
      'invoicePrefix': settings.invoicePrefix,
      'strukPrefix': settings.strukPrefix,
      'templateConfig': settings.templateConfig.toMap(),
      'logoBase64': settings.logoBytes != null ? base64Encode(settings.logoBytes!) : '',
      'signatureBase64': settings.signatureBytes != null ? base64Encode(settings.signatureBytes!) : '',
    };

    await FirestoreService.userDoc('settings').set(data);
  }

  static Future<void> _migrateCollection<T>(
    SharedPreferences prefs,
    String prefsKey,
    String collectionName,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final json = prefs.getString(prefsKey);
    if (json == null || json.isEmpty) return;

    final list = jsonDecode(json) as List;
    if (list.isEmpty) return;

    // Batch write (max 500 per batch)
    final collection = FirestoreService.userCollection(collectionName);
    var batch = FirebaseFirestore.instance.batch();
    var count = 0;

    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final id = map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      batch.set(collection.doc(id), map);
      count++;
      if (count >= 400) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        count = 0;
      }
    }

    if (count > 0) await batch.commit();
  }

  static Future<void> _migrateCounters(SharedPreferences prefs) async {
    final data = <String, dynamic>{
      'strukDate': prefs.getString('s_struk_date') ?? '',
      'strukCounter': prefs.getInt('s_struk_counter') ?? 0,
      'invoiceDate': prefs.getString('s_inv_date') ?? '',
      'invoiceCounter': prefs.getInt('s_inv_counter') ?? 0,
    };
    await FirestoreService.metaDoc('counters').set(data);
  }
}
