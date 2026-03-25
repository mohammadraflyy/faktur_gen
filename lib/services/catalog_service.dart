import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/catalog_model.dart';

class CatalogService {
  static const _kCatalog = 's_catalog';

  static Future<List<CatalogItem>> loadAll() async {
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

  static Future<void> save(CatalogItem item) async {
    final items = await loadAll();
    final idx = items.indexWhere((c) => c.id == item.id);
    if (idx >= 0) {
      items[idx] = item;
    } else {
      items.add(item);
    }
    await _persist(items);
  }

  static Future<void> delete(String id) async {
    final items = await loadAll();
    items.removeWhere((c) => c.id == id);
    await _persist(items);
  }

  static Future<void> _persist(List<CatalogItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(items.map((c) => c.toMap()).toList());
    await prefs.setString(_kCatalog, json);
  }
}
