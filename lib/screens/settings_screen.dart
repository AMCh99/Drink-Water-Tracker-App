import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/day_settings.dart';
import '../utils/app_localizations.dart';
import '../widgets/glass_container.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final Future<void> Function(String) onThemeChanged;
  final Future<void> Function(String) onLanguageChanged;
  final String currentThemeMode;
  final AppLocalizations t;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentThemeMode,
    required this.t,
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
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _persistSettings(
    DaySettings updatedSettings, {
    bool rescheduleReminders = false,
  }) async {
    await _dbHelper.updateDaySettings(updatedSettings);
    await _loadSettings();
    if (rescheduleReminders) {
      await NotificationService.instance.scheduleReminders(updatedSettings);
    }
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
              title: Text(widget.t.get('dayHours')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(widget.t.get('dayStart')),
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
                    title: Text(widget.t.get('dayEnd')),
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
                  child: Text(widget.t.get('cancel')),
                ),
                FilledButton(
                  onPressed: () async {
                    final updatedSettings = _settings!.copyWith(
                      dayStartHour: startTime.hour,
                      dayStartMinute: startTime.minute,
                      dayEndHour: endTime.hour,
                      dayEndMinute: endTime.minute,
                    );
                    await _persistSettings(
                      updatedSettings,
                      rescheduleReminders: true,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(widget.t.get('save')),
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
          title: Text(widget.t.get('dailyGoal')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.t.get('dailyGoalQuestion'),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.t.get('goalMl'),
                  border: const OutlineInputBorder(),
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
              child: Text(widget.t.get('cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final goal = int.tryParse(controller.text);
                if (goal != null && goal > 0) {
                  final updatedSettings = _settings!.copyWith(dailyGoal: goal);
                  await _persistSettings(updatedSettings);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(widget.t.get('save')),
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

  Future<void> _showThemeDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.t.get('chooseTheme')),
          content: RadioGroup<String>(
            groupValue: widget.currentThemeMode,
            onChanged: (value) {
              if (value == null) return;
              widget.onThemeChanged(value);
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text(widget.t.get('themeLight')),
                  secondary: const Icon(Icons.light_mode),
                  value: 'light',
                ),
                RadioListTile<String>(
                  title: Text(widget.t.get('themeDark')),
                  secondary: const Icon(Icons.dark_mode),
                  value: 'dark',
                ),
                RadioListTile<String>(
                  title: Text(widget.t.get('themeOled')),
                  subtitle: Text(widget.t.get('themeOledSubtitle')),
                  secondary: const Icon(Icons.brightness_1),
                  value: 'oled',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLanguageDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.t.get('chooseLanguage')),
          content: RadioGroup<String>(
            groupValue: _settings?.language ?? 'pl',
            onChanged: (value) {
              if (value == null) return;
              widget.onLanguageChanged(value);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Polski'),
                  secondary: const Text('🇵🇱', style: TextStyle(fontSize: 24)),
                  value: 'pl',
                ),
                RadioListTile<String>(
                  title: const Text('English'),
                  secondary: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                  value: 'en',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showIntervalDialog() async {
    if (_settings == null) return;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.t.get('chooseInterval')),
          content: RadioGroup<int>(
            groupValue: _settings!.notificationIntervalMinutes,
            onChanged: (value) async {
              final updatedSettings = _settings!.copyWith(
                notificationIntervalMinutes: value,
              );
              await _persistSettings(
                updatedSettings,
                rescheduleReminders: true,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: NotificationService.availableIntervals.map((minutes) {
                return RadioListTile<int>(
                  title: Text(
                    NotificationService.intervalLabel(
                      minutes,
                      _settings!.language,
                    ),
                  ),
                  value: minutes,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.t.get('settings'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.t.get('settings'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
            child: Text(
              widget.t.get('appearance'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          GlassContainer(
            borderRadius: 16,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  leading: Icon(
                    widget.currentThemeMode == 'light'
                        ? Icons.light_mode_rounded
                        : widget.currentThemeMode == 'oled'
                        ? Icons.brightness_1_rounded
                        : Icons.dark_mode_rounded,
                  ),
                  title: Text(widget.t.get('theme')),
                  subtitle: Text(
                    widget.currentThemeMode == 'light'
                        ? widget.t.get('themeLight')
                        : widget.currentThemeMode == 'oled'
                        ? widget.t.get('themeOled')
                        : widget.t.get('themeDark'),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () => _showThemeDialog(),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                ListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  leading: const Icon(Icons.language_rounded),
                  title: Text(widget.t.get('language')),
                  subtitle: Text(
                    AppLocalizations.languageName(_settings?.language ?? 'pl'),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () => _showLanguageDialog(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 20, bottom: 8),
            child: Text(
              widget.t.get('day'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          GlassContainer(
            borderRadius: 16,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(widget.t.get('dayHours')),
                  subtitle: Text(
                    '${_settings!.dayStartHour.toString().padLeft(2, '0')}:${_settings!.dayStartMinute.toString().padLeft(2, '0')} - '
                    '${_settings!.dayEndHour.toString().padLeft(2, '0')}:${_settings!.dayEndMinute.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: _showDayTimeDialog,
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                ListTile(
                  leading: const Icon(Icons.restart_alt_rounded),
                  title: Text(widget.t.get('counterReset')),
                  subtitle: Text(
                    '${widget.t.get('counterResetSubtitle')} ${((_settings!.dayEndHour + 3) % 24).toString().padLeft(2, '0')}:${_settings!.dayEndMinute.toString().padLeft(2, '0')} ${widget.t.get('counterResetAfter')}',
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                ListTile(
                  leading: const Icon(Icons.flag_rounded),
                  title: Text(widget.t.get('dailyGoal')),
                  subtitle: Text(_settings!.formatAmount(_settings!.dailyGoal)),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: _showDailyGoalDialog,
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                ListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  leading: const Icon(Icons.straighten_rounded),
                  title: Text(widget.t.get('units')),
                  subtitle: Text(
                    _settings!.unit == 'ml'
                        ? widget.t.get('unitsMl')
                        : widget.t.get('unitsOz'),
                  ),
                  trailing: Switch(
                    value: _settings!.unit == 'oz',
                    onChanged: (value) async {
                      final updatedSettings = _settings!.copyWith(
                        unit: value ? 'oz' : 'ml',
                      );
                      await _persistSettings(updatedSettings);
                    },
                  ),
                ),
              ],
            ),
          ),
          // ==================== POWIADOMIENIA ====================
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 20, bottom: 8),
            child: Text(
              widget.t.get('notifications'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          GlassContainer(
            borderRadius: 16,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(16),
                      bottom: Radius.circular(
                        _settings!.notificationsEnabled ? 0 : 16,
                      ),
                    ),
                  ),
                  secondary: const Icon(Icons.notifications_rounded),
                  title: Text(widget.t.get('notificationsEnabled')),
                  subtitle: Text(widget.t.get('notificationsEnabledSubtitle')),
                  value: _settings!.notificationsEnabled,
                  onChanged: (value) async {
                    final updatedSettings = _settings!.copyWith(
                      notificationsEnabled: value,
                    );
                    await _persistSettings(
                      updatedSettings,
                      rescheduleReminders: true,
                    );
                  },
                ),
                if (_settings!.notificationsEnabled) ...[
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  ListTile(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    leading: const Icon(Icons.timer_rounded),
                    title: Text(widget.t.get('notificationInterval')),
                    subtitle: Text(
                      NotificationService.intervalLabel(
                        _settings!.notificationIntervalMinutes,
                        _settings!.language,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: _showIntervalDialog,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 20, bottom: 8),
            child: Text(
              widget.t.get('info'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          GlassContainer(
            borderRadius: 16,
            padding: EdgeInsets.zero,
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(widget.t.get('aboutApp')),
              subtitle: const Text('BeHydrated v1.0'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'BeHydrated',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(
                    Icons.water_drop_rounded,
                    size: 48,
                    color: Colors.blue,
                  ),
                  children: [Text(widget.t.get('aboutAppDescription'))],
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
