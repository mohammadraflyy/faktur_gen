import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_model.dart';
import '../models/recurring_invoice_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'history_service.dart';
import 'settings_service.dart';

class RecurringInvoiceService {
  static const _kRecurring = 's_recurring_invoices';

  static Future<List<RecurringInvoiceModel>> loadAll() async {
    if (AuthService.isLoggedIn) {
      try {
        final snapshot =
            await FirestoreService.userCollection('recurring_invoices').get();
        final items = snapshot.docs
            .map((d) => RecurringInvoiceModel.fromMap(d.data()))
            .toList();
        items.sort((a, b) => a.nextDate.compareTo(b.nextDate));
        await _persistLocal(items);
        return items;
      } catch (_) {}
    }
    return _loadLocal();
  }

  static Future<void> save(RecurringInvoiceModel item) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('recurring_invoices')
          .doc(item.id)
          .set(item.toMap());
    }
    final items = await _loadLocal();
    final idx = items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      items[idx] = item;
    } else {
      items.add(item);
    }
    await _persistLocal(items);
  }

  static Future<void> delete(String id) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('recurring_invoices')
          .doc(id)
          .delete();
    }
    final items = await _loadLocal();
    items.removeWhere((i) => i.id == id);
    await _persistLocal(items);
  }

  /// Check for due recurring invoices and auto-generate them.
  /// Returns the list of generated history entries.
  static Future<List<HistoryEntry>> checkAndGenerate() async {
    final items = await loadAll();
    final generated = <HistoryEntry>[];

    for (final item in items) {
      if (!item.isDue) continue;

      try {
        // Generate invoice number
        final invoiceNumber = await SettingsService.generateInvoiceNumber(
          prefix: item.invoicePrefix,
        );

        // Build history entry
        final entry = HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          docType: DocType.invoice,
          nomorDokumen: invoiceNumber,
          namaKlien: item.contactName,
          totalAmount: calculateTotal(item),
          tanggalDokumen: item.nextDate,
          createdAt: DateTime.now(),
          items: item.items
              .map((i) => HistoryItem(
                    nama: i.nama,
                    kuantitas: i.kuantitas,
                    satuan: i.satuan,
                    hargaSatuan: i.hargaSatuan,
                    subtotal: i.kuantitas * i.hargaSatuan,
                  ))
              .toList(),
          catatan: item.catatan,
          alamatPembeli: item.contactAddress,
          npwpPembeli: item.contactNpwp,
          taxRate: item.taxRate,
          currency: item.currency,
        );

        await HistoryService.add(entry);
        generated.add(entry);

        // Advance to next date
        item.advanceToNext();
        await save(item);

        debugPrint(
            '[RecurringInvoiceService] Generated invoice $invoiceNumber for ${item.contactName}');
      } catch (e) {
        debugPrint(
            '[RecurringInvoiceService] Error generating for ${item.contactName}: $e');
      }
    }

    return generated;
  }

  static double calculateTotal(RecurringInvoiceModel item) {
    final subtotal =
        item.items.fold(0.0, (s, i) => s + i.kuantitas * i.hargaSatuan);
    return subtotal + (subtotal * item.taxRate / 100);
  }

  static Future<List<RecurringInvoiceModel>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kRecurring);
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List;
    final items = list
        .map((e) =>
            RecurringInvoiceModel.fromMap(e as Map<String, dynamic>))
        .toList();
    items.sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return items;
  }

  static Future<void> _persistLocal(
      List<RecurringInvoiceModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(items.map((i) => i.toMap()).toList());
    await prefs.setString(_kRecurring, json);
  }
}
