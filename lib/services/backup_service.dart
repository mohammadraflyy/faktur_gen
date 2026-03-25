import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const _backupKeys = [
    's_history',
    's_contacts',
    's_nama',
    's_alamat',
    's_telepon',
    's_email',
    's_website',
    's_npwp',
    's_footer',
    's_logo',
    's_signature',
    's_bank_accounts',
    's_struk_date',
    's_struk_counter',
    's_inv_date',
    's_inv_counter',
    's_dark_mode',
    's_templates',
    's_reminders',
  ];

  static Future<void> export() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};
    for (final key in _backupKeys) {
      final val = prefs.get(key);
      if (val != null) data[key] = val;
    }
    final json = const JsonEncoder.withIndent('  ')
        .convert({'version': 1, 'data': data});
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/backup_faktura.json');
    await file.writeAsString(json);
    await Share.shareXFiles([XFile(file.path)], subject: 'Backup Faktura');
  }

  static Future<bool> import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return false;

    final path = result.files.first.path;
    if (path == null) return false;

    final file = File(path);
    final content = await file.readAsString();
    final parsed = jsonDecode(content) as Map<String, dynamic>;

    if (!parsed.containsKey('data')) return false;
    final data = parsed['data'] as Map<String, dynamic>;

    final prefs = await SharedPreferences.getInstance();
    for (final entry in data.entries) {
      final val = entry.value;
      if (val is String) {
        await prefs.setString(entry.key, val);
      } else if (val is int) {
        await prefs.setInt(entry.key, val);
      } else if (val is double) {
        await prefs.setDouble(entry.key, val);
      } else if (val is bool) {
        await prefs.setBool(entry.key, val);
      }
    }
    return true;
  }
}
