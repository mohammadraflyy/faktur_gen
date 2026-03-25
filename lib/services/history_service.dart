import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_model.dart';

class HistoryService {
  static const _kHistory = 's_history';

  static Future<List<HistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kHistory);
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List;
    final entries = list.map((e) => HistoryEntry.fromMap(e)).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  static Future<void> add(HistoryEntry entry) async {
    final entries = await load();
    entries.insert(0, entry);
    await _save(entries);
  }

  static Future<void> delete(String id) async {
    final entries = await load();
    entries.removeWhere((e) => e.id == id);
    await _save(entries);
  }

  static Future<void> updateStatus(String id, PaymentStatus status) async {
    final entries = await load();
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      entries[idx].paymentStatus = status;
      await _save(entries);
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistory);
  }

  static Future<void> _save(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(entries.map((e) => e.toMap()).toList());
    await prefs.setString(_kHistory, json);
  }
}
