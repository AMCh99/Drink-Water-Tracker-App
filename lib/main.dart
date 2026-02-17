import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'database/database_helper.dart';
import 'models/water_entry.dart';
import 'models/day_settings.dart';
import 'screens/settings_screen.dart';
import 'screens/add_water_screen.dart';
import 'screens/stats_screen.dart';
import 'utils/widget_helper.dart';
import 'utils/app_localizations.dart';
import 'widgets/glass_container.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl');
  await initializeDateFormatting('en_US');

  // Inicjalizacja powiadomień
  await NotificationService.instance.init();
  // Zaplanuj przypomnienia na podstawie zapisanych ustawień
  final settings = await DatabaseHelper.instance.getDaySettings();
  await NotificationService.instance.scheduleReminders(settings);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isOled = false;
  bool _isLoading = true;
  String _language = 'pl';

  late AppLocalizations t;

  @override
  void initState() {
    super.initState();
    t = AppLocalizations(_language);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getDaySettings();
    setState(() {
      _isOled = settings.themeMode == 'oled';
      _themeMode = _stringToThemeMode(settings.themeMode);
      _language = settings.language;
      t = AppLocalizations(_language);
      _isLoading = false;
    });
  }

  ThemeMode _stringToThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
      case 'oled':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _setTheme(String mode) async {
    setState(() {
      _isOled = mode == 'oled';
      _themeMode = _stringToThemeMode(mode);
    });

    final settings = await DatabaseHelper.instance.getDaySettings();
    final updatedSettings = DaySettings(
      id: settings.id,
      dayStartHour: settings.dayStartHour,
      dayStartMinute: settings.dayStartMinute,
      dayEndHour: settings.dayEndHour,
      dayEndMinute: settings.dayEndMinute,
      dailyGoal: settings.dailyGoal,
      unit: settings.unit,
      themeMode: mode,
      language: settings.language,
      notificationsEnabled: settings.notificationsEnabled,
      notificationIntervalMinutes: settings.notificationIntervalMinutes,
    );
    await DatabaseHelper.instance.updateDaySettings(updatedSettings);
  }

  Future<void> _setLanguage(String lang) async {
    setState(() {
      _language = lang;
      t = AppLocalizations(lang);
    });

    final settings = await DatabaseHelper.instance.getDaySettings();
    final updatedSettings = DaySettings(
      id: settings.id,
      dayStartHour: settings.dayStartHour,
      dayStartMinute: settings.dayStartMinute,
      dayEndHour: settings.dayEndHour,
      dayEndMinute: settings.dayEndMinute,
      dailyGoal: settings.dailyGoal,
      unit: settings.unit,
      themeMode: settings.themeMode,
      language: lang,
      notificationsEnabled: settings.notificationsEnabled,
      notificationIntervalMinutes: settings.notificationIntervalMinutes,
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
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        useMaterial3: true,
      ),
      darkTheme: _isOled
          ? ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
                surface: Colors.black,
              ),
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
              ),
              cardTheme: CardThemeData(
                color: Colors.white.withOpacity(0.06),
                elevation: 0,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: Color(0xFF121212),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Color(0xFF121212),
              ),
              useMaterial3: true,
            )
          : ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: Colors.transparent,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
              ),
              useMaterial3: true,
            ),
      themeMode: _themeMode,
      home: WaterTrackerHome(
        onThemeChanged: _setTheme,
        onLanguageChanged: _setLanguage,
        currentThemeMode: _isOled
            ? 'oled'
            : (_themeMode == ThemeMode.light ? 'light' : 'dark'),
        t: t,
      ),
    );
  }
}

class WaterTrackerHome extends StatefulWidget {
  final Future<void> Function(String) onThemeChanged;
  final Future<void> Function(String) onLanguageChanged;
  final String currentThemeMode;
  final AppLocalizations t;

  const WaterTrackerHome({
    super.key,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentThemeMode,
    required this.t,
  });

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

