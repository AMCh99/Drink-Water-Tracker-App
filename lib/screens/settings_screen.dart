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
  String _selectedThemeMode = 'light';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.currentThemeMode;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _dbHelper.getDaySettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _selectedThemeMode = settings.themeMode;
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

  Future<void> _applyTheme(String mode) async {
    if (_selectedThemeMode == mode) return;

    setState(() {
      _selectedThemeMode = mode;
    });

    await widget.onThemeChanged(mode);
    await _loadSettings();
  }

  Widget _buildThemeChoiceCard({
    required String mode,
    required String label,
    required Color backgroundColor,
    required Color labelColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedThemeMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => _applyTheme(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 118,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.18),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? colorScheme.primary
                      : labelColor.withValues(alpha: 0.22),
                ),
                child: Icon(
                  isSelected ? Icons.check_rounded : Icons.brightness_1,
                  size: 22,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : labelColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showThemeDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.t.get('chooseTheme')),
          content: RadioGroup<String>(
            groupValue: _selectedThemeMode,
            onChanged: (value) {
              if (value == null) return;
              _applyTheme(value);
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

  String _formatTimeString(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return value;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return value;

    final timeOfDay = TimeOfDay(hour: hour, minute: minute);
    return timeOfDay.format(context);
  }

  Future<void> _addNotificationTime() async {
    if (_settings == null) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked == null) return;

    final timeValue =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final currentTimes = [..._settings!.notificationTimes];
    if (currentTimes.contains(timeValue)) return;
    currentTimes.add(timeValue);
    currentTimes.sort();

    final updatedSettings = _settings!.copyWith(
      notificationTimes: currentTimes,
    );
    await _persistSettings(updatedSettings, rescheduleReminders: true);
  }

  Future<void> _removeNotificationTime(String timeValue) async {
    if (_settings == null) return;

    final updatedTimes = [..._settings!.notificationTimes]..remove(timeValue);
    final updatedSettings = _settings!.copyWith(
      notificationTimes: updatedTimes,
    );
    await _persistSettings(updatedSettings, rescheduleReminders: true);
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
            padding: const EdgeInsets.only(left: 4, top: 16, bottom: 10),
            child: Text(
              widget.t.get('appearance'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.t.get('theme'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _showThemeDialog,
                      icon: const Icon(Icons.tune_rounded),
                      tooltip: widget.t.get('chooseTheme'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildThemeChoiceCard(
                      mode: 'light',
                      label: widget.t.get('themeLight'),
                      backgroundColor: Colors.white,
                      labelColor: const Color(0xFF1F2937),
                    ),
                    const SizedBox(width: 10),
                    _buildThemeChoiceCard(
                      mode: 'dark',
                      label: widget.t.get('themeDark'),
                      backgroundColor: const Color(0xFF2E333D),
                      labelColor: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    _buildThemeChoiceCard(
                      mode: 'oled',
                      label: widget.t.get('themeOled'),
                      backgroundColor: Colors.black,
                      labelColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                ListTile(
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
                  contentPadding: EdgeInsets.zero,
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
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  secondary: const Icon(Icons.volume_up_rounded),
                  title: Text(widget.t.get('soundsEnabled')),
                  subtitle: Text(widget.t.get('soundsEnabledSubtitle')),
                  value: _settings!.soundsEnabled,
                  onChanged: (value) async {
                    final updatedSettings = _settings!.copyWith(
                      soundsEnabled: value,
                    );
                    await _persistSettings(updatedSettings);
                  },
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
                  leading: const Icon(Icons.notifications_active_rounded),
                  title: Text(
                    '${widget.t.get('notificationTimes')} (${_settings!.notificationTimes.length})',
                  ),
                  subtitle: Text(
                    _settings!.notificationTimes.isEmpty
                        ? widget.t.get('notificationTimesEmpty')
                        : widget.t.get('notificationTimesSubtitle'),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    onPressed: _addNotificationTime,
                    tooltip: widget.t.get('addNotificationTime'),
                  ),
                ),
                if (_settings!.notificationTimes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _settings!.notificationTimes.map((time) {
                        return InputChip(
                          label: Text(_formatTimeString(time)),
                          deleteIcon: const Icon(Icons.close_rounded),
                          onDeleted: () => _removeNotificationTime(time),
                        );
                      }).toList(),
                    ),
                  ),
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
