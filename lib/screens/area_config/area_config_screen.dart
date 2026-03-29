import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/area_config.dart';
import '../../models/area.dart';
import '../../models/automation_rule.dart';
import '../../providers/garden_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/delete_area_dialog.dart';
import 'widgets/rule_builder_sheet.dart';
import 'widgets/config_section_header.dart';
import 'widgets/config_range_labels.dart';
import 'widgets/config_time_button.dart';
import 'widgets/config_duration_row.dart';
import 'widgets/config_save_bar.dart';

class AreaConfigScreen extends StatefulWidget {
  final String areaId;

  const AreaConfigScreen({super.key, required this.areaId});

  @override
  State<AreaConfigScreen> createState() => _AreaConfigScreenState();
}

class _AreaConfigScreenState extends State<AreaConfigScreen> {
  late TextEditingController _nameController;
  late double _soilThreshold;
  late double _maxTemp;
  late TimeOfDay _lightOn;
  late TimeOfDay _lightOff;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final garden = Provider.of<GardenProvider>(context, listen: false);
    final area = garden.getArea(widget.areaId);
    final config = area?.config ?? const AreaConfig();
    _nameController = TextEditingController(text: area?.name ?? '');
    _soilThreshold = config.soilMoistureThreshold;
    _maxTemp = config.maxTemperature;
    _lightOn = TimeOfDay(hour: config.lightOnHour, minute: config.lightOnMinute);
    _lightOff = TimeOfDay(hour: config.lightOffHour, minute: config.lightOffMinute);
    _nameController.addListener(_onChanged);
  }

  void _onChanged() => setState(() => _hasChanges = true);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context, bool isOn) async {
    final initial = isOn ? _lightOn : _lightOff;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryGreen,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isOn) {
          _lightOn = picked;
        } else {
          _lightOff = picked;
        }
        _hasChanges = true;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar(context, AppLocalizations.of(context).t('config_error'), isError: true);
      return;
    }
    setState(() => _isSaving = true);

    final garden = Provider.of<GardenProvider>(context, listen: false);
    final config = AreaConfig(
      soilMoistureThreshold: _soilThreshold,
      maxTemperature: _maxTemp,
      lightOnHour: _lightOn.hour,
      lightOnMinute: _lightOn.minute,
      lightOffHour: _lightOff.hour,
      lightOffMinute: _lightOff.minute,
    );
    garden.updateAreaName(widget.areaId, name);
    garden.updateAreaConfig(widget.areaId, config);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _hasChanges = false;
    });
    _showSnackBar(context, AppLocalizations.of(context).t('config_saved'));
  }

  void _showSnackBar(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(msg, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
          backgroundColor: isError ? AppColors.alertHigh : AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final garden = Provider.of<GardenProvider>(context);
    final area = garden.getArea(widget.areaId);

    if (area == null) return const Scaffold(body: Center(child: Text('Khu vực không tồn tại')));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.t('area_config'), style: theme.textTheme.titleLarge),
            Text(l10n.t('area_detail'), style: theme.textTheme.bodySmall),
          ],
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_left_rounded, size: 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // ── Area Name ─────────────────────────────────────────────────
            ConfigSectionHeader(
              icon: Icons.edit_rounded,
              color: AppColors.secondaryBlue,
              title: l10n.t('area_name'),
            ).animate().fadeIn(duration: 400.ms),

            AppCard(
              child: TextField(
                controller: _nameController,
                style: theme.textTheme.bodyLarge,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(40),
                ],
                decoration: InputDecoration(
                  hintText: l10n.t('area_name_hint'),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.label_outline_rounded, color: AppColors.secondaryBlue, size: 20),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Water / Soil Moisture ──────────────────────────────────────
            ConfigSectionHeader(
              icon: Icons.water_drop_rounded,
              color: AppColors.secondaryBlue,
              title: l10n.t('config_water'),
            ).animate().fadeIn(delay: 120.ms, duration: 400.ms),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.t('config_soil_threshold'), style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    l10n.t('config_soil_hint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.grass_rounded, size: 18, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primaryGreen,
                            inactiveTrackColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                            thumbColor: AppColors.primaryGreen,
                            overlayColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _soilThreshold,
                            min: 10,
                            max: 90,
                            divisions: 80,
                            onChanged: (v) => setState(() {
                              _soilThreshold = v;
                              _hasChanges = true;
                            }),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_soilThreshold.round()}%',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const ConfigRangeLabels(min: '10%', max: '90%'),
                ],
              ),
            ).animate().fadeIn(delay: 160.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Temperature ────────────────────────────────────────────────
            ConfigSectionHeader(
              icon: Icons.thermostat_rounded,
              color: Colors.orange,
              title: l10n.t('config_temperature'),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.t('config_max_temp'), style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    l10n.t('config_max_temp_hint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.thermostat_rounded, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.orange,
                            inactiveTrackColor: Colors.orange.withValues(alpha: 0.2),
                            thumbColor: Colors.orange,
                            overlayColor: Colors.orange.withValues(alpha: 0.12),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _maxTemp,
                            min: 20,
                            max: 45,
                            divisions: 50,
                            onChanged: (v) => setState(() {
                              _maxTemp = v;
                              _hasChanges = true;
                            }),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_maxTemp.round()}°C',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const ConfigRangeLabels(min: '20°C', max: '45°C'),
                ],
              ),
            ).animate().fadeIn(delay: 240.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Lighting Schedule ──────────────────────────────────────────
            ConfigSectionHeader(
              icon: Icons.wb_sunny_rounded,
              color: Colors.amber,
              title: l10n.t('config_lighting'),
            ).animate().fadeIn(delay: 280.ms, duration: 400.ms),

            AppCard(
              child: Column(
                children: [
                  // Schedule summary banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withValues(alpha: isDark ? 0.25 : 0.12),
                          Colors.orange.withValues(alpha: isDark ? 0.15 : 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(_lightOn),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.amber.withValues(alpha: 0.7)),
                        ),
                        const Icon(Icons.nights_stay_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(_lightOff),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Time picker buttons
                  Row(
                    children: [
                      Expanded(
                        child: ConfigTimeButton(
                          label: l10n.t('config_light_on'),
                          time: _formatTime(_lightOn),
                          icon: Icons.wb_sunny_rounded,
                          color: Colors.amber,
                          onTap: () => _pickTime(context, true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ConfigTimeButton(
                          label: l10n.t('config_light_off'),
                          time: _formatTime(_lightOff),
                          icon: Icons.nights_stay_rounded,
                          secondaryIcon: Icons.star_rounded,
                          color: const Color(0xFF001F3F), // Solid Color for Solid Background
                          onTap: () => _pickTime(context, false),
                        ),
                      ),
                    ],
                  ),

                  // Duration display
                  const SizedBox(height: 12),
                  ConfigDurationRow(on: _lightOn, off: _lightOff),
                ],
              ),
            ).animate().fadeIn(delay: 320.ms, duration: 400.ms),

            const SizedBox(height: 32),

            // ── Custom Automations ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.t('custom_automations').toUpperCase(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showRuleDialog(context, garden),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.t('add_rule')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 340.ms),
            
            const SizedBox(height: 12),
            
            if (area.rules.isEmpty)
              AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Icon(Icons.auto_fix_high_rounded, size: 40, color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có quy tắc tự động nào',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 360.ms)
            else
              Column(
                children: area.rules.map((rule) => AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (rule.isEnabled ? AppColors.primaryGreen : Colors.grey).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          rule.conditions.any((c) => c.triggerType == RuleTriggerType.weather) 
                              ? Icons.cloud_queue_rounded 
                              : Icons.sensors_rounded,
                          color: rule.isEnabled ? AppColors.primaryGreen : Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rule.name, style: theme.textTheme.titleSmall),
                            const SizedBox(height: 2),
                            Text(
                              'NẾU ${rule.conditions.length} điều kiện THÌ ${rule.actions.length} hành động',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: rule.isEnabled,
                        onChanged: (val) => garden.updateRule(widget.areaId, rule.copyWith(isEnabled: val)),
                        activeTrackColor: AppColors.primaryGreen,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        onPressed: () => garden.deleteRule(widget.areaId, rule.id),
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                )).toList(),
              ).animate().fadeIn(delay: 360.ms),

            const SizedBox(height: 48),

            // ── Danger Zone ───────────────────────────────────────────────
            Text(
              'Danger Zone',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.red.shade400,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ).animate().fadeIn(delay: 360.ms),
            const SizedBox(height: 8),
            AppCard(
              onTap: () => _confirmDeleteArea(context),
              child: Row(
                children: [
                  Icon(Icons.delete_forever_rounded, color: Colors.red.shade400, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Xóa bản ghi khu vực này',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.red.withValues(alpha: 0.3)),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: ConfigSaveBar(
        hasChanges: _hasChanges,
        isSaving: _isSaving,
        label: l10n.t('update_config'),
        onSave: _save,
      ),
    );
  }


  void _confirmDeleteArea(BuildContext context) {
    final garden = Provider.of<GardenProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => DeleteAreaDialog(
        areaName: _nameController.text.trim(),
        onConfirm: () {
          garden.deleteArea(widget.areaId);
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  void _showRuleDialog(BuildContext context, GardenProvider garden, [AutomationRule? rule]) {
    final area = garden.getArea(widget.areaId);
    if (area == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RuleBuilderSheet(
        areaId: widget.areaId,
        area: area,
        garden: garden,
        existingRule: rule,
      ),
    );
  }

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
