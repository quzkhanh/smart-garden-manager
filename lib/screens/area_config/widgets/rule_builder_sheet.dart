import 'package:flutter/material.dart';
import '../../../models/automation_rule.dart';
import '../../../models/area.dart';
import '../../../providers/garden_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class RuleBuilderSheet extends StatefulWidget {
  final String areaId;
  final Area area;
  final GardenProvider garden;
  final AutomationRule? existingRule;

  const RuleBuilderSheet({
    super.key,
    required this.areaId,
    required this.area,
    required this.garden,
    this.existingRule,
  });

  @override
  State<RuleBuilderSheet> createState() => _RuleBuilderSheetState();
}

class _RuleBuilderSheetState extends State<RuleBuilderSheet> {
  late TextEditingController _nameController;
  late List<RuleConditionBlock> _conditions;
  late List<RuleActionBlock> _actions;
  late LogicalOperator _logicalOperator;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingRule?.name ?? '');
    _conditions = widget.existingRule?.conditions.toList() ?? [];
    _actions = widget.existingRule?.actions.toList() ?? [];
    _logicalOperator = widget.existingRule?.logicalOperator ?? LogicalOperator.and;

    // Add at least one default if new
    if (_conditions.isEmpty) {
      _conditions.add(RuleConditionBlock(
        triggerType: RuleTriggerType.sensor,
        triggerKey: 'moisture',
        condition: RuleCondition.lessThan,
        thresholdValue: 30,
      ));
    }
    if (_actions.isEmpty) {
      if (widget.area.devices.isNotEmpty) {
        _actions.add(RuleActionBlock(
          deviceId: widget.area.devices.first.id,
          actionOn: true,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveRule() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('Vui lòng nhập tên quy tắc')),
          backgroundColor: AppColors.alertHigh,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final rule = AutomationRule(
      id: widget.existingRule?.id ?? 'rule_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      isEnabled: widget.existingRule?.isEnabled ?? true,
      conditions: _conditions,
      logicalOperator: _logicalOperator,
      actions: _actions,
    );

    if (widget.existingRule == null) {
      widget.garden.addRule(widget.areaId, rule);
    } else {
      widget.garden.updateRule(widget.areaId, rule);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existingRule == null ? 'Thêm quy tắc mới' : 'Chỉnh sửa quy tắc',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên quy tắc',
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── IF SECTION ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('NẾU (Điều kiện)', style: theme.textTheme.titleSmall?.copyWith(color: Colors.amber.shade700, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ..._conditions.asMap().entries.map((entry) => _buildConditionBlock(entry.key, entry.value)),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _conditions.add(RuleConditionBlock(
                                triggerType: RuleTriggerType.sensor,
                                triggerKey: 'moisture',
                                condition: RuleCondition.lessThan,
                                thresholdValue: 30,
                              ));
                            });
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Thêm điều kiện'),
                          style: TextButton.styleFrom(foregroundColor: Colors.amber.shade700),
                        ),
                      ],
                    ),
                  ),

                  // ── OPERATOR TOGGLE ─────────────────────────────────────
                  if (_conditions.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SegmentedButton<LogicalOperator>(
                          segments: const [
                            ButtonSegment(value: LogicalOperator.and, label: Text('Thỏa mãn TẤT CẢ (VÀ)')),
                            ButtonSegment(value: LogicalOperator.or, label: Text('Chỉ cần 1 (HOẶC)')),
                          ],
                          selected: {_logicalOperator},
                          onSelectionChanged: (set) => setState(() => _logicalOperator = set.first),
                        ),
                      ),
                    ),
                  if (_conditions.length <= 1) const SizedBox(height: 24),

                  // ── THEN SECTION ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('THÌ (Hành động)', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ..._actions.asMap().entries.map((entry) => _buildActionBlock(entry.key, entry.value)),
                        TextButton.icon(
                          onPressed: () {
                            if (widget.area.devices.isNotEmpty) {
                              setState(() {
                                _actions.add(RuleActionBlock(
                                  deviceId: widget.area.devices.first.id,
                                  actionOn: true,
                                ));
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).t('Khu vực này chưa có thiết bị nào. Vui lòng thêm thiết bị trước.')),
                                  backgroundColor: AppColors.alertHigh,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Thêm hành động'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primaryGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_conditions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).t('Vui lòng thêm ít nhất 1 điều kiện')),
                    backgroundColor: AppColors.alertHigh,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }
              if (_actions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).t('Vui lòng thêm ít nhất 1 hành động')),
                    backgroundColor: AppColors.alertHigh,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }
              _saveRule();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Lưu quy tắc', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionBlock(int index, RuleConditionBlock condition) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RuleTriggerType>(
                    value: condition.triggerType,
                    isExpanded: true,
                    isDense: true,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: RuleTriggerType.sensor, child: Text('Cảm biến')),
                      DropdownMenuItem(value: RuleTriggerType.weather, child: Text('Thời tiết ngoài trời')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _conditions[index] = RuleConditionBlock(
                            id: condition.id,
                            triggerType: val,
                            triggerKey: val == RuleTriggerType.weather ? 'rain' : 'moisture',
                            condition: condition.condition,
                            thresholdValue: condition.thresholdValue,
                          );
                        });
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _conditions.removeAt(index)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: condition.triggerKey,
                    isExpanded: true,
                    isDense: true,
                    items: condition.triggerType == RuleTriggerType.sensor
                        ? const [
                            DropdownMenuItem(value: 'moisture', child: Text('Độ ẩm đất')),
                            DropdownMenuItem(value: 'temperature', child: Text('Nhiệt độ')),
                            DropdownMenuItem(value: 'humidity', child: Text('Độ ẩm KK')),
                          ]
                        : const [
                            DropdownMenuItem(value: 'rain', child: Text('Trời mưa')),
                            DropdownMenuItem(value: 'temp', child: Text('Nhiệt độ')),
                          ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _conditions[index] = RuleConditionBlock(
                            id: condition.id,
                            triggerType: condition.triggerType,
                            triggerKey: val,
                            condition: condition.condition,
                            thresholdValue: condition.thresholdValue,
                          );
                        });
                      }
                    },
                  ),
                ),
              ),
              if (!(condition.triggerType == RuleTriggerType.weather && condition.triggerKey == 'rain')) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<RuleCondition>(
                      value: condition.condition,
                      isExpanded: true,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: RuleCondition.lessThan, child: Text('<')),
                        DropdownMenuItem(value: RuleCondition.greaterThan, child: Text('>')),
                        DropdownMenuItem(value: RuleCondition.equals, child: Text('=')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _conditions[index] = RuleConditionBlock(
                              id: condition.id,
                              triggerType: condition.triggerType,
                              triggerKey: condition.triggerKey,
                              condition: val,
                              thresholdValue: condition.thresholdValue,
                            );
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: condition.thresholdValue.toInt().toString(),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        _conditions[index] = RuleConditionBlock(
                          id: condition.id,
                          triggerType: condition.triggerType,
                          triggerKey: condition.triggerKey,
                          condition: condition.condition,
                          thresholdValue: parsed,
                        );
                      }
                    },
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBlock(int index, RuleActionBlock action) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.area.devices.any((d) => d.id == action.deviceId) ? action.deviceId : null,
                isExpanded: true,
                isDense: true,
                hint: const Text('Chọn thiết bị'),
                items: widget.area.devices.map((d) {
                  return DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _actions[index] = RuleActionBlock(
                        id: action.id,
                        deviceId: val,
                        actionOn: action.actionOn,
                      );
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<bool>(
                value: action.actionOn,
                isExpanded: true,
                isDense: true,
                items: const [
                  DropdownMenuItem(value: true, child: Text('BẬT', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: false, child: Text('TẮT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _actions[index] = RuleActionBlock(
                        id: action.id,
                        deviceId: action.deviceId,
                        actionOn: val,
                      );
                    });
                  }
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _actions.removeAt(index)),
          ),
        ],
      ),
    );
  }
}
