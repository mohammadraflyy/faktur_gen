import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/catalog_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

class CatalogService {
  static const _kCatalog = 's_catalog';

  static Future<List<CatalogItem>> loadAll() async {
    if (AuthService.isLoggedIn) {
      try {
        final snapshot = await FirestoreService.userCollection('catalog').get();
        final items = snapshot.docs
            .map((d) => CatalogItem.fromMap(d.data()))
            .toList();
        items.sort(
            (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
        await _persistLocal(items);
        return items;
      } catch (_) {
        // Fall through to local
      }
    }
    return _loadLocal();
  }

  static Future<void> save(CatalogItem item) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('catalog')
          .doc(item.id)
          .set(item.toMap());
    }
    final items = await _loadLocal();
    final idx = items.indexWhere((c) => c.id == item.id);
    if (idx >= 0) {
      items[idx] = item;
    } else {
      items.add(item);
    }
    await _persistLocal(items);
  }

  static Future<void> delete(String id) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('catalog').doc(id).delete();
    }
    final items = await _loadLocal();
    items.removeWhere((c) => c.id == id);
    await _persistLocal(items);
  }

  static Future<List<CatalogItem>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kCatalog);
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List;
    final items = list
        .map((e) => CatalogItem.fromMap(e as Map<String, dynamic>))
        .toList();
    items.sort(
        (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    return items;
  }

  static Future<void> _persistLocal(List<CatalogItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(items.map((c) => c.toMap()).toList());
    await prefs.setString(_kCatalog, json);
  }
}
