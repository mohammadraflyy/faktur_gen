import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/template_model.dart';

class TemplateService {
  static const _kTemplates = 's_templates';

  static Future<List<TemplateModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kTemplates);
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => TemplateModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(TemplateModel template) async {
    final templates = await loadAll();
    final idx = templates.indexWhere((t) => t.id == template.id);
    if (idx >= 0) {
      templates[idx] = template;
    } else {
      templates.add(template);
    }
    await _persist(templates);
  }

  static Future<void> delete(String id) async {
    final templates = await loadAll();
    templates.removeWhere((t) => t.id == id);
    await _persist(templates);
  }

  static Future<void> _persist(List<TemplateModel> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(templates.map((t) => t.toMap()).toList());
    await prefs.setString(_kTemplates, json);
  }
}
