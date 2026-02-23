import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../models/daily_stats.dart';
import '../models/day_settings.dart';
import '../utils/app_localizations.dart';
import '../widgets/glass_container.dart';

class StatsScreen extends StatefulWidget {
  final AppLocalizations t;

  const StatsScreen({super.key, required this.t});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late TabController _tabController;

  // Weekly
  List<DailyStats> _weeklyStats = [];
  DaySettings? _settings;
  bool _isLoadingWeekly = true;

  // Monthly
  List<DailyStats> _monthlyStats = [];
  late int _selectedYear;
  late int _selectedMonth;
  bool _isLoadingMonthly = true;

  // Yearly
  List<DailyStats> _yearlyStats = [];
  late int _selectedYearForYearly;
  bool _isLoadingYearly = true;

  // Streak
  int _currentStreak = 0;

  // Trends
  List<Map<String, dynamic>> _weeklyAverages = [];
  List<Map<String, dynamic>> _monthlyAverages = [];
  bool _isLoadingTrends = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _selectedYearForYearly = now.year;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    _loadWeeklyStats();
    _loadMonthlyStats();
    _loadYearlyStats();
    _loadStreak();
    _loadTrends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWeeklyStats() async {
    final stats = await _dbHelper.getWeeklyStats();
    final settings = await _dbHelper.getDaySettings();
    if (!mounted) return;
    setState(() {
      _weeklyStats = stats;
      _settings = settings;
      _isLoadingWeekly = false;
    });
  }

  Future<void> _loadMonthlyStats() async {
    if (!mounted) return;
    setState(() => _isLoadingMonthly = true);
    final stats = await _dbHelper.getMonthlyStats(
      _selectedYear,
      _selectedMonth,
    );
    final settings = await _dbHelper.getDaySettings();
    if (!mounted) return;
    setState(() {
      _monthlyStats = stats;
      _settings = settings;
      _isLoadingMonthly = false;
    });
  }

  Future<void> _loadYearlyStats() async {
    if (!mounted) return;
    setState(() => _isLoadingYearly = true);
    final stats = await _dbHelper.getYearlyStats(_selectedYearForYearly);
    if (!mounted) return;
    setState(() {
      _yearlyStats = stats;
      _isLoadingYearly = false;
    });
  }

  Future<void> _loadStreak() async {
    final streak = await _dbHelper.getCurrentStreak();
    if (!mounted) return;
    setState(() {
      _currentStreak = streak;
    });
  }

