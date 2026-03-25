import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder_model.dart';

class NotificationService {
  static FlutterLocalNotificationsPlugin? _plugin;
  static bool _initialized = false;

  /// Jumlah notifikasi ke depan untuk pengingat berulang
  static const _maxFutureSchedules = 12;

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

    final success = await _plugin!.initialize(initSettings);
    debugPrint('[NotifService] init result: $success');
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    if (!_supported || _plugin == null) return false;
    final android = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;

    // Request POST_NOTIFICATIONS permission (Android 13+)
    final granted = await android.requestNotificationsPermission();
    debugPrint('[NotifService] POST_NOTIFICATIONS granted: $granted');

    // Request exact alarm permission (Android 12+)
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
      'Test Notifikasi',
      'Notifikasi pengingat berfungsi dengan baik!',
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
        await _scheduleSingle(
          reminder.notificationId,
          reminder.reminderDate,
          reminder.reminderHour,
          reminder.reminderMinute,
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
        // Unique ID per occurrence: base ID + offset
        final notifId =
            (reminder.notificationId + i) % 2147483647;
        await _scheduleNotification(
          notifId,
          scheduledDate,
          reminder.serviceName,
          reminder.contactName,
        );
      }

      // Maju ke bulan berikutnya
      date = DateTime(date.year, date.month + months, date.day);
    }
  }

  static Future<void> _scheduleSingle(
    int notifId,
    DateTime date,
    int hour,
    int minute,
    String serviceName,
    String contactName,
  ) async {
    final scheduledDate = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );

    final now = tz.TZDateTime.now(tz.local);
    if (scheduledDate.isBefore(now)) {
      debugPrint('[NotifService] Skipping past date: $scheduledDate');
      return;
    }

    debugPrint('[NotifService] Scheduling for: $scheduledDate (now: $now)');
    await _scheduleNotification(
        notifId, scheduledDate, serviceName, contactName);
  }

  static Future<void> _scheduleNotification(
    int notifId,
    tz.TZDateTime scheduledDate,
    String serviceName,
    String contactName,
  ) async {
    const details = NotificationDetails(android: _androidDetails);

    try {
      await _plugin!.zonedSchedule(
        notifId,
        'Pengingat: $serviceName',
        '$contactName — saatnya $serviceName',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
      debugPrint('[NotifService] Scheduled notif #$notifId at $scheduledDate');
    } catch (e) {
      debugPrint('[NotifService] exactAllowWhileIdle failed: $e');
      // Fallback ke inexact jika exact alarm tidak diizinkan
      try {
        await _plugin!.zonedSchedule(
          notifId,
          'Pengingat: $serviceName',
          '$contactName — saatnya $serviceName',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
        debugPrint('[NotifService] Fallback inexact scheduled #$notifId');
      } catch (e2) {
        debugPrint('[NotifService] Fallback also failed: $e2');
      }
    }
  }

  static Future<void> cancelReminder(ReminderModel reminder) async {
    if (!_supported || _plugin == null) return;
    // Cancel semua notifikasi recurring (base ID + 0..11)
    for (var i = 0; i < _maxFutureSchedules; i++) {
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
