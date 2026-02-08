import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/day_settings.dart';

class SettingsScreen extends StatefulWidget {
  final Future<void> Function() onToggleTheme;
  final Brightness currentBrightness;

  const SettingsScreen({
    super.key,
    required this.onToggleTheme,
    required this.currentBrightness,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  DaySettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _dbHelper.getDaySettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _showDayTimeDialog() async {
    if (_settings == null) return;

    TimeOfDay startTime = TimeOfDay(
      hour: _settings!.dayStartHour,
      minute: _settings!.dayStartMinute,
    );

    TimeOfDay endTime = TimeOfDay(
      hour: _settings!.dayEndHour,
      minute: _settings!.dayEndMinute,
    );

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Godziny dnia'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Początek dnia'),
                    trailing: Text(
                      startTime.format(context),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          startTime = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Koniec dnia'),
                    trailing: Text(
                      endTime.format(context),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          endTime = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Anuluj'),
                ),
                FilledButton(
                  onPressed: () async {
                    final updatedSettings = DaySettings(
                      id: _settings!.id,
                      dayStartHour: startTime.hour,
                      dayStartMinute: startTime.minute,
                      dayEndHour: endTime.hour,
                      dayEndMinute: endTime.minute,
                      dailyGoal: _settings!.dailyGoal,
                      unit: _settings!.unit,
                    );
                    await _dbHelper.updateDaySettings(updatedSettings);
                    await _loadSettings();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDailyGoalDialog() async {
    if (_settings == null) return;

    final TextEditingController controller = TextEditingController(
      text: _settings!.dailyGoal.toString(),
    );

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dzienny cel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ile mililitrów wody chcesz wypijać dziennie?',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cel (ml)',
                  border: OutlineInputBorder(),
                  suffixText: 'ml',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  _quickGoalChip(controller, 1500),
                  _quickGoalChip(controller, 2000),
                  _quickGoalChip(controller, 2500),
                  _quickGoalChip(controller, 3000),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () async {
                final goal = int.tryParse(controller.text);
                if (goal != null && goal > 0) {
                  final updatedSettings = DaySettings(
                    id: _settings!.id,
                    dayStartHour: _settings!.dayStartHour,
                    dayStartMinute: _settings!.dayStartMinute,
                    dayEndHour: _settings!.dayEndHour,
                    dayEndMinute: _settings!.dayEndMinute,
                    dailyGoal: goal,
                    unit: _settings!.unit,
                  );
                  await _dbHelper.updateDaySettings(updatedSettings);
                  await _loadSettings();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }

  Widget _quickGoalChip(TextEditingController controller, int value) {
    return ActionChip(
      label: Text('${value}ml'),
      onPressed: () {
        controller.text = value.toString();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Opcje')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Opcje')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Wygląd',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              widget.currentBrightness == Brightness.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title: const Text('Motyw'),
            subtitle: Text(
              widget.currentBrightness == Brightness.dark ? 'Ciemny' : 'Jasny',
            ),
            trailing: Switch(
              value: widget.currentBrightness == Brightness.dark,
              onChanged: (value) {
                widget.onToggleTheme();
                setState(() {}); // Odśwież UI
              },
            ),
            onTap: widget.onToggleTheme,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Dzień',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Godziny dnia'),
            subtitle: Text(
              '${_settings!.dayStartHour.toString().padLeft(2, '0')}:${_settings!.dayStartMinute.toString().padLeft(2, '0')} - '
              '${_settings!.dayEndHour.toString().padLeft(2, '0')}:${_settings!.dayEndMinute.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showDayTimeDialog,
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Dzienny cel'),
            subtitle: Text(_settings!.formatAmount(_settings!.dailyGoal)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showDailyGoalDialog,
          ),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Jednostki'),
            subtitle: Text(
              _settings!.unit == 'ml' ? 'Mililitry (ml)' : 'Uncje (oz)',
            ),
            trailing: Switch(
              value: _settings!.unit == 'oz',
              onChanged: (value) async {
                final updatedSettings = DaySettings(
                  id: _settings!.id,
                  dayStartHour: _settings!.dayStartHour,
                  dayStartMinute: _settings!.dayStartMinute,
                  dayEndHour: _settings!.dayEndHour,
                  dayEndMinute: _settings!.dayEndMinute,
                  dailyGoal: _settings!.dailyGoal,
                  unit: value ? 'oz' : 'ml',
                );
                await _dbHelper.updateDaySettings(updatedSettings);
                await _loadSettings();
              },
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Informacje',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('O aplikacji'),
            subtitle: const Text('Drink Water Tracker v1.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Drink Water Tracker',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.water_drop,
                  size: 48,
                  color: Colors.blue,
                ),
                children: [
                  const Text(
                    'Prosta aplikacja do śledzenia ilości wypijanej wody.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
