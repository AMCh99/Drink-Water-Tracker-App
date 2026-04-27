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

  /// Planuje powiadomienia-przypomnienia na bieżący i następny dzień
  /// Okno: dayStart + 1h do dayEnd - 2h
  /// Interwał: notificationIntervalMinutes
  Future<void> scheduleReminders(DaySettings settings) async {
    // Anuluj wszystkie istniejące
    await cancelAll();

    if (!settings.notificationsEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final intervalMinutes = settings.notificationIntervalMinutes;

    // Oblicz okno powiadomień
    final windowStartMinutes =
        settings.dayStartHour * 60 + settings.dayStartMinute + 60; // +1h
    final windowEndMinutes =
        settings.dayEndHour * 60 + settings.dayEndMinute - 120; // -2h

    if (windowStartMinutes >= windowEndMinutes) return; // brak okna

    // Zaplanuj na dzisiaj i jutro
    for (int dayOffset = 0; dayOffset <= 1; dayOffset++) {
      final baseDate = now.add(Duration(days: dayOffset));
      int notificationId = dayOffset * 100; // 0-99 dziś, 100-199 jutro

      int currentMinutes = windowStartMinutes;
      while (currentMinutes <= windowEndMinutes) {
        final hour = currentMinutes ~/ 60;
        final minute = currentMinutes % 60;

        final scheduledDate = tz.TZDateTime(
          tz.local,
          baseDate.year,
          baseDate.month,
          baseDate.day,
          hour,
          minute,
        );

        // Planuj tylko przyszłe powiadomienia
        if (scheduledDate.isAfter(now)) {
          await _scheduleNotification(
            id: notificationId,
            scheduledDate: scheduledDate,
            title: _getTitle(settings.language),
            body: _getBody(settings.language),
          );
        }

        notificationId++;
        currentMinutes += intervalMinutes;
      }
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
      matchDateTimeComponents: null,
    );
  }

  String _getTitle(String language) {
    return language == 'pl' ? '💧 Czas na wodę!' : '💧 Time for water!';
  }

  String _getBody(String language) {
    return language == 'pl'
        ? 'Dawno nie piłeś — napij się wody!'
        : "You haven't drunk in a while — have some water!";
  }

  /// Lista dostępnych interwałów (w minutach)
  static const List<int> availableIntervals = [15, 30, 60, 90, 120];

  /// Opis interwału (do wyświetlenia w UI)
  static String intervalLabel(int minutes, String language) {
    switch (minutes) {
      case 15:
        return language == 'pl' ? 'Co 15 minut' : 'Every 15 minutes';
      case 30:
        return language == 'pl' ? 'Co 30 minut' : 'Every 30 minutes';
      case 60:
        return language == 'pl' ? 'Co 1 godzinę' : 'Every 1 hour';
      case 90:
        return language == 'pl' ? 'Co 1,5 godziny' : 'Every 1.5 hours';
      case 120:
        return language == 'pl' ? 'Co 2 godziny' : 'Every 2 hours';
      default:
        return language == 'pl' ? 'Co $minutes min' : 'Every $minutes min';
    }
  }
}
