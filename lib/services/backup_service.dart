import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const _kLastAutoBackup = 's_last_auto_backup';
  static const _autoBackupIntervalDays = 7;

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
    's_template_config',
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

  /// Check if auto-backup is due and perform it silently.
  static Future<bool> autoBackupIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackupMs = prefs.getInt(_kLastAutoBackup) ?? 0;
      final lastBackup = DateTime.fromMillisecondsSinceEpoch(lastBackupMs);
      final now = DateTime.now();

      if (now.difference(lastBackup).inDays < _autoBackupIntervalDays) {
        return false; // not due yet
      }

      // Check if there's any data worth backing up
      final hasHistory = prefs.getString('s_history')?.isNotEmpty ?? false;
      final hasReminders = prefs.getString('s_reminders')?.isNotEmpty ?? false;
      if (!hasHistory && !hasReminders) return false;

      // Build backup data
      final data = <String, dynamic>{};
      for (final key in _backupKeys) {
        final val = prefs.get(key);
        if (val != null) data[key] = val;
      }
      final json = const JsonEncoder.withIndent('  ').convert({
        'version': 1,
        'autoBackup': true,
        'timestamp': now.toIso8601String(),
        'data': data,
      });

      // Save to app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Keep only last 4 backups
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final file = File('${backupDir.path}/auto_backup_$dateStr.json');
      await file.writeAsString(json);

      // Clean old backups (keep last 4)
      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (var i = 4; i < files.length; i++) {
        await files[i].delete();
      }

      await prefs.setInt(_kLastAutoBackup, now.millisecondsSinceEpoch);
      return true;
    } catch (e) {
      // Silent failure — auto-backup should never crash the app
      return false;
    }
  }

  /// Get info about last auto-backup.
  static Future<DateTime?> getLastAutoBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastAutoBackup);
    if (ms == null || ms == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
