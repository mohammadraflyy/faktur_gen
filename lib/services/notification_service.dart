import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../main.dart' show navigatorKey;
import '../models/reminder_model.dart';
import '../pages/reminder_page.dart';

class NotificationService {
  static FlutterLocalNotificationsPlugin? _plugin;
  static bool _initialized = false;

  /// Jumlah notifikasi ke depan untuk pengingat berulang (bulanan)
  static const _maxFutureSchedules = 12;

  /// Jumlah alarm pengulangan setiap 5 menit setelah waktu jatuh tempo
  static const _maxFollowUpAlarms = 12; // 12 x 5 menit = 1 jam

  /// Interval pengulangan alarm (menit)
  static const _followUpIntervalMinutes = 5;

  /// Jumlah ID per satu jadwal (1 utama + follow-ups)
  static const _idsPerSchedule = _maxFollowUpAlarms + 1;

  static bool get _supported => !kIsWeb;

  static const _androidDetails = AndroidNotificationDetails(
    'reminder_channel',
    'Pengingat Layanan',
    channelDescription: 'Notifikasi pengingat layanan pelanggan',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    fullScreenIntent: true,
  );

  static Future<void> init() async {
    if (_initialized || !_supported) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    _plugin = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    final success = await _plugin!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    debugPrint('[NotifService] init result: $success');
    _initialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('[NotifService] Notification tapped: ${response.payload}');
    // Navigate to reminder page
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const ReminderPage()),
      );
    }
  }

  static Future<bool> requestPermission() async {
    if (!_supported || _plugin == null) return false;
    final android = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;

    final granted = await android.requestNotificationsPermission();
    debugPrint('[NotifService] POST_NOTIFICATIONS granted: $granted');

    final exactAlarm = await android.requestExactAlarmsPermission();
    debugPrint('[NotifService] Exact alarm granted: $exactAlarm');

    return granted ?? false;
  }

  /// Kirim notifikasi langsung untuk test
  static Future<void> showTestNotification() async {
    if (!_supported) return;
    await init();

    const details = NotificationDetails(android: _androidDetails);
    await _plugin!.show(
      0,
      'Test Notifikasi Pengingat',
      'Sistem notifikasi pengingat layanan berfungsi dengan baik.',
      details,
    );
    debugPrint('[NotifService] Test notification sent');
  }

  static Future<void> scheduleReminder(ReminderModel reminder) async {
    if (!_supported) return;
    await init();

    try {
      if (reminder.isRepeating) {
        await _scheduleRecurring(reminder);
      } else {
        final baseDate = tz.TZDateTime(
          tz.local,
          reminder.reminderDate.year,
          reminder.reminderDate.month,
          reminder.reminderDate.day,
          reminder.reminderHour,
          reminder.reminderMinute,
        );
        await _scheduleWithFollowUps(
          reminder.notificationId,
          baseDate,
          reminder.serviceName,
          reminder.contactName,
        );
      }
    } catch (e) {
      debugPrint('[NotifService] Error scheduling reminder: $e');
    }
  }

  static Future<void> _scheduleRecurring(ReminderModel reminder) async {
    final months = reminder.repeatInterval.months;
    var date = reminder.reminderDate;
    final now = tz.TZDateTime.now(tz.local);

    for (var i = 0; i < _maxFutureSchedules; i++) {
      final scheduledDate = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        reminder.reminderHour,
        reminder.reminderMinute,
      );

      if (scheduledDate.isAfter(now)) {
        final baseId =
            (reminder.notificationId + i * _idsPerSchedule) % 2147483647;
        await _scheduleWithFollowUps(
          baseId,
          scheduledDate,
          reminder.serviceName,
          reminder.contactName,
        );
      }

      date = DateTime(date.year, date.month + months, date.day);
    }
  }

  /// Jadwalkan notifikasi utama + alarm pengulangan setiap 5 menit
  static Future<void> _scheduleWithFollowUps(
    int baseId,
    tz.TZDateTime scheduledDate,
    String serviceName,
    String contactName,
  ) async {
    final now = tz.TZDateTime.now(tz.local);

    // Notifikasi utama
    if (scheduledDate.isAfter(now)) {
      await _scheduleNotification(
        baseId,
        scheduledDate,
        'Pengingat Layanan - $serviceName',
        'Pelanggan: $contactName\nLayanan $serviceName sudah jatuh tempo hari ini. Segera ditindaklanjuti.',
      );
    }

    // Alarm pengulangan setiap 5 menit setelah waktu utama
    for (var j = 1; j <= _maxFollowUpAlarms; j++) {
      final followUpDate = scheduledDate.add(
        Duration(minutes: _followUpIntervalMinutes * j),
      );
      if (followUpDate.isAfter(now)) {
        final followUpId = (baseId + j) % 2147483647;
        final menit = _followUpIntervalMinutes * j;
        await _scheduleNotification(
          followUpId,
          followUpDate,
          'Pengingat ke-$j - $serviceName',
          'Pelanggan: $contactName\nSudah $menit menit sejak pengingat pertama. Belum ditindaklanjuti.',
        );
      }
    }
  }

  static Future<void> _scheduleNotification(
    int notifId,
    tz.TZDateTime scheduledDate,
    String title,
    String body,
  ) async {
    const details = NotificationDetails(android: _androidDetails);

    try {
      await _plugin!.zonedSchedule(
        notifId,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
      debugPrint('[NotifService] Scheduled #$notifId at $scheduledDate');
    } catch (e) {
      debugPrint('[NotifService] exactAllowWhileIdle failed: $e');
      try {
        await _plugin!.zonedSchedule(
          notifId,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
        debugPrint('[NotifService] Fallback inexact #$notifId');
      } catch (e2) {
        debugPrint('[NotifService] Fallback also failed: $e2');
      }
    }
  }

  static Future<void> cancelReminder(ReminderModel reminder) async {
    if (!_supported || _plugin == null) return;
    // Cancel semua: recurring schedules + follow-up alarms
    final totalIds = _maxFutureSchedules * _idsPerSchedule;
    for (var i = 0; i < totalIds; i++) {
      await _plugin!
          .cancel((reminder.notificationId + i) % 2147483647);
    }
  }

  static Future<void> cancelAll() async {
    if (!_supported || _plugin == null) return;
    await _plugin!.cancelAll();
  }

  static Future<void> rescheduleAll(List<ReminderModel> reminders) async {
    if (!_supported) return;
    await init();
    await _plugin!.cancelAll();
    for (final r in reminders) {
      if (r.status == ReminderStatus.pending) {
        await scheduleReminder(r);
      }
    }
  }

  /// Cek apakah ada notifikasi yang terjadwal (untuk debugging)
  static Future<List<PendingNotificationRequest>> getPending() async {
    if (!_supported || _plugin == null) return [];
    return _plugin!.pendingNotificationRequests();
  }
}
