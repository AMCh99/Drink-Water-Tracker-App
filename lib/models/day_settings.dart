import 'dart:convert';

class DaySettings {
  final int? id;
  final int dayStartHour; // 0-23
  final int dayStartMinute; // 0-59
  final int dayEndHour; // 0-23
  final int dayEndMinute; // 0-59
  final int dailyGoal; // cel dzienny w ml
  final String unit; // jednostka: 'ml' lub 'oz'
  final String themeMode; // 'system', 'light', 'dark'
  final String language; // 'pl', 'en'
  final List<String> notificationTimes; // lista godzin HH:mm
  final bool soundsEnabled; // czy efekty dźwiękowe są włączone

  DaySettings({
    this.id,
    required this.dayStartHour,
    required this.dayStartMinute,
    required this.dayEndHour,
    required this.dayEndMinute,
    required this.dailyGoal,
    this.unit = 'ml',
    this.themeMode = 'system',
    this.language = 'pl',
    List<String>? notificationTimes,
    this.soundsEnabled = true,
  }) : notificationTimes = notificationTimes ?? const [];

  static List<String> _normalizeNotificationTimes(List<String> times) {
    final normalized = times
        .map((time) => time.trim())
        .where((time) => RegExp(r'^\d{2}:\d{2}$').hasMatch(time))
        .toSet()
        .toList();
    normalized.sort();
    return normalized;
  }

  DaySettings copyWith({
    int? id,
    int? dayStartHour,
    int? dayStartMinute,
    int? dayEndHour,
    int? dayEndMinute,
    int? dailyGoal,
    String? unit,
    String? themeMode,
    String? language,
    List<String>? notificationTimes,
    bool? soundsEnabled,
  }) {
    return DaySettings(
      id: id ?? this.id,
      dayStartHour: dayStartHour ?? this.dayStartHour,
      dayStartMinute: dayStartMinute ?? this.dayStartMinute,
      dayEndHour: dayEndHour ?? this.dayEndHour,
      dayEndMinute: dayEndMinute ?? this.dayEndMinute,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      unit: unit ?? this.unit,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notificationTimes: notificationTimes ?? this.notificationTimes,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dayStartHour': dayStartHour,
      'dayStartMinute': dayStartMinute,
      'dayEndHour': dayEndHour,
      'dayEndMinute': dayEndMinute,
      'dailyGoal': dailyGoal,
      'unit': unit,
      'themeMode': themeMode,
      'language': language,
      'notificationTimes': jsonEncode(
        _normalizeNotificationTimes(notificationTimes),
      ),
      'soundsEnabled': soundsEnabled ? 1 : 0,
    };
  }

  factory DaySettings.fromMap(Map<String, dynamic> map) {
    final rawNotificationTimes = map['notificationTimes'];
    List<String> notificationTimes = [];
    if (rawNotificationTimes is String && rawNotificationTimes.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawNotificationTimes);
        if (decoded is List) {
          notificationTimes = decoded
              .whereType<String>()
              .map((time) => time.trim())
              .toList();
        }
      } catch (_) {
        notificationTimes = [];
      }
    }

    return DaySettings(
      id: map['id'] as int?,
      dayStartHour: map['dayStartHour'] as int,
      dayStartMinute: map['dayStartMinute'] as int,
      dayEndHour: map['dayEndHour'] as int,
      dayEndMinute: map['dayEndMinute'] as int,
      dailyGoal: map['dailyGoal'] as int? ?? 2000,
      unit: map['unit'] as String? ?? 'ml',
      themeMode: map['themeMode'] as String? ?? 'system',
      language: map['language'] as String? ?? 'pl',
      notificationTimes: _normalizeNotificationTimes(notificationTimes),
      soundsEnabled: (map['soundsEnabled'] as int? ?? 1) == 1,
    );
  }

  // Konwersja ml na oz (1 oz = 29.5735 ml)
  double mlToOz(int ml) {
    return ml / 29.5735;
  }

  // Konwersja oz na ml
  int ozToMl(double oz) {
    return (oz * 29.5735).round();
  }

  String formatAmount(int ml) {
    if (unit == 'oz') {
      return '${mlToOz(ml).toStringAsFixed(1)} oz';
    }
    return '$ml ml';
  }

  // Domyślne ustawienia: dzień 6:00-22:00, cel 2000ml
  factory DaySettings.defaultSettings() {
    return DaySettings(
      dayStartHour: 6,
      dayStartMinute: 0,
      dayEndHour: 22,
      dayEndMinute: 0,
      dailyGoal: 2000,
      unit: 'ml',
      themeMode: 'system',
      language: 'pl',
      notificationTimes: ['09:00', '13:00', '17:00'],
      soundsEnabled: true,
    );
  }
}
