import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

class ReminderService {
  static const _kReminders = 's_reminders';

  static Future<List<ReminderModel>> loadAll() async {
    if (AuthService.isLoggedIn) {
      try {
        final snapshot = await FirestoreService.userCollection('reminders').get();
        final reminders = snapshot.docs
            .map((d) => ReminderModel.fromMap(d.data()))
            .toList();
        reminders.sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
        await _persistLocal(reminders);
        return reminders;
      } catch (_) {
        // Fall through to local
      }
    }
    return _loadLocal();
  }

  static Future<List<ReminderModel>> getUpcoming() async {
    final all = await loadAll();
    return all.where((r) => r.status == ReminderStatus.pending).toList();
  }

  static Future<void> add(ReminderModel reminder) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('reminders')
          .doc(reminder.id)
          .set(reminder.toMap());
    }
    final list = await _loadLocal();
    list.add(reminder);
    await _persistLocal(list);
    await NotificationService.scheduleReminder(reminder);
  }

  static Future<void> update(ReminderModel reminder) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('reminders')
          .doc(reminder.id)
          .set(reminder.toMap());
    }
    final list = await _loadLocal();
    final idx = list.indexWhere((r) => r.id == reminder.id);
    if (idx >= 0) {
      list[idx] = reminder;
      await _persistLocal(list);
      await NotificationService.cancelReminder(reminder);
      if (reminder.status == ReminderStatus.pending) {
        await NotificationService.scheduleReminder(reminder);
      }
    }
  }

  static Future<void> updateStatus(String id, ReminderStatus status) async {
    final list = await _loadLocal();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx < 0) return;

    final reminder = list[idx];
    await NotificationService.cancelReminder(reminder);

    if (status == ReminderStatus.done && reminder.isRepeating) {
      // For recurring reminders: advance to next date and keep pending
      reminder.advanceToNext();
      list[idx] = reminder;
      await _persistLocal(list);
      if (AuthService.isLoggedIn) {
        await FirestoreService.userCollection('reminders')
            .doc(id)
            .set(reminder.toMap());
      }
      await NotificationService.scheduleReminder(reminder);
    } else {
      reminder.status = status;
      list[idx] = reminder;
      await _persistLocal(list);
      if (AuthService.isLoggedIn) {
        await FirestoreService.userCollection('reminders')
            .doc(id)
            .update({'status': status.index});
      }
    }
  }

  static Future<void> delete(String id) async {
    if (AuthService.isLoggedIn) {
      await FirestoreService.userCollection('reminders').doc(id).delete();
    }
    final list = await _loadLocal();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      await NotificationService.cancelReminder(list[idx]);
      list.removeAt(idx);
      await _persistLocal(list);
    }
  }

  /// Auto-advance recurring reminders yang terlewat, lalu reschedule semua
  static Future<void> rescheduleNotifications() async {
    try {
      final list = await _loadLocal();
      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      bool changed = false;

      for (final r in list) {
        if (r.status == ReminderStatus.pending &&
            r.isRepeating &&
            r.reminderDate.isBefore(today)) {
          // Maju terus sampai tanggal >= hari ini, max 120 iterasi sebagai safety net
          var iterations = 0;
          while (r.reminderDate.isBefore(today) && iterations < 120) {
            r.advanceToNext();
            iterations++;
          }
          changed = true;
        }
      }

      if (changed) await _persistLocal(list);
      await NotificationService.rescheduleAll(list);
    } catch (e) {
      debugPrint('[ReminderService] rescheduleNotifications error: $e');
    }
  }

  static Future<List<ReminderModel>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kReminders);
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List;
    final reminders = list.map((e) => ReminderModel.fromMap(e)).toList();
    reminders.sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
    return reminders;
  }

  static Future<void> _persistLocal(List<ReminderModel> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(reminders.map((r) => r.toMap()).toList());
    await prefs.setString(_kReminders, json);
  }
}
