import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/area_config.dart';
import '../../models/automation_rule.dart';
import '../../models/watering_schedule.dart';
import '../../providers/garden_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/delete_area_dialog.dart';
import '../../widgets/device/timer_picker_dialog.dart';
import '../../widgets/device/schedule_manager_dialog.dart';
import 'widgets/rule_builder_sheet.dart';
import 'widgets/config_section_header.dart';
import 'widgets/config_range_labels.dart';
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
    _nameController.addListener(_onChanged);
  }

  void _onChanged() => setState(() => _hasChanges = true);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

            // ── Watering Schedules (Scheduled Watering) ──────────────────
            Row(
              children: [
                Expanded(
                  child: ConfigSectionHeader(
                    icon: Icons.schedule_rounded,
                    color: AppColors.primaryGreen,
                    title: 'Lịch tưới định kỳ',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showScheduleManager(context, garden),
                  icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                  label: const Text('Quản lý lịch'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 320.ms),

            AppCard(
              onTap: () => _showScheduleManager(context, garden),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          area.schedules.isEmpty 
                              ? 'Chưa có lịch tưới nào' 
                              : 'Đang có ${area.schedules.length} lịch tưới được thiết lập',
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          area.schedules.isEmpty 
                              ? 'Nhấn để bắt đầu thêm lịch mới' 
                              : 'Nhấn để xem hoặc điều chỉnh lịch trình',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ).animate().fadeIn(delay: 330.ms),

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
                  onTap: () => _showRuleDialog(context, garden, rule),
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

  String _formatDays(List<int> days) {
    if (days.length == 7) return 'Hàng ngày';
    final List<String> labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days.map((d) => labels[d - 1]).join(', ');
  }

  void _showScheduleManager(BuildContext context, GardenProvider garden) async {
    final area = garden.getArea(widget.areaId);
    if (area == null) return;

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleManagerDialog(
        area: area,
        garden: garden,
      ),
    );

    if (result == 'add') {
      if (!mounted) return;
      _showScheduleDialog(context, garden);
    }
  }

  void _showScheduleDialog(BuildContext context, GardenProvider garden) {
    final area = garden.getArea(widget.areaId);
    if (area == null) return;

    String selectedDeviceId = area.devices.first.id;
    String selectedDeviceName = area.devices.first.name;
    TimeOfDay selectedTime = const TimeOfDay(hour: 6, minute: 0);
    int duration = 10;
    List<int> selectedDays = [1, 2, 3, 4, 5, 6, 7];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

          return Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 30),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Thêm lịch tưới', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Device selector
                  Text('Thiết bị', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                      color: AppColors.primaryGreen.withValues(alpha: 0.05),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedDeviceId,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryGreen),
                        items: area.devices.map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Row(
                            children: [
                              Icon(
                                d.type == 'pump' ? Icons.water_drop_rounded
                                    : d.type == 'mist' ? Icons.cloud_rounded
                                    : Icons.air_rounded,
                                color: AppColors.primaryGreen, size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(d.name),
                            ],
                          ),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedDeviceId = val;
                              selectedDeviceName = area.devices.firstWhere((d) => d.id == val).name;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Time & Duration
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Thời gian', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                  builder: (ctx2, child) => Theme(
                                    data: Theme.of(ctx2).copyWith(
                                      colorScheme: Theme.of(ctx2).colorScheme.copyWith(primary: AppColors.primaryGreen),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) setDialogState(() => selectedTime = picked);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                  color: Colors.blue.withValues(alpha: 0.05),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded, color: Colors.blue, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Thời lượng', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                color: Colors.orange.withValues(alpha: 0.05),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_rounded, size: 20),
                                    onPressed: () => setDialogState(() => duration = (duration > 1 ? duration - 1 : 1)),
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.zero,
                                    color: Colors.orange,
                                  ),
                                  Text('$duration phút', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_rounded, size: 20),
                                    onPressed: () => setDialogState(() => duration++),
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.zero,
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Day picker
                  Text('Ngày trong tuần', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      final isSelected = selectedDays.contains(day);
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            if (isSelected) selectedDays.remove(day);
                            else selectedDays.add(day);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGreen : Colors.grey.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              labels[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setDialogState(() => selectedDays = [1, 2, 3, 4, 5, 6, 7]),
                        child: const Text('Tất cả', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen)),
                      ),
                      TextButton(
                        onPressed: () => setDialogState(() => selectedDays = [1, 2, 3, 4, 5]),
                        child: const Text('Ngày thường', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen)),
                      ),
                      TextButton(
                        onPressed: () => setDialogState(() => selectedDays = [6, 7]),
                        child: const Text('Cuối tuần', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  ElevatedButton.icon(
                    onPressed: selectedDays.isEmpty ? null : () {
                      final schedule = WateringSchedule(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        deviceId: selectedDeviceId,
                        deviceName: selectedDeviceName,
                        hour: selectedTime.hour,
                        minute: selectedTime.minute,
                        durationMinutes: duration,
                        daysOfWeek: selectedDays..sort(),
                      );
                      garden.addWateringSchedule(widget.areaId, schedule);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Thêm lịch tưới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


