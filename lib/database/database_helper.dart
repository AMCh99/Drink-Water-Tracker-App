import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/water_entry.dart';
import '../models/day_settings.dart';
import '../models/water_button.dart';
import '../models/daily_stats.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('water_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Inicjalizacja dla platform desktop (macOS, Linux, Windows)
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 12,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE water_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        milliliters INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE day_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dayStartHour INTEGER NOT NULL,
        dayStartMinute INTEGER NOT NULL,
        dayEndHour INTEGER NOT NULL,
        dayEndMinute INTEGER NOT NULL,
        dailyGoal INTEGER NOT NULL DEFAULT 2000,
        unit TEXT NOT NULL DEFAULT 'ml',
        themeMode TEXT NOT NULL DEFAULT 'system',
        language TEXT NOT NULL DEFAULT 'pl',
        notificationTimes TEXT NOT NULL DEFAULT '[]',
        soundsEnabled INTEGER NOT NULL DEFAULT 1,
        notificationsEnabled INTEGER NOT NULL DEFAULT 1,
        notificationIntervalMinutes INTEGER NOT NULL DEFAULT 60
      )
    ''');

    await db.execute('''
      CREATE TABLE water_buttons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        milliliters INTEGER NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        iconAsset TEXT,
        order_index INTEGER NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Wstaw domyślne ustawienia
    await db.insert('day_settings', DaySettings.defaultSettings().toMap());

    // Wstaw domyślne przyciski
    for (var button in WaterButton.defaultButtons()) {
      await db.insert('water_buttons', {
        'milliliters': button.milliliters,
        'iconCodePoint': button.icon.codePoint,
        'iconAsset': button.assetPath,
        'order_index': button.order,
        'isFavorite': button.isFavorite ? 1 : 0,
      });
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Dodaj kolumnę dailyGoal do istniejącej tabeli
      await db.execute('''
        ALTER TABLE day_settings ADD COLUMN dailyGoal INTEGER NOT NULL DEFAULT 2000
      ''');
    }

    if (oldVersion < 3) {
      // Dodaj tabelę water_buttons
      await db.execute('''
        CREATE TABLE water_buttons (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          milliliters INTEGER NOT NULL,
          iconCodePoint INTEGER NOT NULL,
          iconAsset TEXT,
          order_index INTEGER NOT NULL,
          isFavorite INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Wstaw domyślne przyciski
      for (var button in WaterButton.defaultButtons()) {
        await db.insert('water_buttons', {
          'milliliters': button.milliliters,
          'iconCodePoint': button.icon.codePoint,
          'iconAsset': button.assetPath,
          'order_index': button.order,
          'isFavorite': button.isFavorite ? 1 : 0,
        });
      }
    }

    if (oldVersion < 4) {
      // Dodaj kolumnę isFavorite do istniejącej tabeli water_buttons
      await db.execute('''
        ALTER TABLE water_buttons ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0
      ''');
    }

    if (oldVersion < 5) {
      // Dodaj kolumnę unit do istniejącej tabeli day_settings
      await db.execute('''
        ALTER TABLE day_settings ADD COLUMN unit TEXT NOT NULL DEFAULT 'ml'
      ''');
    }

    if (oldVersion < 6) {
      // Dodaj kolumnę themeMode do istniejącej tabeli day_settings
      await db.execute('''
        ALTER TABLE day_settings ADD COLUMN themeMode TEXT NOT NULL DEFAULT 'system'
      ''');
    }

    if (oldVersion < 7) {
      // Dodaj kolumnę language do istniejącej tabeli day_settings
      await db.execute('''
        ALTER TABLE day_settings ADD COLUMN language TEXT NOT NULL DEFAULT 'pl'
      ''');
    }

    if (oldVersion < 8) {
      // Dodaj kolumny powiadomień do istniejącej tabeli day_settings
      await db.execute('''
        ALTER TABLE day_settings ADD COLUMN notificationsEnabled INTEGER NOT NULL DEFAULT 1
      ''');
      await db.execute('''
        ALTER TABLE day_settings ADD COLUMN notificationIntervalMinutes INTEGER NOT NULL DEFAULT 60
      ''');
    }

    if (oldVersion < 9) {
      // Dodaj nowe rozmiary przycisków (100, 150, 330, 1500)
      // Najpierw sprawdź jakie rozmiary już istnieją
      final existing = await db.query('water_buttons');
      final existingSizes = existing
          .map((e) => e['milliliters'] as int)
          .toSet();

      // Pobierz najwyższy order_index
      int maxOrder = 0;
      for (final row in existing) {
        final order = row['order_index'] as int;
        if (order > maxOrder) maxOrder = order;
      }

      final newSizes = [100, 150, 330, 1500];
      for (final ml in newSizes) {
        if (!existingSizes.contains(ml)) {
          maxOrder++;
          final icon = WaterButton.getIconForMilliliters(ml);
          await db.insert('water_buttons', {
            'milliliters': ml,
            'iconCodePoint': icon.codePoint,
            'iconAsset': WaterButton.getAssetForMilliliters(ml),
            'order_index': maxOrder,
            'isFavorite': 0,
          });
        }
      }

      // Zmień kolejność przycisków rosnąco po ml
      final allButtons = await db.query(
        'water_buttons',
        orderBy: 'milliliters ASC',
      );
      for (int i = 0; i < allButtons.length; i++) {
        await db.update(
          'water_buttons',
          {'order_index': i + 1},
          where: 'id = ?',
          whereArgs: [allButtons[i]['id']],
        );
      }
    }

    if (oldVersion < 10) {
      await db.execute('''
        ALTER TABLE day_settings ADD COLUMN soundsEnabled INTEGER NOT NULL DEFAULT 1
      ''');
    }

    if (oldVersion < 11) {
      await db.execute('''
        ALTER TABLE day_settings ADD COLUMN notificationTimes TEXT NOT NULL DEFAULT '[]'
      ''');

      final rows = await db.query('day_settings', limit: 1);
      if (rows.isNotEmpty) {
        final row = rows.first;
        final notificationsEnabled =
            (row['notificationsEnabled'] as int? ?? 1) == 1;
        if (notificationsEnabled) {
          final dayStartHour = row['dayStartHour'] as int;
          final dayStartMinute = row['dayStartMinute'] as int;
          final dayEndHour = row['dayEndHour'] as int;
          final dayEndMinute = row['dayEndMinute'] as int;
          final intervalMinutes =
              row['notificationIntervalMinutes'] as int? ?? 60;

          final startMinutes = dayStartHour * 60 + dayStartMinute + 60;
          final endMinutes = dayEndHour * 60 + dayEndMinute - 120;
          final legacyTimes = <String>[];

          if (startMinutes < endMinutes) {
            int currentMinutes = startMinutes;
            while (currentMinutes <= endMinutes) {
              final hour = currentMinutes ~/ 60;
              final minute = currentMinutes % 60;
              legacyTimes.add(
                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
              );
              currentMinutes += intervalMinutes;
            }
          }

          await db.update(
            'day_settings',
            {'notificationTimes': jsonEncode(legacyTimes)},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
      }
    }

    if (oldVersion < 12) {
      await db.execute('''
        ALTER TABLE water_buttons ADD COLUMN iconAsset TEXT
      ''');
    }
  }

  // CRUD dla water_entries
  Future<int> insertWaterEntry(WaterEntry entry) async {
    final db = await database;
    debugPrint(
      'DEBUG: Dodaję wpis: ${entry.milliliters}ml o ${entry.timestamp}',
    );
    final id = await db.insert('water_entries', entry.toMap());
    debugPrint('DEBUG: Wpis dodany z ID: $id');
    return id;
  }

  Future<WaterEntry?> getLastWaterEntry() async {
    final db = await database;
    final results = await db.query(
      'water_entries',
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return WaterEntry.fromMap(results.first);
  }

  Future<List<WaterEntry>> getWaterEntriesForDay(DateTime day) async {
    final db = await database;
    final settings = await getDaySettings();

    // Obliczamy godzinę resetu (środek nocy między końcem a początkiem dnia)
    final resetTime = _calculateResetTime(settings);

    // Określamy zakres aktualnego dnia
    DateTime startOfDay;
    DateTime endOfDay;

    // Jeśli aktualna godzina jest przed resetem, to należymy do poprzedniego dnia
    if (day.hour < resetTime.hour ||
        (day.hour == resetTime.hour && day.minute < resetTime.minute)) {
      // Reset poprzedniego dnia
      final previousReset = DateTime(
        day.year,
        day.month,
        day.day - 1,
        resetTime.hour,
        resetTime.minute,
      );

      // Aktualny reset
      final currentReset = DateTime(
        day.year,
        day.month,
        day.day,
        resetTime.hour,
        resetTime.minute,
      );

      startOfDay = previousReset;
      endOfDay = currentReset;
    } else {
      // Reset dzisiaj
      final currentReset = DateTime(
        day.year,
        day.month,
        day.day,
        resetTime.hour,
        resetTime.minute,
      );

      // Reset jutro
      final nextReset = DateTime(
        day.year,
        day.month,
        day.day + 1,
        resetTime.hour,
        resetTime.minute,
      );

      startOfDay = currentReset;
      endOfDay = nextReset;
    }

    debugPrint(
      'DEBUG: Szukam wpisów od $startOfDay do $endOfDay (reset o ${resetTime.hour}:${resetTime.minute})',
    );

    final results = await db.query(
      'water_entries',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    debugPrint('DEBUG: Znaleziono ${results.length} wpisów');
    return results.map((map) => WaterEntry.fromMap(map)).toList();
  }

  // Oblicza godzinę resetu licznika (3 godziny po końcu dnia)
  TimeOfDay _calculateResetTime(DaySettings settings) {
    int resetHour = settings.dayEndHour + 3;
    int resetMinute = settings.dayEndMinute;

    // Normalizujemy godziny (np. 22+3=25 -> 1:00)
    resetHour = resetHour % 24;

    debugPrint(
      'DEBUG: Reset o godzinie $resetHour:${resetMinute.toString().padLeft(2, '0')} (3h po końcu dnia ${settings.dayEndHour}:${settings.dayEndMinute.toString().padLeft(2, '0')})',
    );

    return TimeOfDay(hour: resetHour, minute: resetMinute);
  }

  // Sprawdza status wpisu względem dnia użytkownika
  // 'normal' — w godzinach dnia (dayStart–dayEnd)
  // 'late' — po końcu dnia, przed resetem (dayEnd–reset) — "Pora spać!"
  // 'early' — po resecie, przed początkiem dnia (reset–dayStart) — "Wcześnie!"
  String getEntryStatus(DateTime entryTime, DaySettings settings) {
    final resetTime = _calculateResetTime(settings);

    // Konwertujemy wszystko na minuty od północy do łatwego porównania
    final entryMinutes = entryTime.hour * 60 + entryTime.minute;
    final startMinutes = settings.dayStartHour * 60 + settings.dayStartMinute;
    final endMinutes = settings.dayEndHour * 60 + settings.dayEndMinute;
    final resetMinutes = resetTime.hour * 60 + resetTime.minute;

    // Normalny dzień (start < end, np. 6:00–22:00)
    if (startMinutes < endMinutes) {
      if (entryMinutes >= startMinutes && entryMinutes <= endMinutes) {
        return 'normal';
      }

      // Poza godzinami dnia — rozróżniamy late vs early
      // Reset jest po północy (np. 01:00) gdy dayEnd + 3h > 24
      if (resetMinutes < startMinutes) {
        // Reset jest po północy (np. koniec 22:00, reset 01:00, start 06:00)
        // late: od dayEnd do północy ORAZ od północy do reset
        // early: od reset do dayStart
        if (entryMinutes > endMinutes || entryMinutes < resetMinutes) {
          return 'late';
        } else {
          return 'early';
        }
      } else {
        // Reset jest przed północą (np. koniec 18:00, reset 21:00, start 06:00)
        // late: od dayEnd do reset
        // early: od reset do dayStart (+ po północy do dayStart)
        if (entryMinutes > endMinutes && entryMinutes < resetMinutes) {
          return 'late';
        } else {
          return 'early';
        }
      }
    } else {
      // Dzień przechodzi przez północ (start > end, np. 22:00–06:00)
      // normal: od start do północy ORAZ od północy do end
      if (entryMinutes >= startMinutes || entryMinutes <= endMinutes) {
        return 'normal';
      }
      // Poza normalnymi godzinami: od end do start
      if (entryMinutes > endMinutes && entryMinutes < resetMinutes) {
        return 'late';
      } else {
        return 'early';
      }
    }
  }

  Future<int> getTotalWaterForDay(DateTime day) async {
    final entries = await getWaterEntriesForDay(day);
    return entries.fold<int>(0, (sum, entry) => sum + entry.milliliters);
  }

  Future<int> deleteWaterEntry(int id) async {
    final db = await database;
    return await db.delete('water_entries', where: 'id = ?', whereArgs: [id]);
  }

  // Statystyki tygodniowe - zwraca dane z ostatnich 7 dni
  Future<List<DailyStats>> getWeeklyStats() async {
    final settings = await getDaySettings();
    final now = DateTime.now();
    final List<DailyStats> stats = [];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i, 12, 0);
      final total = await getTotalWaterForDay(day);
      stats.add(
        DailyStats(
          date: DateTime(day.year, day.month, day.day),
          totalMl: total,
          goalMl: settings.dailyGoal,
        ),
      );
    }

    return stats;
  }

  Future<List<DailyStats>> getMonthlyStats(int year, int month) async {
    final settings = await getDaySettings();
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<DailyStats> stats = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      // Nie pobieraj danych dla przyszłych dni
      if (date.isAfter(today)) {
        stats.add(
          DailyStats(date: date, totalMl: -1, goalMl: settings.dailyGoal),
        );
        continue;
      }
      final total = await getTotalWaterForDay(
        DateTime(year, month, day, 12, 0),
      );
      stats.add(
        DailyStats(date: date, totalMl: total, goalMl: settings.dailyGoal),
      );
    }

    return stats;
  }

  // CRUD dla day_settings
  Future<DaySettings> getDaySettings() async {
    final db = await database;
    final results = await db.query('day_settings', limit: 1);

    if (results.isEmpty) {
      // Jeśli nie ma ustawień, wstaw domyślne
      final defaultSettings = DaySettings.defaultSettings();
      await db.insert('day_settings', defaultSettings.toMap());
      return defaultSettings;
    }

    return DaySettings.fromMap(results.first);
  }

  Future<int> updateDaySettings(DaySettings settings) async {
    final db = await database;
    return await db.update(
      'day_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }

  // CRUD dla water_buttons
  Future<List<WaterButton>> getWaterButtons() async {
    final db = await database;
    final results = await db.query('water_buttons', orderBy: 'order_index ASC');

    final buttons = results
        .map(
          (map) => WaterButton(
            id: map['id'] as int?,
            milliliters: map['milliliters'] as int,
            icon: IconData(
              map['iconCodePoint'] as int,
              fontFamily: 'MaterialIcons',
            ),
            order: map['order_index'] as int,
            isFavorite: (map['isFavorite'] as int?) == 1,
            assetPath:
                map['iconAsset'] as String? ??
                WaterButton.getClosestAsset(map['milliliters'] as int),
          ),
        )
        .toList();

    // Sortuj: ulubione najpierw, potem reszta
    buttons.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return a.order.compareTo(b.order);
    });

    return buttons;
  }

  Future<int> insertWaterButton(WaterButton button) async {
    final db = await database;
    return await db.insert('water_buttons', {
      'milliliters': button.milliliters,
      'iconCodePoint': button.icon.codePoint,
      'iconAsset': button.assetPath,
      'order_index': button.order,
      'isFavorite': button.isFavorite ? 1 : 0,
    });
  }

  Future<int> deleteWaterButton(int id) async {
    final db = await database;
    return await db.delete('water_buttons', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateWaterButton(WaterButton button) async {
    final db = await database;
    return await db.update(
      'water_buttons',
      {
        'milliliters': button.milliliters,
        'iconCodePoint': button.icon.codePoint,
        'iconAsset': button.assetPath,
        'order_index': button.order,
        'isFavorite': button.isFavorite ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [button.id],
    );
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'water_buttons',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Seria dni (streak) — ile kolejnych dni cel został osiągnięty
  Future<int> getCurrentStreak() async {
    final settings = await getDaySettings();
    final now = DateTime.now();
    int streak = 0;

    // Sprawdzamy wstecz od wczoraj (dzisiaj się jeszcze liczy jako "w trakcie")
    // Ale jeśli dzisiaj cel jest osiągnięty, zaczynamy od dzisiaj
    for (int i = 0; i <= 365; i++) {
      final day = DateTime(now.year, now.month, now.day - i, 12, 0);
      final total = await getTotalWaterForDay(day);

      if (total >= settings.dailyGoal) {
        streak++;
      } else {
        // Dzisiaj jeszcze może być w trakcie, nie przerywaj
        if (i == 0) continue;
        break;
      }
    }

    return streak;
  }

  // Statystyki roczne — dla widoku jak GitHub contributions
  Future<List<DailyStats>> getYearlyStats(int year) async {
    final settings = await getDaySettings();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<DailyStats> stats = [];

    // Pobierz wszystkie dane z bazy za dany rok jednorazowo (optymalizacja)
    final db = await database;
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    final results = await db.query(
      'water_entries',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfYear.toIso8601String(), endOfYear.toIso8601String()],
    );

    // Grupuj wpisy wg dnia
    final Map<String, int> dailyTotals = {};
    for (final row in results) {
      final timestamp = DateTime.parse(row['timestamp'] as String);
      final dayKey =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      dailyTotals[dayKey] =
          (dailyTotals[dayKey] ?? 0) + (row['milliliters'] as int);
    }

    // Buduj listę statystyk dla każdego dnia w roku
    final daysInYear = DateTime(
      year + 1,
      1,
      1,
    ).difference(DateTime(year, 1, 1)).inDays;
    for (int d = 0; d < daysInYear; d++) {
      final date = DateTime(year, 1, 1 + d);
      if (date.isAfter(today)) {
        stats.add(
          DailyStats(date: date, totalMl: -1, goalMl: settings.dailyGoal),
        );
        continue;
      }
      final dayKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final total = dailyTotals[dayKey] ?? 0;
      stats.add(
        DailyStats(date: date, totalMl: total, goalMl: settings.dailyGoal),
      );
    }

    return stats;
  }

  // Pobierz wszystkie wpisy do eksportu
  Future<List<Map<String, dynamic>>> getAllEntriesForExport() async {
    final db = await database;
    return await db.query('water_entries', orderBy: 'timestamp ASC');
  }

  // Średnia tygodniowa — ostatnie N tygodni
  Future<List<Map<String, dynamic>>> getWeeklyAverages({int weeks = 8}) async {
    final settings = await getDaySettings();
    final now = DateTime.now();
    final List<Map<String, dynamic>> averages = [];

    for (int w = weeks - 1; w >= 0; w--) {
      final weekEnd = DateTime(now.year, now.month, now.day - (w * 7));
      final weekStart = DateTime(weekEnd.year, weekEnd.month, weekEnd.day - 6);

      int totalMl = 0;
      int daysWithData = 0;
      int daysGoalReached = 0;

      for (int d = 0; d < 7; d++) {
        final day = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + d,
          12,
          0,
        );
        // Nie licz przyszłych dni
        if (day.isAfter(now)) break;
        final dayTotal = await getTotalWaterForDay(day);
        totalMl += dayTotal;
        if (dayTotal > 0) daysWithData++;
        if (dayTotal >= settings.dailyGoal) daysGoalReached++;
      }

      averages.add({
        'weekStart': weekStart,
        'weekEnd': weekEnd,
        'totalMl': totalMl,
        'avgMl': daysWithData > 0 ? (totalMl / daysWithData).round() : 0,
        'daysWithData': daysWithData,
        'daysGoalReached': daysGoalReached,
      });
    }

    return averages;
  }

  // Średnia miesięczna — ostatnie N miesięcy
  Future<List<Map<String, dynamic>>> getMonthlyAverages({
    int months = 6,
  }) async {
    final settings = await getDaySettings();
    final now = DateTime.now();
    final List<Map<String, dynamic>> averages = [];

    for (int m = months - 1; m >= 0; m--) {
      final monthDate = DateTime(now.year, now.month - m, 1);
      final year = monthDate.year;
      final month = monthDate.month;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final today = DateTime(now.year, now.month, now.day);

      int totalMl = 0;
      int daysWithData = 0;
      int daysGoalReached = 0;

      for (int d = 1; d <= daysInMonth; d++) {
        final day = DateTime(year, month, d, 12, 0);
        if (day.isAfter(today)) break;
        final dayTotal = await getTotalWaterForDay(day);
        totalMl += dayTotal;
        if (dayTotal > 0) daysWithData++;
        if (dayTotal >= settings.dailyGoal) daysGoalReached++;
      }

      averages.add({
        'month': monthDate,
        'totalMl': totalMl,
        'avgMl': daysWithData > 0 ? (totalMl / daysWithData).round() : 0,
        'daysWithData': daysWithData,
        'daysGoalReached': daysGoalReached,
      });
    }

    return averages;
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
