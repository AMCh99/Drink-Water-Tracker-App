import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'database/database_helper.dart';
import 'models/water_entry.dart';
import 'models/day_settings.dart';
import 'models/water_button.dart';
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

  // Nie blokuj startu aplikacji — powiadomienia i baza zainicjują się po UI
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
    try {
      final settings = await DatabaseHelper.instance.getDaySettings().timeout(
        const Duration(seconds: 5),
      );
      if (!mounted) return;
      setState(() {
        _isOled = settings.themeMode == 'oled';
        _themeMode = _stringToThemeMode(settings.themeMode);
        _language = settings.language;
        t = AppLocalizations(_language);
        _isLoading = false;
      });
    } catch (_) {
      // Nie blokuj — pokaż UI z domyślnymi ustawieniami
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
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
    final updatedSettings = settings.copyWith(themeMode: mode);
    await DatabaseHelper.instance.updateDaySettings(updatedSettings);
  }

  Future<void> _setLanguage(String lang) async {
    setState(() {
      _language = lang;
      t = AppLocalizations(lang);
    });

    final settings = await DatabaseHelper.instance.getDaySettings();
    final updatedSettings = settings.copyWith(language: lang);
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
      title: 'BeHydrated',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A86FF),
          brightness: Brightness.light,
              secondary: const Color(0xFF1FA3A3),
              tertiary: const Color(0xFF6E57E0),
              surface: const Color(0xFFF7FAFF),
              surfaceTint: const Color(0xFF1A86FF),
            ).copyWith(
              primary: const Color(0xFF1A86FF),
              secondary: const Color(0xFF1FA3A3),
              tertiary: const Color(0xFF6E57E0),
              surface: const Color(0xFFF7FAFF),
              surfaceContainerLowest: const Color(0xFFFFFFFF),
              surfaceContainerLow: const Color(0xFFF2F7FF),
              surfaceContainer: const Color(0xFFEAF2FF),
              surfaceContainerHigh: const Color(0xFFE2ECFF),
              surfaceContainerHighest: const Color(0xFFDCE7FF),
              outline: const Color(0xFFB8C8E6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F8FF),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFFF7FAFF),
          foregroundColor: Color(0xFF12324E),
          iconTheme: IconThemeData(color: Color(0xFF1A86FF)),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFFFFFFFF),
          elevation: 0,
          surfaceTintColor: Color(0x331A86FF),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A86FF)),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1A86FF),
            foregroundColor: Colors.white,
          ),
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
                backgroundColor: Colors.black,
                elevation: 0,
                scrolledUnderElevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF1A1A1A),
                elevation: 0,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: Color(0xFF1A1A1A),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Color(0xFF1A1A1A),
              ),
              useMaterial3: true,
            )
          : ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(
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
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  int _totalWater = 0;
  List<WaterEntry> _entries = [];
  List<WaterButton> _favoriteButtons = [];
  DaySettings? _daySettings;

  // Animacja postępu
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0.0;

  // Confetti
  late ConfettiController _confettiController;
  bool _goalCelebratedToday = false;

  // Audio — lazy init przy pierwszym użyciu
  AudioPlayer? _audioPlayer;

  Future<AudioPlayer> _ensureAudioPlayer() async {
    if (_audioPlayer != null) return _audioPlayer!;

    final player = AudioPlayer();
    await player.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
    );
    _audioPlayer = player;
    return player;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _loadData();
    _initNotifications();
  }

  /// Inicjalizacja powiadomień — po starcie UI żeby nie blokować ekranu
  Future<void> _initNotifications() async {
    try {
      await NotificationService.instance.init();
      // Poproś o uprawnienia zanim zaplanujesz powiadomienia
      await NotificationService.instance.requestPermissions();
      final settings = await _dbHelper.getDaySettings();
      await NotificationService.instance.scheduleReminders(settings);
    } catch (_) {
      // Nie blokuj aplikacji gdy powiadomienia zawiodą
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressController.dispose();
    _confettiController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Odśwież dane gdy aplikacja wraca na pierwszy plan
      _loadData();
    }
  }

  Future<void> _loadData({
    bool playEffects = false,
    bool rescheduleNotifications = false,
  }) async {
    final total = await _dbHelper.getTotalWaterForDay(DateTime.now());
    final entries = await _dbHelper.getWaterEntriesForDay(DateTime.now());
    final buttons = await _dbHelper.getWaterButtons();
    final settings = await _dbHelper.getDaySettings();

    final favoriteButtons = buttons
        .where((button) => button.isFavorite)
        .take(3)
        .toList();

    if (!mounted) return;

    final newProgress = settings.dailyGoal > 0
        ? (total / settings.dailyGoal).clamp(0.0, 1.0)
        : 0.0;

    // Animuj pasek postępu
    _progressAnimation =
        Tween<double>(begin: _previousProgress, end: newProgress).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );
    _progressController.forward(from: 0);

    // Confetti przy osiągnięciu 100%
    if (newProgress >= 1.0 &&
        _previousProgress < 1.0 &&
        !_goalCelebratedToday) {
      _goalCelebratedToday = true;
      _confettiController.play();
    }

    // Efekty dźwiękowe i haptyczne przy dodawaniu wody
    if (playEffects) {
      HapticFeedback.mediumImpact();
      if (settings.soundsEnabled) {
        try {
          final player = await _ensureAudioPlayer();
          await player.play(AssetSource('sounds/water_drop.wav'));
        } catch (_) {
          // Ignoruj błędy audio
        }
      }
    }

    _previousProgress = newProgress;

    setState(() {
      _totalWater = total;
      _entries = entries;
      _favoriteButtons = favoriteButtons;
      _daySettings = settings;
    });

    // Zaktualizuj widget
    await WidgetHelper.updateWidget();

    // Przelicz powiadomienia tylko gdy zmieniono ustawienia
    if (rescheduleNotifications) {
      await NotificationService.instance.scheduleReminders(settings);
    }
  }

  Future<void> _addAgain(int milliliters) async {
    final entry = WaterEntry(
      timestamp: DateTime.now(),
      milliliters: milliliters,
    );
    await _dbHelper.insertWaterEntry(entry);
    await _loadData(playEffects: true);

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
    if (!mounted) return;

    // Odśwież zawsze po powrocie: wpisy mogły się zmienić, ale też ulubione.
    await _loadData(playEffects: result == true);
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
    ).then((_) => _loadData(rescheduleNotifications: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Stack(
        children: [
          Column(
            children: [
              // Główny licznik wody
              SizedBox(
                width: double.infinity,
                child: GlassContainer(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    children: [
                      if (_daySettings != null) ...[
                        // Wskaźnik kołowy — animowany
                        RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              final progress = _progressAnimation.value;
                              final colorScheme = Theme.of(context).colorScheme;
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              final progressColor = progress >= 1.0
                                  ? Colors.green.shade500
                                  : colorScheme.primary;
                              final trackColor = isDark
                                  ? const Color(0xFF262A33)
                                  : colorScheme.primary.withValues(alpha: 0.15);
                              final currentAmount = _daySettings!.formatAmount(
                                _totalWater,
                              );
                              final goalAmount = _daySettings!.formatAmount(
                                _daySettings!.dailyGoal,
                              );

                              return SizedBox(
                                width: 220,
                                height: 220,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 210,
                                      height: 210,
                                      child: CircularProgressIndicator(
                                        value: 1,
                                        strokeWidth: 16,
                                        color: trackColor,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 210,
                                      height: 210,
                                      child: CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 16,
                                        strokeCap: StrokeCap.round,
                                        color: progressColor,
                                        backgroundColor: Colors.transparent,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.water_drop_rounded,
                                            size: 30,
                                            color: progressColor,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '$currentAmount / $goalAmount',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.t.get('dailyGoal'),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_favoriteButtons.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: _favoriteButtons
                                .map(_buildFavoriteAmountButton)
                                .toList(),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.t.get('history'),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return _buildEntryTile(entry);
                        },
                      ),
              ),
            ],
          ),
          // Confetti overlay 🎉
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.blue,
                Colors.cyan,
                Colors.lightBlue,
                Colors.green,
                Colors.teal,
                Colors.white,
              ],
              numberOfParticles: 30,
              gravity: 0.2,
              emissionFrequency: 0.05,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddWaterScreen,
        icon: const Icon(Icons.add_rounded),
        label: Text(widget.t.get('addWater')),
      ),
    );
  }

  Widget _buildFavoriteAmountButton(WaterButton button) {
    final colorScheme = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: () => _addAgain(button.milliliters),
      icon: const Icon(Icons.water_drop_outlined, size: 16),
      label: Text('+ ${button.milliliters} ml'),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEntryTile(WaterEntry entry) {
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
      child: Row(
        children: [
          // Ikona
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
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
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
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
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
            tooltip: widget.t.get('addAgainTooltip'),
            onPressed: () => _addAgain(entry.milliliters),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
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
        color: color.withValues(alpha: 0.15),
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
