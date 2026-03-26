import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';
import 'notification_service.dart';

class ReminderService {
  static const _kReminders = 's_reminders';

  static Future<List<ReminderModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kReminders);
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List;
    final reminders = list.map((e) => ReminderModel.fromMap(e)).toList();
    reminders.sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
    return reminders;
  }

  static Future<List<ReminderModel>> getUpcoming() async {
    final all = await loadAll();
    return all.where((r) => r.status == ReminderStatus.pending).toList();
  }

  static Future<void> add(ReminderModel reminder) async {
    final list = await loadAll();
    list.add(reminder);
    await _persist(list);
    await NotificationService.scheduleReminder(reminder);
  }

  static Future<void> update(ReminderModel reminder) async {
    final list = await loadAll();
    final idx = list.indexWhere((r) => r.id == reminder.id);
    if (idx >= 0) {
      list[idx] = reminder;
      await _persist(list);
      await NotificationService.cancelReminder(reminder);
      if (reminder.status == ReminderStatus.pending) {
        await NotificationService.scheduleReminder(reminder);
      }
    }
  }

  static Future<void> updateStatus(String id, ReminderStatus status) async {
    final list = await loadAll();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx < 0) return;

    final reminder = list[idx];
    await NotificationService.cancelReminder(reminder);

    if (status == ReminderStatus.done && reminder.isRepeating) {
      // For recurring reminders: advance to next date and keep pending
      reminder.advanceToNext();
      list[idx] = reminder;
      await _persist(list);
      await NotificationService.scheduleReminder(reminder);
    } else {
      reminder.status = status;
      list[idx] = reminder;
      await _persist(list);
    }
  }

  static Future<void> delete(String id) async {
    final list = await loadAll();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      await NotificationService.cancelReminder(list[idx]);
      list.removeAt(idx);
      await _persist(list);
    }
  }

  /// Auto-advance recurring reminders yang terlewat, lalu reschedule semua
  static Future<void> rescheduleNotifications() async {
    try {
      final list = await loadAll();
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

      if (changed) await _persist(list);
      await NotificationService.rescheduleAll(list);
    } catch (e) {
      debugPrint('[ReminderService] rescheduleNotifications error: $e');
    }
  }

  static Future<void> _persist(List<ReminderModel> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(reminders.map((r) => r.toMap()).toList());
    await prefs.setString(_kReminders, json);
  }
}
