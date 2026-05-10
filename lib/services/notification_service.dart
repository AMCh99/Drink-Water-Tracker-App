import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/day_settings.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inicjalizacja serwisu powiadomień
  Future<void> init() async {
    if (_initialized) return;

    // Inicjalizacja stref czasowych
    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Warsaw'));
    }

    // Konfiguracja Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Konfiguracja iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    _initialized = true;
  }

  /// Prosi o uprawnienia do powiadomień (Android 13+, iOS)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      // Android 13+ — uprawnienie do wyświetlania powiadomień
      final notifGranted = await android?.requestNotificationsPermission();
      if (notifGranted != true) return false;

      // Android 12+ — uprawnienie do dokładnych alarmów
      final exactGranted = await android?.requestExactAlarmsPermission();
      // Jeśli brak zgody na dokładne alarmy, wróć false (użyjemy inexact)
      _canUseExactAlarms = exactGranted ?? false;
      return true;
    } else if (Platform.isIOS) {
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  bool _canUseExactAlarms = true;

  /// Planuje powiadomienia według konkretnych godzin ustawionych przez użytkownika.
  Future<void> scheduleReminders(DaySettings settings) async {
    // Anuluj wszystkie istniejące
    await cancelAll();

    if (settings.notificationTimes.isEmpty) return;

    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    for (int index = 0; index < settings.notificationTimes.length; index++) {
      final time = settings.notificationTimes[index];
      final scheduledDate = _nextScheduledDate(time);
      if (scheduledDate == null) continue;

      await _scheduleNotification(
        id: 1000 + index,
        scheduledDate: scheduledDate,
        title: _getTitle(settings.language),
        body: _getBody(settings.language),
      );
    }
  }

  /// Anuluj wszystkie zaplanowane powiadomienia
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Planuje pojedyncze powiadomienie
  Future<void> _scheduleNotification({
    required int id,
    required tz.TZDateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'water_reminder',
      'Przypomnienia o piciu wody',
      channelDescription: 'Regularne przypomnienia o piciu wody',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: _canUseExactAlarms
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime? _nextScheduledDate(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  String _getTitle(String language) {
    return language == 'pl' ? '💧 Czas na wodę!' : '💧 Time for water!';
  }

  String _getBody(String language) {
    return language == 'pl'
        ? 'Dawno nie piłeś — napij się wody!'
        : "You haven't drunk in a while — have some water!";
  }

}
