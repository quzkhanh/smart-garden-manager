import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/area_config.dart';
import '../../providers/garden_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_card.dart';

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
    final garden =
        Provider.of<GardenProvider>(context, listen: false);
    final area = garden.getArea(widget.areaId);
    final config = area?.config ?? const AreaConfig();
    _nameController = TextEditingController(text: area?.name ?? '');
    _soilThreshold = config.soilMoistureThreshold;
    _maxTemp = config.maxTemperature;
    _lightOn = TimeOfDay(
        hour: config.lightOnHour, minute: config.lightOnMinute);
    _lightOff = TimeOfDay(
        hour: config.lightOffHour, minute: config.lightOffMinute);
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
      _showSnackBar(
          context, AppLocalizations.of(context).t('config_error'),
          isError: true);
      return;
    }
    setState(() => _isSaving = true);

    // Simulate async Firebase write (replace with actual Firebase call):
    // await DatabaseReference.child('zones/${widget.areaId}/name').set(name);
    // await DatabaseReference.child('zones/${widget.areaId}/configs').update(config.toMap());
    await Future.delayed(const Duration(milliseconds: 600));

    final garden =
        Provider.of<GardenProvider>(context, listen: false);
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
    _showSnackBar(
        context, AppLocalizations.of(context).t('config_saved'));
  }

  void _showSnackBar(BuildContext context, String msg,
      {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(msg,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
          backgroundColor:
              isError ? AppColors.alertHigh : AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.chevron_left_rounded, size: 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // ── Area Name ─────────────────────────────────────────────────
            _SectionHeader(
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
                  prefixIcon: const Icon(Icons.label_outline_rounded,
                      color: AppColors.secondaryBlue, size: 20),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Water / Soil Moisture ──────────────────────────────────────
            _SectionHeader(
              icon: Icons.water_drop_rounded,
              color: AppColors.secondaryBlue,
              title: l10n.t('config_water'),
            ).animate().fadeIn(delay: 120.ms, duration: 400.ms),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('config_soil_threshold'),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.t('config_soil_hint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.grass_rounded,
                          size: 18, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primaryGreen,
                            inactiveTrackColor: AppColors.primaryGreen
                                .withValues(alpha: 0.2),
                            thumbColor: AppColors.primaryGreen,
                            overlayColor: AppColors.primaryGreen
                                .withValues(alpha: 0.12),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen
                              .withValues(alpha: isDark ? 0.2 : 0.1),
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
                  _RangeLabels(min: '10%', max: '90%'),
                ],
              ),
            ).animate().fadeIn(delay: 160.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Temperature ────────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.thermostat_rounded,
              color: Colors.orange,
              title: l10n.t('config_temperature'),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('config_max_temp'),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.t('config_max_temp_hint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.thermostat_rounded,
                          size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.orange,
                            inactiveTrackColor:
                                Colors.orange.withValues(alpha: 0.2),
                            thumbColor: Colors.orange,
                            overlayColor:
                                Colors.orange.withValues(alpha: 0.12),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange
                              .withValues(alpha: isDark ? 0.2 : 0.1),
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
                  _RangeLabels(min: '20°C', max: '45°C'),
                ],
              ),
            ).animate().fadeIn(delay: 240.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Lighting Schedule ──────────────────────────────────────────
            _SectionHeader(
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withValues(alpha: isDark ? 0.25 : 0.12),
                          Colors.orange.withValues(alpha: isDark ? 0.15 : 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.amber
                              .withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wb_sunny_rounded,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(_lightOn),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.amber.withValues(alpha: 0.7)),
                        ),
                        const Icon(Icons.nights_stay_rounded,
                            color: Colors.amber, size: 18),
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
                        child: _TimeButton(
                          label: l10n.t('config_light_on'),
                          time: _formatTime(_lightOn),
                          icon: Icons.wb_sunny_rounded,
                          color: Colors.amber,
                          onTap: () => _pickTime(context, true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeButton(
                          label: l10n.t('config_light_off'),
                          time: _formatTime(_lightOff),
                          icon: Icons.nights_stay_rounded,
                          color: Colors.blueGrey,
                          onTap: () => _pickTime(context, false),
                        ),
                      ),
                    ],
                  ),

                  // Duration display
                  const SizedBox(height: 12),
                  _DurationRow(on: _lightOn, off: _lightOff, l10n: l10n),
                ],
              ),
            ).animate().fadeIn(delay: 320.ms, duration: 400.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),

      // ── Save Button ─────────────────────────────────────────────────────
      bottomNavigationBar: _SaveBar(
        hasChanges: _hasChanges,
        isSaving: _isSaving,
        label: l10n.t('update_config'),
        onSave: _save,
      ),
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Range Labels ──────────────────────────────────────────────────────────────

class _RangeLabels extends StatelessWidget {
  final String min;
  final String max;

  const _RangeLabels({required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context)
              .textTheme
              .bodySmall
              ?.color
              ?.withValues(alpha: 0.5),
          fontSize: 11,
        );
    return Padding(
      padding: const EdgeInsets.only(left: 26, top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(min, style: style),
          Text(max, style: style),
        ],
      ),
    );
  }
}

// ── Time Button ───────────────────────────────────────────────────────────────

class _TimeButton extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Duration Row ──────────────────────────────────────────────────────────────

class _DurationRow extends StatelessWidget {
  final TimeOfDay on;
  final TimeOfDay off;
  final AppLocalizations l10n;

  const _DurationRow(
      {required this.on, required this.off, required this.l10n});

  int _durationMinutes() {
    final onMins = on.hour * 60 + on.minute;
    final offMins = off.hour * 60 + off.minute;
    // Handle overnight (e.g. 22:00 → 06:00)
    return offMins >= onMins
        ? offMins - onMins
        : (24 * 60 - onMins) + offMins;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durationMins = _durationMinutes();
    final h = durationMins ~/ 60;
    final m = durationMins % 60;
    final durationStr = h > 0
        ? (m > 0 ? '${h}h ${m}ph' : '${h}h')
        : '${m}ph';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer_outlined, size: 14, color: Colors.amber),
        const SizedBox(width: 6),
        Text(
          '${l10n.t('config_light_duration')}: $durationStr',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.amber.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Save Bar ──────────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  final bool hasChanges;
  final bool isSaving;
  final String label;
  final VoidCallback onSave;

  const _SaveBar({
    required this.hasChanges,
    required this.isSaving,
    required this.label,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2128) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: AnimatedOpacity(
            opacity: hasChanges ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: (hasChanges && !isSaving) ? onSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primaryGreen.withValues(alpha: 0.5),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_upload_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
}
