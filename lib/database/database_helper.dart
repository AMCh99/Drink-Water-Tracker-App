import 'dart:io';
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
      version: 6,
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
        themeMode TEXT NOT NULL DEFAULT 'system'
      )
    ''');

    await db.execute('''
      CREATE TABLE water_buttons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        milliliters INTEGER NOT NULL,
        iconCodePoint INTEGER NOT NULL,
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
          order_index INTEGER NOT NULL,
          isFavorite INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Wstaw domyślne przyciski
      for (var button in WaterButton.defaultButtons()) {
        await db.insert('water_buttons', {
          'milliliters': button.milliliters,
          'iconCodePoint': button.icon.codePoint,
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
  }

  // CRUD dla water_entries
  Future<int> insertWaterEntry(WaterEntry entry) async {
    final db = await database;
    print('DEBUG: Dodaję wpis: ${entry.milliliters}ml o ${entry.timestamp}');
    final id = await db.insert('water_entries', entry.toMap());
    print('DEBUG: Wpis dodany z ID: $id');
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

    print(
      'DEBUG: Szukam wpisów od $startOfDay do $endOfDay (reset o ${resetTime.hour}:${resetTime.minute})',
    );

    final results = await db.query(
      'water_entries',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    print('DEBUG: Znaleziono ${results.length} wpisów');
    return results.map((map) => WaterEntry.fromMap(map)).toList();
  }

  // Oblicza godzinę resetu licznika (3 godziny po końcu dnia)
  TimeOfDay _calculateResetTime(DaySettings settings) {
    int resetHour = settings.dayEndHour + 3;
    int resetMinute = settings.dayEndMinute;

    // Normalizujemy godziny (np. 22+3=25 -> 1:00)
    resetHour = resetHour % 24;

    print(
      'DEBUG: Reset o godzinie $resetHour:${resetMinute.toString().padLeft(2, '0')} (3h po końcu dnia ${settings.dayEndHour}:${settings.dayEndMinute.toString().padLeft(2, '0')})',
    );

    return TimeOfDay(hour: resetHour, minute: resetMinute);
  }

  // Sprawdza status wpisu względem dnia użytkownika
  String getEntryStatus(DateTime entryTime, DaySettings settings) {
    final now = DateTime.now();
    final resetTime = _calculateResetTime(settings);

    // Określamy początek i koniec aktywnego dnia
    DateTime dayStart = DateTime(
      now.year,
      now.month,
      now.day,
      settings.dayStartHour,
      settings.dayStartMinute,
    );

    DateTime dayEnd = DateTime(
      now.year,
      now.month,
      now.day,
      settings.dayEndHour,
      settings.dayEndMinute,
    );

    // Jeśli kończy się wcześniej niż zaczyna, to koniec jest w tym samym dniu
    if (settings.dayEndHour > settings.dayStartHour) {
      // Normalny dzień w ciągu jednej doby
      if (entryTime.isBefore(dayStart)) {
        return 'early'; // Przed początkiem dnia
      } else if (entryTime.isAfter(dayEnd)) {
        return 'late'; // Po końcu dnia
      } else {
        return 'normal'; // W normalnych godzinach
      }
    } else {
      // Dzień przechodzi przez północ
      if (entryTime.isAfter(dayEnd) && entryTime.isBefore(dayStart)) {
        // Jest między końcem a początkiem (w nocy)
        if (entryTime.hour < resetTime.hour ||
            (entryTime.hour == resetTime.hour &&
                entryTime.minute < resetTime.minute)) {
          return 'late'; // Po końcu poprzedniego dnia
        } else {
          return 'early'; // Przed początkiem nowego dnia
        }
      } else {
        return 'normal'; // W normalnych godzinach
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

  Future close() async {
    final db = await database;
    db.close();
  }
}
