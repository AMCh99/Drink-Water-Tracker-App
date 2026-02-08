import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/database_helper.dart';
import 'models/water_entry.dart';
import 'models/day_settings.dart';
import 'screens/settings_screen.dart';
import 'screens/add_water_screen.dart';
import 'utils/widget_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final settings = await DatabaseHelper.instance.getDaySettings();
    setState(() {
      _themeMode = _stringToThemeMode(settings.themeMode);
      _isLoading = false;
    });
  }

  ThemeMode _stringToThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  Future<void> _toggleTheme() async {
    final newThemeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    setState(() {
      _themeMode = newThemeMode;
    });

    // Zapisz do bazy danych
    final settings = await DatabaseHelper.instance.getDaySettings();
    final updatedSettings = DaySettings(
      id: settings.id,
      dayStartHour: settings.dayStartHour,
      dayStartMinute: settings.dayStartMinute,
      dayEndHour: settings.dayEndHour,
      dayEndMinute: settings.dayEndMinute,
      dailyGoal: settings.dailyGoal,
      unit: settings.unit,
      themeMode: _themeModeToString(newThemeMode),
    );
    await DatabaseHelper.instance.updateDaySettings(updatedSettings);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'Drink water',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: WaterTrackerHome(onToggleTheme: _toggleTheme),
    );
  }
}

class WaterTrackerHome extends StatefulWidget {
  final Future<void> Function() onToggleTheme;

  const WaterTrackerHome({super.key, required this.onToggleTheme});

  @override
  State<WaterTrackerHome> createState() => _WaterTrackerHomeState();
}

class _WaterTrackerHomeState extends State<WaterTrackerHome>
    with WidgetsBindingObserver {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  int _totalWater = 0;
  List<WaterEntry> _entries = [];
  DaySettings? _daySettings;
  WaterEntry? _lastEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Odśwież dane gdy aplikacja wraca na pierwszy plan
      _loadData();
    }
  }

  Future<void> _loadData() async {
    print('DEBUG: Ładuję dane...');
    final total = await _dbHelper.getTotalWaterForDay(DateTime.now());
    final entries = await _dbHelper.getWaterEntriesForDay(DateTime.now());
    final settings = await _dbHelper.getDaySettings();
    final lastEntry = await _dbHelper.getLastWaterEntry();

    print(
      'DEBUG: Total: $total, Entries: ${entries.length}, Settings: ${settings.dayStartHour}:${settings.dayStartMinute} - ${settings.dayEndHour}:${settings.dayEndMinute}',
    );

    setState(() {
      _totalWater = total;
      _entries = entries;
      _daySettings = settings;
      _lastEntry = lastEntry;
    });

    // Zaktualizuj widget
    await WidgetHelper.updateWidget();
  }

  Future<void> _addLastAmount() async {
    if (_lastEntry == null) return;

    final entry = WaterEntry(
      timestamp: DateTime.now(),
      milliliters: _lastEntry!.milliliters,
    );
    await _dbHelper.insertWaterEntry(entry);
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dodano ${_daySettings?.formatAmount(_lastEntry!.milliliters) ?? "${_lastEntry!.milliliters} ml"}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addAgain(int milliliters) async {
    final entry = WaterEntry(
      timestamp: DateTime.now(),
      milliliters: milliliters,
    );
    await _dbHelper.insertWaterEntry(entry);
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dodano ${_daySettings?.formatAmount(milliliters) ?? "$milliliters ml"}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openAddWaterScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddWaterScreen()),
    );

    // Jeśli result == true, oznacza że woda została dodana
    if (result == true) {
      await _loadData();
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          onToggleTheme: widget.onToggleTheme,
          currentBrightness: Theme.of(context).brightness,
        ),
      ),
    ).then((_) => _loadData()); // Odśwież dane po powrocie z ustawień
  }

  @override
  Widget build(BuildContext context) {
    final progress = _daySettings != null && _daySettings!.dailyGoal > 0
        ? (_totalWater / _daySettings!.dailyGoal).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drink water'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Licznik wody - ładniejszy design
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.water_drop,
                      size: 40,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _daySettings?.formatAmount(_totalWater) ??
                          '$_totalWater ml',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_daySettings != null) ...[
                  Text(
                    'z ${_daySettings!.formatAmount(_daySettings!.dailyGoal)}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pasek postępu
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? Colors.green : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% celu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  // Przycisk "Dodaj ostatnią ilość"
                  if (_lastEntry != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addLastAmount,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        'Dodaj ponownie ${_daySettings!.formatAmount(_lastEntry!.milliliters)}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          // Lista wpisów
          Expanded(
            child: _entries.isEmpty
                ? const Center(
                    child: Text(
                      'Brak wpisów na dzisiaj.\nDodaj swoją pierwszą wodę!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      final timeFormat = DateFormat('HH:mm');
                      final status = _daySettings != null
                          ? _dbHelper.getEntryStatus(
                              entry.timestamp,
                              _daySettings!,
                            )
                          : 'normal';

                      Widget? statusWidget;
                      if (status == 'early') {
                        statusWidget = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.wb_sunny,
                                size: 16,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Wcześnie! 👏',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (status == 'late') {
                        statusWidget = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bedtime,
                                size: 16,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Pora spać! 😴',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.water_drop),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                _daySettings?.formatAmount(entry.milliliters) ??
                                    '${entry.milliliters} ml',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (statusWidget != null) ...[
                              const SizedBox(width: 8),
                              statusWidget,
                            ],
                          ],
                        ),
                        subtitle: Text(timeFormat.format(entry.timestamp)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Dodaj ponownie',
                              onPressed: () => _addAgain(entry.milliliters),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Usuń',
                              onPressed: () async {
                                await _dbHelper.deleteWaterEntry(entry.id!);
                                await _loadData();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddWaterScreen,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj wodę'),
      ),
    );
  }
}
