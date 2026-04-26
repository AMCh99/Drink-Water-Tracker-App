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
  final bool notificationsEnabled; // czy powiadomienia włączone
  final bool soundsEnabled; // czy efekty dźwiękowe są włączone
  final int
  notificationIntervalMinutes; // interwał w minutach: 15, 30, 60, 90, 120

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
    this.notificationsEnabled = true,
    this.soundsEnabled = true,
    this.notificationIntervalMinutes = 60,
  });

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
    bool? notificationsEnabled,
    bool? soundsEnabled,
    int? notificationIntervalMinutes,
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
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      notificationIntervalMinutes:
          notificationIntervalMinutes ?? this.notificationIntervalMinutes,
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
      'notificationsEnabled': notificationsEnabled ? 1 : 0,
      'soundsEnabled': soundsEnabled ? 1 : 0,
      'notificationIntervalMinutes': notificationIntervalMinutes,
    };
  }

  factory DaySettings.fromMap(Map<String, dynamic> map) {
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
      notificationsEnabled: (map['notificationsEnabled'] as int? ?? 1) == 1,
      soundsEnabled: (map['soundsEnabled'] as int? ?? 1) == 1,
      notificationIntervalMinutes:
          map['notificationIntervalMinutes'] as int? ?? 60,
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
      notificationsEnabled: true,
      soundsEnabled: true,
      notificationIntervalMinutes: 60,
    );
  }
}
