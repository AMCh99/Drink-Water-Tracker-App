import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/daily_stats.dart';
import '../models/day_settings.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadWeeklyStats();
    _loadMonthlyStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWeeklyStats() async {
    final stats = await _dbHelper.getWeeklyStats();
    final settings = await _dbHelper.getDaySettings();
    setState(() {
      _weeklyStats = stats;
      _settings = settings;
      _isLoadingWeekly = false;
    });
  }

  Future<void> _loadMonthlyStats() async {
    setState(() => _isLoadingMonthly = true);
    final stats = await _dbHelper.getMonthlyStats(
      _selectedYear,
      _selectedMonth,
    );
    final settings = await _dbHelper.getDaySettings();
    setState(() {
      _monthlyStats = stats;
      _settings = settings;
      _isLoadingMonthly = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statystyki'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Tydzień'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Miesiąc'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildWeeklyTab(), _buildMonthlyTab()],
      ),
    );
  }

  // ==================== WEEKLY TAB ====================

  Widget _buildWeeklyTab() {
    if (_isLoadingWeekly) {
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
          _buildSummaryCards(avgMl, daysGoalReached),
          const SizedBox(height: 24),
          const Text(
            'Ostatnie 7 dni',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 280, child: _buildChart(chartMax, goalMl)),
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
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                  const Text(
                    'Średnio dziennie',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                  const Text(
                    'Cel osiągnięty',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
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
                  final dayName = DateFormat('E', 'pl').format(date);
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
                labelResolver: (line) => 'Cel',
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

  Widget _buildDaysList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Szczegóły',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(_weeklyStats.length, (index) {
          final stat = _weeklyStats[_weeklyStats.length - 1 - index];
          final dayFormat = DateFormat('EEEE, d MMM', 'pl');
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
              isToday ? 'Dzisiaj' : dayFormat.format(stat.date),
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
      'pl',
    ).format(DateTime(_selectedYear, _selectedMonth));

    // Statystyki miesiąca (tylko przeszłe/dzisiejsze dni)
    final pastDays = _monthlyStats.where((s) => !s.isFuture).toList();
    final daysReached = pastDays.where((s) => s.goalReached).length;
    final totalDays = pastDays.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Nawigacja miesięcy
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

          // Podsumowanie
          Text(
            'Cel osiągnięty: $daysReached / $totalDays dni',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Nagłówki dni tygodnia
          _buildWeekdayHeaders(),
          const SizedBox(height: 8),

          // Siatka kropek
          _buildDotsGrid(),

          const SizedBox(height: 24),

          // Legenda
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
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
    // Pierwszy dzień miesiąca — dzień tygodnia (1=poniedziałek w DateTime)
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    // weekday: 1=Mon, 7=Sun → offset = weekday - 1
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
        _legendItem(Colors.green.shade400, 'Cel osiągnięty'),
        const SizedBox(width: 24),
        _legendItem(Colors.grey.shade400, 'Cel nieosiągnięty'),
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

  // ==================== HELPERS ====================

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
