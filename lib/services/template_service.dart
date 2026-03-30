import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/template_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

class TemplateService {
  static const _kTemplates = 's_templates';

  static Future<List<TemplateModel>> loadAll() async {
    if (AuthService.isLoggedIn) {
      try {
        final snapshot = await FirestoreService.userCollection('templates').get();
        final templates = snapshot.docs
            .map((d) => TemplateModel.fromMap(d.data()))
            .toList();
        await _persistLocal(templates);
        return templates;
      } catch (_) {
        // Fall through to local
      }
    }
    return _loadLocal();
  }

  static Future<void> save(TemplateModel template) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('templates')
          .doc(template.id)
          .set(template.toMap());
    }
    final templates = await _loadLocal();
    final idx = templates.indexWhere((t) => t.id == template.id);
    if (idx >= 0) {
      templates[idx] = template;
    } else {
      templates.add(template);
    }
    await _persistLocal(templates);
  }

  static Future<void> delete(String id) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('templates').doc(id).delete();
    }
    final templates = await _loadLocal();
    templates.removeWhere((t) => t.id == id);
    await _persistLocal(templates);
  }

  static Future<List<TemplateModel>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kTemplates);
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => TemplateModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _persistLocal(List<TemplateModel> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(templates.map((t) => t.toMap()).toList());
    await prefs.setString(_kTemplates, json);
  }
}
