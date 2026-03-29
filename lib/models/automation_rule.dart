import 'dart:math';

enum RuleTriggerType { sensor, weather }
enum RuleCondition { greaterThan, lessThan, equals }
enum LogicalOperator { and, or }

String _generateId() => 
    DateTime.now().microsecondsSinceEpoch.toString() + 
    Random().nextInt(1000).toString();

class RuleConditionBlock {
  final String id;
  final RuleTriggerType triggerType;
  final String triggerKey; // 'moisture', 'temperature', 'rain'
  final RuleCondition condition;
  final double thresholdValue;

  RuleConditionBlock({
    String? id,
    required this.triggerType,
    required this.triggerKey,
    required this.condition,
    required this.thresholdValue,
  }) : id = id ?? _generateId();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'triggerType': triggerType.name,
      'triggerKey': triggerKey,
      'condition': condition.name,
      'thresholdValue': thresholdValue,
    };
  }

  factory RuleConditionBlock.fromMap(Map<String, dynamic> map) {
    return RuleConditionBlock(
      id: map['id'] as String?,
      triggerType: RuleTriggerType.values.firstWhere(
        (e) => e.name == map['triggerType'],
        orElse: () => RuleTriggerType.sensor,
      ),
      triggerKey: map['triggerKey'] as String? ?? 'moisture',
      condition: RuleCondition.values.firstWhere(
        (e) => e.name == map['condition'],
        orElse: () => RuleCondition.lessThan,
      ),
      thresholdValue: (map['thresholdValue'] as num? ?? 0).toDouble(),
    );
  }
}

class RuleActionBlock {
  final String id;
  final String deviceId;
  final bool actionOn; // true for ON, false for OFF

  RuleActionBlock({
    String? id,
    required this.deviceId,
    required this.actionOn,
  }) : id = id ?? _generateId();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'actionOn': actionOn,
    };
  }

  factory RuleActionBlock.fromMap(Map<String, dynamic> map) {
    return RuleActionBlock(
      id: map['id'] as String?,
      deviceId: map['deviceId'] as String? ?? '',
      actionOn: map['actionOn'] as bool? ?? true,
    );
  }
}

class AutomationRule {
  final String id;
  final String name;
  final bool isEnabled;
  final List<RuleConditionBlock> conditions;
  final LogicalOperator logicalOperator; // 'AND' or 'OR'
  final List<RuleActionBlock> actions;
  final int durationMinutes;

  AutomationRule({
    required this.id,
    required this.name,
    this.isEnabled = true,
    required this.conditions,
    this.logicalOperator = LogicalOperator.and,
    required this.actions,
    this.durationMinutes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isEnabled': isEnabled,
      'conditions': conditions.map((c) => c.toMap()).toList(),
      'logicalOperator': logicalOperator.name,
      'actions': actions.map((a) => a.toMap()).toList(),
      'durationMinutes': durationMinutes,
      'version': 2, 
    };
  }

  factory AutomationRule.fromMap(String id, Map<String, dynamic> map) {
    // Check if it's the old schema (V1)
    if (map['conditions'] == null && map['triggerType'] != null) {
      // Migrate V1 to V2
      final conditionBlock = RuleConditionBlock(
        triggerType: RuleTriggerType.values.firstWhere(
          (e) => e.name == map['triggerType'],
          orElse: () => RuleTriggerType.sensor,
        ),
        triggerKey: map['triggerKey'] as String? ?? 'moisture',
        condition: RuleCondition.values.firstWhere(
          (e) => e.name == map['condition'],
          orElse: () => RuleCondition.lessThan,
        ),
        thresholdValue: (map['thresholdValue'] as num? ?? 0).toDouble(),
      );

      final actionBlock = RuleActionBlock(
        deviceId: map['deviceId'] as String? ?? '',
        actionOn: map['actionOn'] as bool? ?? true,
      );

      return AutomationRule(
        id: id,
        name: map['name'] as String? ?? 'Quy tắc mới',
        isEnabled: map['isEnabled'] as bool? ?? true,
        conditions: [conditionBlock],
        logicalOperator: LogicalOperator.and,
        actions: [actionBlock],
        durationMinutes: map['durationMinutes'] as int? ?? 0,
      );
    }

    // New Schema V2
    final conditionsList = (map['conditions'] as List? ?? [])
        .map((e) => RuleConditionBlock.fromMap(e as Map<String, dynamic>))
        .toList();

    final actionsList = (map['actions'] as List? ?? [])
        .map((e) => RuleActionBlock.fromMap(e as Map<String, dynamic>))
        .toList();

    return AutomationRule(
      id: id,
      name: map['name'] as String? ?? 'Quy tắc mới',
      isEnabled: map['isEnabled'] as bool? ?? true,
      conditions: conditionsList,
      logicalOperator: LogicalOperator.values.firstWhere(
        (e) => e.name == map['logicalOperator'],
        orElse: () => LogicalOperator.and,
      ),
      actions: actionsList,
      durationMinutes: map['durationMinutes'] as int? ?? 0,
    );
  }

  AutomationRule copyWith({
    String? name,
    bool? isEnabled,
    List<RuleConditionBlock>? conditions,
    LogicalOperator? logicalOperator,
    List<RuleActionBlock>? actions,
    int? durationMinutes,
  }) {
    return AutomationRule(
      id: this.id, // Must preserve original id
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      conditions: conditions ?? List.from(this.conditions), // copy lists for safety
      logicalOperator: logicalOperator ?? this.logicalOperator,
      actions: actions ?? List.from(this.actions),
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