  Future<void> _loadTrends() async {
    if (!mounted) return;
    setState(() => _isLoadingTrends = true);
    final weeklyAvg = await _dbHelper.getWeeklyAverages();
    final monthlyAvg = await _dbHelper.getMonthlyAverages();
    if (!mounted) return;
    setState(() {
      _weeklyAverages = weeklyAvg;
      _monthlyAverages = monthlyAvg;
      _isLoadingTrends = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
    _loadMonthlyStats();
  }

  void _changeYearForYearly(int delta) {
    final now = DateTime.now();
    final newYear = _selectedYearForYearly + delta;
    if (newYear > now.year) return;
    setState(() {
      _selectedYearForYearly = newYear;
    });
    _loadYearlyStats();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.t.get('statsTitle')),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.ios_share),
              tooltip: widget.t.get('exportData'),
              onSelected: (value) {
                if (value == 'csv') _exportCSV();
                if (value == 'pdf') _exportPDF();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'csv',
                  child: ListTile(
                    leading: const Icon(Icons.table_chart),
                    title: Text(widget.t.get('exportCSV')),
                    subtitle: Text(
                      widget.t.get('exportCSVDesc'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: Text(widget.t.get('exportPDF')),
                    subtitle: Text(
                      widget.t.get('exportPDFDesc'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.bar_chart),
                text: widget.t.get('week'),
              ),
              Tab(
                icon: const Icon(Icons.calendar_month),
                text: widget.t.get('month'),
              ),
              Tab(
                icon: const Icon(Icons.calendar_view_month),
                text: widget.t.get('year'),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildWeeklyTab(), _buildMonthlyTab(), _buildYearlyTab()],
        ),
      ),
    );
  }

  // ==================== STREAK BANNER ====================

  Widget _buildStreakBanner() {
    if (_currentStreak <= 0) {
      return GlassContainer(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 16,
        blur: 12,
        child: Row(
          children: [
            const Text('\u{1F4A7}', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.t.get('noStreak'),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      blur: 12,
      child: Row(
        children: [
          const Text('\u{1F525}', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_currentStreak ${_currentStreak == 1 ? widget.t.get('streakDay') : widget.t.get('streakDays')}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.t.get('streakRegular'),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (_currentStreak >= 7)
            const Text('\u{1F3C6}', style: TextStyle(fontSize: 24)),
          if (_currentStreak >= 30)
            const Text('\u{2B50}', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  // ==================== WEEKLY TAB ====================

  Widget _buildWeeklyTab() {
    if (_isLoadingWeekly || _isLoadingTrends) {
      return const Center(child: CircularProgressIndicator());
    }

    final maxMl = _weeklyStats.isEmpty
        ? 2000.0
        : _weeklyStats
              .map((s) => s.totalMl)
              .reduce((a, b) => a > b ? a : b)
              .toDouble();
    final goalMl = _settings?.dailyGoal.toDouble() ?? 2000.0;
    final chartMax = (maxMl > goalMl ? maxMl : goalMl) * 1.2;

    final avgMl = _weeklyStats.isEmpty
        ? 0
        : (_weeklyStats.map((s) => s.totalMl).reduce((a, b) => a + b) /
                  _weeklyStats.length)
              .round();
    final daysGoalReached = _weeklyStats.where((s) => s.goalReached).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStreakBanner(),
          _buildSummaryCards(avgMl, daysGoalReached),
          const SizedBox(height: 24),
          Text(
            widget.t.get('last7Days'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 280, child: _buildChart(chartMax, goalMl)),
          const SizedBox(height: 24),
          _buildWeeklyTrendSection(),
          const SizedBox(height: 24),
          _buildDaysList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(int avgMl, int daysGoalReached) {
    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            blur: 12,
            child: Column(
              children: [
                const Icon(Icons.water_drop, color: Colors.blue, size: 32),
                const SizedBox(height: 8),
                Text(
                  _settings?.formatAmount(avgMl) ?? '$avgMl ml',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.t.get('avgDaily'),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GlassContainer(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            blur: 12,
            child: Column(
              children: [
                Icon(
                  daysGoalReached >= 5 ? Icons.emoji_events : Icons.flag,
                  color: daysGoalReached >= 5 ? Colors.amber : Colors.green,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  '$daysGoalReached / 7',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.t.get('goalReached'),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(double chartMax, double goalMl) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMax,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final stat = _weeklyStats[group.x];
              return BarTooltipItem(
                _settings?.formatAmount(stat.totalMl) ?? '${stat.totalMl} ml',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _weeklyStats.length) {
                  final date = _weeklyStats[value.toInt()].date;
                  final dayName = DateFormat(
                    'E',
                    widget.t.dateLocale,
                  ).format(date);
                  final isToday = _isToday(date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dayName.substring(0, 2),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                final label = _settings?.unit == 'oz'
                    ? (value / 29.5735).toStringAsFixed(0)
                    : '${value.toInt()}';
                return Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax / 4,
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: goalMl,
              color: Colors.red.withOpacity(0.5),
              strokeWidth: 2,
              dashArray: [8, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(
                  color: Colors.red.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (line) => widget.t.get('goal'),
              ),
            ),
          ],
        ),
        barGroups: _weeklyStats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          final isGoalReached = stat.goalReached;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: stat.totalMl.toDouble(),
                color: isGoalReached
                    ? Colors.green.shade400
                    : Colors.blue.shade400,
                width: 28,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ==================== WEEKLY TREND ====================

  Widget _buildWeeklyTrendSection() {
    if (_weeklyAverages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.t.get('trends'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          widget.t.get('last8Weeks'),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        SizedBox(height: 180, child: _buildTrendChart()),
        const SizedBox(height: 16),
        Text(
          widget.t.get('last6Months'),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        _buildMonthlyAveragesList(),
      ],
    );
  }

  Widget _buildTrendChart() {
    if (_weeklyAverages.isEmpty) return const SizedBox.shrink();

    final goalMl = _settings?.dailyGoal.toDouble() ?? 2000.0;
    final maxAvg = _weeklyAverages
        .map((w) => (w['avgMl'] as int).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final chartMax = (maxAvg > goalMl ? maxAvg : goalMl) * 1.2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: chartMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax / 4,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= _weeklyAverages.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${widget.t.get('weekShort')}${idx + 1}',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: goalMl,
              color: Colors.red.withOpacity(0.3),
              strokeWidth: 1,
              dashArray: [6, 4],
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _weeklyAverages.asMap().entries.map((e) {
              return FlSpot(
                e.key.toDouble(),
                (e.value['avgMl'] as int).toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.blue.shade400,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isGoal = spot.y >= goalMl;
                return FlDotCirclePainter(
                  radius: 4,
                  color: isGoal ? Colors.green : Colors.blue,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  _settings?.formatAmount(spot.y.toInt()) ??
                      '${spot.y.toInt()} ml',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyAveragesList() {
    if (_monthlyAverages.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _monthlyAverages.length,
        itemBuilder: (context, index) {
          final data = _monthlyAverages[index];
          final month = data['month'] as DateTime;
          final avgMl = data['avgMl'] as int;
          final goalDays = data['daysGoalReached'] as int;
          final monthName = DateFormat(
            'MMM',
            widget.t.dateLocale,
          ).format(month);
          final goalMl = _settings?.dailyGoal ?? 2000;
          final isAboveGoal = avgMl >= goalMl;

          return GlassContainer(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderRadius: 12,
            blur: 10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monthName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _settings?.formatAmount(avgMl) ?? '$avgMl ml',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isAboveGoal ? Colors.green : null,
                  ),
                ),
                Text(
                  '${widget.t.get('goalDays')}: $goalDays',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDaysList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.t.get('details'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(_weeklyStats.length, (index) {
          final stat = _weeklyStats[_weeklyStats.length - 1 - index];
          final dayFormat = DateFormat('EEEE, d MMM', widget.t.dateLocale);
          final isToday = _isToday(stat.date);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: stat.goalReached
                  ? Colors.green.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
              child: Icon(
                stat.goalReached ? Icons.check : Icons.water_drop,
                color: stat.goalReached ? Colors.green : Colors.blue,
              ),
            ),
            title: Text(
              isToday ? widget.t.get('today') : dayFormat.format(stat.date),
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: LinearProgressIndicator(
              value: stat.progress,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                stat.goalReached ? Colors.green : Colors.blue,
              ),
            ),
            trailing: Text(
              _settings?.formatAmount(stat.totalMl) ?? '${stat.totalMl} ml',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: stat.goalReached ? Colors.green : null,
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==================== MONTHLY TAB ====================

  Widget _buildMonthlyTab() {
    if (_isLoadingMonthly) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final isCurrentMonth =
        _selectedYear == now.year && _selectedMonth == now.month;
    final monthName = DateFormat(
      'LLLL yyyy',
      widget.t.dateLocale,
    ).format(DateTime(_selectedYear, _selectedMonth));

    final pastDays = _monthlyStats.where((s) => !s.isFuture).toList();
    final daysReached = pastDays.where((s) => s.goalReached).length;
    final totalDays = pastDays.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStreakBanner(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                monthName[0].toUpperCase() + monthName.substring(1),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: isCurrentMonth ? null : () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.t.get('goalReachedDays')} $daysReached / $totalDays ${widget.t.get('days')}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          _buildWeekdayHeaders(),
          const SizedBox(height: 8),
          _buildDotsGrid(),
          const SizedBox(height: 24),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdays = [
      widget.t.get('weekdayMon'),
      widget.t.get('weekdayTue'),
      widget.t.get('weekdayWed'),
      widget.t.get('weekdayThu'),
      widget.t.get('weekdayFri'),
      widget.t.get('weekdaySat'),
      widget.t.get('weekdaySun'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map(
            (d) => SizedBox(
              width: 40,
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDotsGrid() {
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    final startOffset = firstDay.weekday - 1;

    final totalCells = startOffset + _monthlyStats.length;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayIndex = cellIndex - startOffset;

              if (dayIndex < 0 || dayIndex >= _monthlyStats.length) {
                return const SizedBox(width: 40, height: 40);
              }

              final stat = _monthlyStats[dayIndex];
              return _buildDot(stat);
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDot(DailyStats stat) {
    final isToday = _isToday(stat.date);
    final bool isOled =
        Theme.of(context).scaffoldBackgroundColor == Colors.black;

    Color dotColor;
    if (stat.isFuture) {
      dotColor = isOled ? Colors.grey.shade800 : Colors.grey.shade200;
    } else if (stat.goalReached) {
      dotColor = Colors.green.shade400;
    } else {
      dotColor = isOled ? Colors.grey.shade600 : Colors.grey.shade400;
    }

    return SizedBox(
      width: 40,
      height: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isToday ? 26 : 22,
            height: isToday ? 26 : 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              border: isToday
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.5,
                    )
                  : null,
              boxShadow: stat.goalReached && !stat.isFuture
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${stat.date.day}',
            style: TextStyle(
              fontSize: 9,
              color: isToday
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade500,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.green.shade400, widget.t.get('goalReachedLegend')),
        const SizedBox(width: 24),
        _legendItem(Colors.grey.shade400, widget.t.get('goalNotReachedLegend')),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // ==================== YEARLY TAB (GitHub-style) ====================

  Widget _buildYearlyTab() {
    if (_isLoadingYearly) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final isCurrentYear = _selectedYearForYearly == now.year;

    final pastDays = _yearlyStats.where((s) => !s.isFuture).toList();
    final daysTracked = pastDays.where((s) => s.totalMl > 0).length;
    final daysGoalReached = pastDays.where((s) => s.goalReached).length;
    final totalMl = pastDays.fold<int>(
      0,
      (sum, s) => sum + (s.totalMl > 0 ? s.totalMl : 0),
    );
    final avgMl = daysTracked > 0 ? (totalMl / daysTracked).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStreakBanner(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeYearForYearly(-1),
              ),
              Text(
                '$_selectedYearForYearly',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: isCurrentYear ? null : () => _changeYearForYearly(1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildYearlySummaryCard(
                  Icons.calendar_today,
                  Colors.blue,
                  '$daysTracked',
                  widget.t.get('totalDaysTracked'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildYearlySummaryCard(
                  Icons.emoji_events,
                  Colors.green,
                  '$daysGoalReached',
                  widget.t.get('totalGoalDays'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildYearlySummaryCard(
                  Icons.water_drop,
                  Colors.cyan,
                  _settings?.formatAmount(avgMl) ?? '$avgMl ml',
                  widget.t.get('yearlyAvg'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            widget.t.get('yearlyOverview'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildYearlyContributionGrid(),
          const SizedBox(height: 12),
          _buildYearlyGradientLegend(),
          const SizedBox(height: 20),
          _buildMonthlyBreakdown(),
        ],
      ),
    );
  }

  Widget _buildYearlySummaryCard(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderRadius: 14,
      blur: 10,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyContributionGrid() {
    if (_yearlyStats.isEmpty) return const SizedBox.shrink();

    final firstDay = DateTime(_selectedYearForYearly, 1, 1);
    final startOffset = firstDay.weekday - 1;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isOled =
        Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final totalDays = startOffset + _yearlyStats.length;
    final totalWeeks = (totalDays / 7).ceil();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 16,
            child: Row(children: _buildMonthLabels(totalWeeks)),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 0),
                  ...List.generate(7, (dayOfWeek) {
                    final labels = [
                      '',
                      widget.t.get('weekdayTue'),
                      '',
                      widget.t.get('weekdayThu'),
                      '',
                      widget.t.get('weekdaySat'),
                      '',
                    ];
                    return SizedBox(
                      height: 13,
                      width: 20,
                      child: Text(
                        labels[dayOfWeek],
                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    );
                  }),
                ],
              ),
              ...List.generate(totalWeeks, (week) {
                return Column(
                  children: List.generate(7, (dayOfWeek) {
                    final dayIndex = week * 7 + dayOfWeek - startOffset;
                    if (dayIndex < 0 || dayIndex >= _yearlyStats.length) {
                      return const SizedBox(width: 13, height: 13);
                    }
                    final stat = _yearlyStats[dayIndex];
                    return _buildContributionCell(stat, isDark, isOled);
                  }),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMonthLabels(int totalWeeks) {
    final List<Widget> labels = [];
    labels.add(const SizedBox(width: 20));

    int lastMonth = -1;
    for (int week = 0; week < totalWeeks; week++) {
      final dayIndex =
          week * 7 - (DateTime(_selectedYearForYearly, 1, 1).weekday - 1);
      if (dayIndex >= 0 && dayIndex < _yearlyStats.length) {
        final month = _yearlyStats[dayIndex].date.month;
        if (month != lastMonth) {
          lastMonth = month;
          final monthName = DateFormat(
            'MMM',
            widget.t.dateLocale,
          ).format(DateTime(_selectedYearForYearly, month));
          labels.add(
            SizedBox(
              width: 13,
              child: Text(
                monthName,
                style: const TextStyle(fontSize: 8, color: Colors.grey),
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            ),
          );
        } else {
          labels.add(const SizedBox(width: 13));
        }
      } else {
        labels.add(const SizedBox(width: 13));
      }
    }

    return labels;
  }

  Widget _buildContributionCell(DailyStats stat, bool isDark, bool isOled) {
    Color cellColor;

    if (stat.isFuture) {
      cellColor = isOled
          ? Colors.grey.shade900
          : isDark
          ? Colors.grey.shade800
          : Colors.grey.shade100;
    } else if (stat.totalMl <= 0) {
      cellColor = isOled
          ? Colors.grey.shade800
          : isDark
          ? Colors.grey.shade700
          : Colors.grey.shade200;
    } else {
      final progress = stat.progress;
      if (progress >= 1.0) {
        cellColor = Colors.green.shade600;
      } else if (progress >= 0.75) {
        cellColor = Colors.green.shade400;
      } else if (progress >= 0.50) {
        cellColor = Colors.green.shade300;
      } else if (progress >= 0.25) {
        cellColor = isDark ? Colors.green.shade900 : Colors.green.shade200;
      } else {
        cellColor = isDark ? Colors.green.shade900 : Colors.green.shade100;
      }
    }

    final isToday = _isToday(stat.date);

    return Container(
      width: 11,
      height: 11,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(2),
        border: isToday
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              )
            : null,
      ),
    );
  }

  Widget _buildYearlyGradientLegend() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.t.get('less'),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(width: 4),
        _gradientBox(isDark ? Colors.grey.shade700 : Colors.grey.shade200),
        _gradientBox(isDark ? Colors.green.shade900 : Colors.green.shade100),
        _gradientBox(Colors.green.shade300),
        _gradientBox(Colors.green.shade400),
        _gradientBox(Colors.green.shade600),
        const SizedBox(width: 4),
        Text(
          widget.t.get('more'),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _gradientBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildMonthlyBreakdown() {
    final Map<int, List<DailyStats>> monthGroups = {};
    for (final stat in _yearlyStats) {
      if (stat.isFuture) continue;
      final m = stat.date.month;
      monthGroups.putIfAbsent(m, () => []);
      monthGroups[m]!.add(stat);
    }

    if (monthGroups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.t.get('details'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...monthGroups.entries.map((entry) {
          final month = entry.key;
          final stats = entry.value;
          final monthName = DateFormat(
            'LLLL',
            widget.t.dateLocale,
          ).format(DateTime(_selectedYearForYearly, month));
          final totalMl = stats.fold<int>(
            0,
            (sum, s) => sum + (s.totalMl > 0 ? s.totalMl : 0),
          );
          final daysWithData = stats.where((s) => s.totalMl > 0).length;
          final avgMl = daysWithData > 0 ? (totalMl / daysWithData).round() : 0;
          final goalDays = stats.where((s) => s.goalReached).length;
          final totalDaysInMonth = stats.length;
          final pct = totalDaysInMonth > 0 ? goalDays / totalDaysInMonth : 0.0;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: pct >= 0.7
                  ? Colors.green.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
              child: Text(
                '${(pct * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: pct >= 0.7 ? Colors.green : Colors.blue,
                ),
              ),
            ),
            title: Text(
              monthName[0].toUpperCase() + monthName.substring(1),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 0.7 ? Colors.green : Colors.blue,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _settings?.formatAmount(avgMl) ?? '$avgMl ml',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$goalDays/$totalDaysInMonth ${widget.t.get('days')}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==================== EXPORT ====================

  Future<void> _exportCSV() async {
    try {
      final entries = await _dbHelper.getAllEntriesForExport();
      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.t.get('noDataToExport'))),
          );
        }
        return;
      }

      final List<List<dynamic>> csvData = [
        [widget.t.get('date'), widget.t.get('time'), widget.t.get('amount')],
      ];

      for (final entry in entries) {
        final timestamp = DateTime.parse(entry['timestamp'] as String);
        csvData.add([
          DateFormat('yyyy-MM-dd').format(timestamp),
          DateFormat('HH:mm:ss').format(timestamp),
          entry['milliliters'],
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/water_tracker_export.csv');
      await file.writeAsString(csvString);

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Water Tracker - CSV Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.t.get('exportError')}: $e')),
        );
      }
    }
  }

  Future<void> _exportPDF() async {
    try {
      final settings = await _dbHelper.getDaySettings();
      final weeklyStats = await _dbHelper.getWeeklyStats();
      final streak = await _dbHelper.getCurrentStreak();
      final entries = await _dbHelper.getAllEntriesForExport();

      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.t.get('noDataToExport'))),
          );
        }
        return;
      }

      final pdfDoc = pw.Document();

      final avgMl = weeklyStats.isEmpty
          ? 0
          : (weeklyStats.map((s) => s.totalMl).reduce((a, b) => a + b) /
                    weeklyStats.length)
                .round();
      final daysGoalReached = weeklyStats.where((s) => s.goalReached).length;

      pdfDoc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Drink Water Tracker - Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              ),
              pw.SizedBox(height: 20),
              pw.Header(level: 1, text: 'Summary'),
              pw.Bullet(
                text:
                    'Daily goal: ${settings.formatAmount(settings.dailyGoal)}',
              ),
              pw.Bullet(text: 'Current streak: $streak days'),
              pw.Bullet(
                text: 'Weekly average: ${settings.formatAmount(avgMl)}',
              ),
              pw.Bullet(text: 'Goal reached: $daysGoalReached / 7 days'),
              pw.SizedBox(height: 20),
              pw.Header(level: 1, text: 'Last 7 days'),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ['Date', 'Amount', 'Goal', 'Status'],
                data: weeklyStats.map((s) {
                  return [
                    DateFormat('yyyy-MM-dd').format(s.date),
                    settings.formatAmount(s.totalMl),
                    settings.formatAmount(s.goalMl),
                    s.goalReached ? '\u2713' : '\u2717',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Header(level: 1, text: 'Recent entries'),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ['Date', 'Time', 'Amount (ml)'],
                data: entries.reversed.take(50).map((entry) {
                  final ts = DateTime.parse(entry['timestamp'] as String);
                  return [
                    DateFormat('yyyy-MM-dd').format(ts),
                    DateFormat('HH:mm').format(ts),
                    '${entry['milliliters']}',
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/water_tracker_report.pdf');
      await file.writeAsBytes(await pdfDoc.save());

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Water Tracker - PDF Report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.t.get('exportError')}: $e')),
        );
      }
    }
  }

  // ==================== HELPERS ====================

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