    // Przelicz powiadomienia (po dodaniu/usunięciu wody)
    await NotificationService.instance.scheduleReminders(settings);
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
            '${widget.t.get('added')} ${_daySettings?.formatAmount(_lastEntry!.milliliters) ?? "${_lastEntry!.milliliters} ml"}',
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
            '${widget.t.get('added')} ${_daySettings?.formatAmount(milliliters) ?? "$milliliters ml"}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openAddWaterScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddWaterScreen(t: widget.t)),
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
          onThemeChanged: widget.onThemeChanged,
          onLanguageChanged: widget.onLanguageChanged,
          currentThemeMode: widget.currentThemeMode,
          t: widget.t,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final progress = _daySettings != null && _daySettings!.dailyGoal > 0
        ? (_totalWater / _daySettings!.dailyGoal).clamp(0.0, 1.0)
        : 0.0;

    return LiquidGlassBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.t.get('appTitle'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              tooltip: widget.t.get('statistics'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatsScreen(t: widget.t),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: _openSettings,
            ),
          ],
        ),
        body: Column(
          children: [
            // Główny licznik wody — Liquid Glass
            GlassContainer(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              blur: 20,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.water_drop_rounded,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _daySettings?.formatAmount(_totalWater) ??
                            '$_totalWater ml',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_daySettings != null) ...[
                    Text(
                      '${widget.t.get('ofGoal')} ${_daySettings!.formatAmount(_daySettings!.dailyGoal)}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Pasek postępu — glass style
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: progress >= 1.0
                                      ? [
                                          Colors.green.shade400,
                                          Colors.green.shade300,
                                        ]
                                      : [
                                          Colors.blue.shade400,
                                          Colors.cyan.shade300,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (progress >= 1.0
                                                ? Colors.green
                                                : Colors.blue)
                                            .withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% ${widget.t.get('percentGoal')}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    // Przycisk "Dodaj ponownie" — glass style
                    if (_lastEntry != null) ...[
                      const SizedBox(height: 16),
                      GlassContainer(
                        padding: EdgeInsets.zero,
                        borderRadius: 30,
                        blur: 10,
                        opacity: 0.08,
                        child: InkWell(
                          onTap: _addLastAmount,
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.t.get('addAgain')} ${_daySettings!.formatAmount(_lastEntry!.milliliters)}',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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
                  ? Center(
                      child: Text(
                        widget.t.get('noEntriesToday'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return _buildGlassEntryTile(entry);
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: GlassContainer(
          padding: EdgeInsets.zero,
          borderRadius: 28,
          blur: 15,
          opacity: 0.15,
          child: InkWell(
            onTap: _openAddWaterScreen,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.t.get('addWater'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassEntryTile(WaterEntry entry) {
    final timeFormat = DateFormat('HH:mm');
    final status = _daySettings != null
        ? _dbHelper.getEntryStatus(entry.timestamp, _daySettings!)
        : 'normal';

    Widget? statusWidget;
    if (status == 'early') {
      statusWidget = _buildStatusChip(
        Icons.wb_sunny_rounded,
        widget.t.get('earlyStatus'),
        Colors.green,
      );
    } else if (status == 'late') {
      statusWidget = _buildStatusChip(
        Icons.bedtime_rounded,
        widget.t.get('lateStatus'),
        Colors.orange,
      );
    }

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      blur: 10,
      opacity: 0.08,
      child: Row(
        children: [
          // Ikona
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            ),
            child: Icon(
              Icons.water_drop_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Tekst
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _daySettings?.formatAmount(entry.milliliters) ??
                      '${entry.milliliters} ml',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      timeFormat.format(entry.timestamp),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    if (statusWidget != null) ...[
                      const SizedBox(width: 8),
                      Flexible(child: statusWidget),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Akcje
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              size: 20,
            ),
            tooltip: widget.t.get('addAgainTooltip'),
            onPressed: () => _addAgain(entry.milliliters),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              size: 20,
            ),
            tooltip: widget.t.get('deleteTooltip'),
            onPressed: () async {
              await _dbHelper.deleteWaterEntry(entry.id!);
              await _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
