import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

class HistoryService {
  static const _kHistory = 's_history';

  static Future<List<HistoryEntry>> load() async {
    if (AuthService.isLoggedIn) {
      try {
        final snapshot = await FirestoreService.userCollection('history')
            .orderBy('createdAt', descending: true)
            .get();
        final entries = snapshot.docs
            .map((d) => HistoryEntry.fromMap(d.data()))
            .toList();
        // Update local cache
        await _saveLocal(entries);
        return entries;
      } catch (_) {
        // Fall through to local
      }
    }
    return _loadLocal();
  }

  static Future<void> add(HistoryEntry entry) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('history')
          .doc(entry.id)
          .set(entry.toMap());
    }
    final entries = await _loadLocal();
    entries.insert(0, entry);
    await _saveLocal(entries);
  }

  static Future<void> delete(String id) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('history').doc(id).delete();
    }
    final entries = await _loadLocal();
    entries.removeWhere((e) => e.id == id);
    await _saveLocal(entries);
  }

  static Future<void> updateStatus(String id, PaymentStatus status) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('history')
          .doc(id)
          .update({'paymentStatus': status.index});
    }
    final entries = await _loadLocal();
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      entries[idx].paymentStatus = status;
      await _saveLocal(entries);
    }
  }

  static Future<void> clearAll() async {
    if (AuthService.isLoggedIn) {
      final snapshot = await FirestoreService.userCollection('history').get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistory);
  }

  static Future<List<HistoryEntry>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kHistory);
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List;
    final entries = list.map((e) => HistoryEntry.fromMap(e)).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  static Future<void> _saveLocal(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(entries.map((e) => e.toMap()).toList());
    await prefs.setString(_kHistory, json);
  }
}
