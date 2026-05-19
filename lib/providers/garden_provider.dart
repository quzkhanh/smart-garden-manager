import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/area.dart';
import '../models/area_config.dart';
import '../models/sensor_reading.dart';
import '../models/sensor.dart';
import '../models/device.dart';
import '../models/automation_rule.dart';
import '../models/watering_schedule.dart';
import '../models/alert.dart';
import '../services/weather_service.dart';
import '../services/activity_log_service.dart';
import 'auth_provider.dart';

class GardenProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Area> _areas = [];
  bool _isLoading = true;
  String? _uid;
  AuthProvider? _authProvider;
  StreamSubscription? _areasSubscription;
  Timer? _timerCheckTimer;
  Timer? _weatherTimer;
  Timer? _evalTimer;
  final Map<String, Set<String>> _sentAlerts = {};
  bool _disposed = false;
  String _language = 'vi';
  final WeatherService _weatherService = WeatherService();
  WeatherData? _currentWeather;
  List<WeatherData> _forecast = [];
  bool _hasActiveTimers = false; // Track if any device has an active timer
  bool _orphanCleanupDone = false; // One-time cleanup flag

  List<Area> get areas => _areas;
  bool get isLoading => _isLoading;

  int get totalAreas => _areas.length;
  int get totalActiveDevices =>
      _areas.fold<int>(0, (sum, area) => sum + area.activeDeviceCount);
  int get totalDevices =>
      _areas.fold<int>(0, (sum, area) => sum + area.totalDeviceCount);
  WeatherData? get currentWeather => _currentWeather;
  List<WeatherData> get forecast => _forecast;

  GardenProvider() {
    // Timer check is started on-demand only when a device has an active timer
    // (see _startTimerCheckIfNeeded / _stopTimerCheckIfIdle)
    
    // Check weather every 15 minutes
    _weatherTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => fetchWeather(),
    );
    fetchWeather(); // Initial fetch
  }

  @override
  void dispose() {
    _disposed = true;
    _timerCheckTimer?.cancel();
    _weatherTimer?.cancel();
    _areasSubscription?.cancel();
    _evalTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void _startEvaluationTimer() {
    _evalTimer?.cancel();
    // Check schedules and thresholds every minute
    _evalTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _evaluateThresholds();
      _evaluateSchedules();
      notifyListeners(); // Refresh UI to update isOnline status (which depends on current time)
    });
  }

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
    final newUid = auth.uid;
    if (_uid == newUid) return;
    
    _uid = newUid;
    _areasSubscription?.cancel();
    _evalTimer?.cancel();
    
    if (_uid == null) {
      _areas = [];
      _isLoading = false;
      notifyListeners();
    } else {
      _listenToAreas();
      _startEvaluationTimer();
    }
  }

  void updateLocale(String languageCode) {
    if (_language == languageCode) return;
    _language = languageCode;
    fetchWeather(); // Fetch weather in new language
  }

  void _listenToAreas() {
    _isLoading = true;
    notifyListeners();

    _areasSubscription = _firestore
        .collection('users')
        .doc(_uid)
        .collection('areas')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      final List<Area> updatedAreas = [];
      final List<_OrphanCleanup> orphansToClean = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final area = Area.fromMap(doc.id, data);
          updatedAreas.add(area);

          // Collect orphaned data for one-time cleanup (not every snapshot)
          if (!_orphanCleanupDone) {
            final rawSchedules = (data['schedules'] as List? ?? []);
            final rawRules = (data['rules'] as List? ?? []);
            if (rawSchedules.length != area.schedules.length ||
                rawRules.length != area.rules.length) {
              orphansToClean.add(_OrphanCleanup(doc.id, area));
            }
          }
        } catch (e) {
          debugPrint('Error parsing area ${doc.id}: $e');
        }
      }
      _areas = updatedAreas;
      _isLoading = false;

      // Run orphan cleanup only once to avoid write→read→write loop
      if (!_orphanCleanupDone && orphansToClean.isNotEmpty) {
        _orphanCleanupDone = true;
        _runOrphanCleanup(orphansToClean);
      } else if (!_orphanCleanupDone) {
        _orphanCleanupDone = true;
      }

      // Auto-manage timer check based on active timers
      _updateTimerCheckState();

      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to areas: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Clean orphaned schedules/rules once (not inside real-time listener loop)
  void _runOrphanCleanup(List<_OrphanCleanup> orphans) {
    for (final orphan in orphans) {
      _firestore
          .collection('users')
          .doc(_uid)
          .collection('areas')
          .doc(orphan.docId)
          .update({
        'schedules': orphan.area.schedules.map((s) => s.toMap()).toList(),
        'rules': orphan.area.rules.map((r) => r.toMap()).toList(),
      }).catchError((e) {
        debugPrint('Error cleaning orphaned data for ${orphan.docId}: $e');
      });
    }
  }

  Future<void> addArea(String name) async {
    if (_uid == null) return;
    
    try {
      // Each area always has exactly 3 fixed hardware devices: Pump, Mist, and Fan
      final devices = [
        Device(id: 'pump_1', name: 'Máy bơm', type: 'pump'),
        Device(id: 'mist_1', name: 'Phun sương', type: 'mist'),
        Device(id: 'fan_1', name: 'Quạt thông gió', type: 'fan'),
      ];

      final newArea = Area(
        id: '', // Firestore will generate
        name: name,
        sensors: [
          Sensor(id: 'temp', type: 'temperature', value: 25.0, unit: '°C'),
          Sensor(id: 'humi', type: 'air_humidity', value: 60.0, unit: '%'),
          Sensor(id: 'soil', type: 'soil_moisture', value: 45.0, unit: '%'),
        ],
        devices: devices,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('areas')
          .add(newArea.toMap());

      // Log activity
      ActivityLogService.log(
        uid: _uid!,
        type: ActivityType.areaAdd,
        description: 'Thêm khu vườn "$name"',
        actorName: _authProvider?.displayName ?? '',
        actorPhone: _authProvider?.phoneNumber ?? '',
        areaId: docRef.id,
        areaName: name,
      );
    } catch (e) {
      debugPrint('Error adding area: $e');
    }
  }

  Future<void> deleteArea(String areaId) async {
    if (_uid == null) return;
    try {
      // Get area name before deleting for the log
      final area = getArea(areaId);
      final areaName = area?.name ?? areaId;

      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('areas')
          .doc(areaId)
          .delete();

      // Log activity
      ActivityLogService.log(
        uid: _uid!,
        type: ActivityType.areaDelete,
        description: 'Xóa khu vườn "$areaName"',
        actorName: _authProvider?.displayName ?? '',
        actorPhone: _authProvider?.phoneNumber ?? '',
        areaId: areaId,
        areaName: areaName,
      );
    } catch (e) {
      debugPrint('Error deleting area: $e');
    }
  }

  Area? getArea(String id) {
    try {
      return _areas.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get 24h sensor history for an area from Firestore.
  Stream<List<SensorReading>> getSensorHistoryStream(String areaId, String sensorType) {
    if (_uid == null) return const Stream.empty();
    
    final cutoff = DateTime.now().subtract(const Duration(hours: 25)).millisecondsSinceEpoch;
    
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('areas')
        .doc(areaId)
        .collection('history')
        .where('type', isEqualTo: sensorType)
        .where('timestamp', isGreaterThan: cutoff)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SensorReading.fromMap(doc.data()))
            .toList());
  }

  void toggleAreaMode(String areaId) async {
    if (_uid == null) return;
    final index = _areas.indexWhere((a) => a.id == areaId);
    if (index != -1) {
      // Block mode toggle during soil renovation
      if (_areas[index].isSoilRenovation) return;
      
      final newMode = !_areas[index].isAutoMode;
      
      // Optimistic UI Update
      _areas[index].isAutoMode = newMode;
      notifyListeners();
      
      try {
        await _firestore
            .collection('users')
            .doc(_uid)
            .collection('areas')
            .doc(areaId)
            .update({'isAutoMode': newMode});
      } catch (e) {
        debugPrint('Error toggling area mode: $e');
      }
    }
  }

  void toggleDevice(String areaId, String deviceId) async {
    if (_uid == null) return;
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex != -1) {
      final area = _areas[areaIndex];
      // Block device toggle during soil renovation or auto mode
      if (area.isAutoMode || area.isSoilRenovation) return;
      final deviceIndex = area.devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex != -1) {
        final device = area.devices[deviceIndex];
        device.isOn = !device.isOn;
        device.clearTimer();
        
        // Optimistic UI Update
        notifyListeners();
        
        try {
          // Log activity immediately for instant UI feedback
          ActivityLogService.log(
            uid: _uid!,
            type: ActivityType.deviceToggle,
            description: '${device.isOn ? "Bật" : "Tắt"} ${device.name} (${area.name})',
            actorName: _authProvider?.displayName ?? '',
            actorPhone: _authProvider?.phoneNumber ?? '',
            areaId: areaId,
            areaName: area.name,
          );

          await _firestore
              .collection('users')
              .doc(_uid)
              .collection('areas')
              .doc(areaId)
              .update({
            'devices': area.devices.map((d) => d.toMap()).toList()
          });
        } catch (e) {
          debugPrint('Error toggling device: $e');
        }
      }
    }
  }

  /// Set a timer on a device. When the timer expires, the device will toggle.
  void setDeviceTimer(String areaId, String deviceId, Duration duration) async {
    if (_uid == null) return;
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex != -1) {
      final area = _areas[areaIndex];
      // Block timer during soil renovation or auto mode
      if (area.isAutoMode || area.isSoilRenovation) return;
      final deviceIndex = area.devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex != -1) {
        area.devices[deviceIndex].setTimer(duration);
        
        // Start timer check loop since we now have an active timer
        _startTimerCheckIfNeeded();
        
        // Optimistic UI Update
        notifyListeners();
        
        try {
          await _firestore
              .collection('users')
              .doc(_uid)
              .collection('areas')
              .doc(areaId)
              .update({
            'devices': area.devices.map((d) => d.toMap()).toList()
          });
        } catch (e) {
          debugPrint('Error setting device timer: $e');
        }
      }
    }
  }

  void cancelDeviceTimer(String areaId, String deviceId) async {
    if (_uid == null) return;
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex != -1) {
      final area = _areas[areaIndex];
      final deviceIndex = area.devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex != -1) {
        area.devices[deviceIndex].clearTimer();
        
        // Check if we can stop the timer loop
        _updateTimerCheckState();
        
        // Optimistic UI Update
        notifyListeners();
        
        try {
          await _firestore
              .collection('users')
              .doc(_uid)
              .collection('areas')
              .doc(areaId)
              .update({
            'devices': area.devices.map((d) => d.toMap()).toList()
          });
        } catch (e) {
          debugPrint('Error cancelling device timer: $e');
        }
      }
    }
  }

  /// Start the timer check loop only when needed (a device has an active timer)
  void _startTimerCheckIfNeeded() {
    if (_timerCheckTimer != null) return; // Already running
    _hasActiveTimers = true;
    _timerCheckTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkTimers(),
    );
  }

  /// Stop the timer check loop when no devices have active timers
  void _stopTimerCheckIfIdle() {
    if (_timerCheckTimer == null) return;
    _hasActiveTimers = false;
    _timerCheckTimer?.cancel();
    _timerCheckTimer = null;
  }

  /// Check if any device has an active timer and start/stop accordingly
  void _updateTimerCheckState() {
    final hasAnyTimer = _areas.any((a) =>
        !a.isAutoMode && a.devices.any((d) => d.hasActiveTimer));
    if (hasAnyTimer && !_hasActiveTimers) {
      _startTimerCheckIfNeeded();
    } else if (!hasAnyTimer && _hasActiveTimers) {
      _stopTimerCheckIfIdle();
    }
  }

  /// Periodically check all device timers and toggle expired ones.
  void _checkTimers() {
    bool changed = false;
    bool hasAnyTimer = false;
    for (final area in _areas) {
      if (area.isAutoMode) continue;
      for (final device in area.devices) {
        if (device.hasActiveTimer) {
          hasAnyTimer = true;
          if (device.timerRemaining == Duration.zero) {
            device.isOn = !device.isOn;
            device.clearTimer();
            changed = true;
          }
        }
      }
    }

    // Stop the check loop if no timers remain
    if (!hasAnyTimer) {
      _stopTimerCheckIfIdle();
    }

    if (changed || hasAnyTimer) {
      notifyListeners();
    }
  }

  void _evaluateThresholds() {
    if (_uid == null) return;

    for (final area in _areas) {
      if (area.isSoilRenovation) continue;

      final tempSensor = area.getSensor('temperature');
      final soilSensor = area.getSensor('soil_moisture');

      // Check Temperature
      if (tempSensor != null && tempSensor.value > area.config.maxTemperature) {
        _sendAlertOnce(area, 'temp_high', 'Nhiệt độ quá cao: ${tempSensor.value.toStringAsFixed(1)}°C', AlertSeverity.high);
      }

      // Check Soil Moisture
      if (soilSensor != null && soilSensor.value < area.config.soilMoistureThreshold) {
        _sendAlertOnce(area, 'soil_dry', 'Độ ẩm đất thấp: ${soilSensor.value.toStringAsFixed(1)}%', AlertSeverity.medium);
      }
    }
  }

  void _sendAlertOnce(Area area, String key, String message, AlertSeverity severity) async {
    final areaAlerts = _sentAlerts.putIfAbsent(area.id, () => {});
    if (areaAlerts.contains(key)) return;

    areaAlerts.add(key);
    
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('alerts')
          .add({
        'areaName': area.name,
        'message': message,
        'time': DateTime.now().millisecondsSinceEpoch,
        'severity': severity.name,
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Error sending threshold alert: $e');
    }

    // Reset alert after 1 hour so it can trigger again if condition persists
    Timer(const Duration(hours: 1), () {
      _sentAlerts[area.id]?.remove(key);
    });
  }

  void _evaluateSchedules() {
    if (_uid == null) return;
    final now = DateTime.now();

    for (final area in _areas) {
      if (area.isSoilRenovation || area.isAutoMode) continue;

      for (final schedule in area.schedules) {
        if (!schedule.isEnabled) continue;
        if (!schedule.daysOfWeek.contains(now.weekday)) continue;

        if (schedule.hour == now.hour && schedule.minute == now.minute) {
          // Trigger the device
          final deviceIndex = area.devices.indexWhere((d) => d.id == schedule.deviceId);
          if (deviceIndex != -1) {
            final device = area.devices[deviceIndex];
            if (!device.isOn) {
              device.isOn = true;
              device.setTimer(Duration(minutes: schedule.durationMinutes));
              
              _syncAreaDevices(area.id);
              notifyListeners();
            }
          }
        }
      }
    }
  }

  void updateAreaName(String areaId, String newName) async {
    if (_uid == null) return;
    
    // Optimistic UI Update
    final index = _areas.indexWhere((a) => a.id == areaId);
    if (index != -1) {
      _areas[index].name = newName.trim();
      notifyListeners();
    }
    
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('areas')
          .doc(areaId)
          .update({'name': newName.trim()});
    } catch (e) {
      debugPrint('Error updating area name: $e');
    }
  }

  Future<void> updateAreaNotes(String areaId, String notes) async {
    if (_uid == null) return;
    final index = _areas.indexWhere((a) => a.id == areaId);
    if (index != -1) {
      _areas[index].notes = notes;
      notifyListeners();

      try {
        await _firestore
            .collection('users')
            .doc(_uid)
            .collection('areas')
            .doc(areaId)
            .update({'notes': notes});
      } catch (e) {
        debugPrint('Error updating area notes: $e');
      }
    }
  }

  Future<void> addWateringSchedule(String areaId, WateringSchedule schedule) async {
    if (_uid == null) return;
    final index = _areas.indexWhere((a) => a.id == areaId);
    if (index != -1) {
      final area = _areas[index];
      final newSchedules = List<WateringSchedule>.from(area.schedules)..add(schedule);
      
      try {
        await _firestore
            .collection('users')
            .doc(_uid)
            .collection('areas')
            .doc(areaId)
            .update({
          'schedules': newSchedules.map((s) => s.toMap()).toList()
        });
      } catch (e) {
        debugPrint('Error adding schedule: $e');
      }
    }
  }

  Future<void> deleteWateringSchedule(String areaId, String scheduleId) async {
    if (_uid == null) return;
    final index = _areas.indexWhere((a) => a.id == areaId);
    if (index != -1) {
      final area = _areas[index];
      final newSchedules = area.schedules.where((s) => s.id != scheduleId).toList();
      
      try {
        await _firestore
            .collection('users')
            .doc(_uid)
            .collection('areas')
            .doc(areaId)
            .update({
          'schedules': newSchedules.map((s) => s.toMap()).toList()
        });
      } catch (e) {
        debugPrint('Error deleting schedule: $e');
      }
    }
  }

  void updateAreaConfig(String areaId, AreaConfig newConfig) async {
    if (_uid == null) return;
    
    // Optimistic UI Update
    final index = _areas.indexWhere((a) => a.id == areaId);
    if (index != -1) {
      _areas[index].config = newConfig;
      notifyListeners();
    }
    
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('areas')
          .doc(areaId)
          .update({'config': newConfig.toMap()});
    } catch (e) {
      debugPrint('Error updating area config: $e');
    }
  }

  /// Toggle soil renovation mode for an area.
  void toggleSoilRenovation(String areaId) async {
    if (_uid == null) return;
    final index = _areas.indexWhere((a) => a.id == areaId);
    if (index != -1) {
      final area = _areas[index];
      final newRenovation = !area.isSoilRenovation;
      
      // Optimistic UI Update
      area.isSoilRenovation = newRenovation;
      if (newRenovation) {
        area.isAutoMode = false;
        for (final device in area.devices) {
          device.isOn = false;
          device.clearTimer();
        }
      }
      notifyListeners();
      
      try {
        final updateData = <String, dynamic>{
          'isSoilRenovation': newRenovation,
          'devices': area.devices.map((d) => d.toMap()).toList(),
        };
        if (newRenovation) {
          updateData['isAutoMode'] = false;
        }
        await _firestore
            .collection('users')
            .doc(_uid)
            .collection('areas')
            .doc(areaId)
            .update(updateData);
      } catch (e) {
        debugPrint('Error toggling soil renovation: $e');
      }
    }
  }

  Future<void> fetchWeather() async {
    final weather = await _weatherService.fetchCurrentWeather(language: _language);
    if (weather != null) {
      _currentWeather = weather;
      _forecast = await _weatherService.fetchForecast(language: _language);
      notifyListeners();
      _evaluateAutomations();
    }
  }

  Future<void> refreshData() async {
    await fetchWeather();
  }

  void _evaluateAutomations() {
    for (final area in _areas) {
      if (!area.isAutoMode) continue;
      
      for (final rule in area.rules) {
        if (!rule.isEnabled) continue;
        if (rule.conditions.isEmpty) continue;
        
        bool allTrue = true;
        bool anyTrue = false;

        for (final condition in rule.conditions) {
          bool conditionTriggered = false;

          if (condition.triggerType == RuleTriggerType.sensor) {
            final sensor = area.getSensor(condition.triggerKey);
            if (sensor != null) {
              if (condition.condition == RuleCondition.greaterThan) {
                conditionTriggered = sensor.value > condition.thresholdValue;
              } else if (condition.condition == RuleCondition.lessThan) {
                conditionTriggered = sensor.value < condition.thresholdValue;
              } else if (condition.condition == RuleCondition.equals) {
                conditionTriggered = sensor.value == condition.thresholdValue;
              }
            }
          } else if (condition.triggerType == RuleTriggerType.weather && _currentWeather != null) {
            if (condition.triggerKey == 'rain') {
              conditionTriggered = _currentWeather!.condition.toLowerCase().contains('rain');
            } else if (condition.triggerKey == 'temp') {
              if (condition.condition == RuleCondition.greaterThan) {
                conditionTriggered = _currentWeather!.temp > condition.thresholdValue;
              } else if (condition.condition == RuleCondition.lessThan) {
                conditionTriggered = _currentWeather!.temp < condition.thresholdValue;
              } else if (condition.condition == RuleCondition.equals) {
                conditionTriggered = _currentWeather!.temp == condition.thresholdValue;
              }
            }
          }

          if (!conditionTriggered) allTrue = false;
          if (conditionTriggered) anyTrue = true;
        }

        bool shouldTrigger = false;
        if (rule.logicalOperator == LogicalOperator.and) {
          shouldTrigger = allTrue;
        } else {
          shouldTrigger = anyTrue;
        }

        if (shouldTrigger && rule.actions.isNotEmpty) {
          bool devicesChanged = false;
          for (final action in rule.actions) {
            final deviceIndex = area.devices.indexWhere((d) => d.id == action.deviceId);
            if (deviceIndex != -1) {
              final device = area.devices[deviceIndex];
              if (device.isOn != action.actionOn) {
                device.isOn = action.actionOn;
                devicesChanged = true;
              }
            }
          }
          if (devicesChanged) {
             _syncAreaDevices(area.id);
          }
        }
      }
    }
  }

  Future<void> addRule(String areaId, AutomationRule rule) async {
    if (_uid == null) return;
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex != -1) {
      final area = _areas[areaIndex];
      area.rules.add(rule);
      // Optimistic UI Update
      notifyListeners();
      await _syncAreaRules(areaId);
    }
  }

  Future<void> updateRule(String areaId, AutomationRule updatedRule) async {
    if (_uid == null) return;
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex != -1) {
      final area = _areas[areaIndex];
      final ruleIndex = area.rules.indexWhere((r) => r.id == updatedRule.id);
      if (ruleIndex != -1) {
        area.rules[ruleIndex] = updatedRule;
        // Optimistic UI Update
        notifyListeners();
        await _syncAreaRules(areaId);
      }
    }
  }

  Future<void> deleteRule(String areaId, String ruleId) async {
    if (_uid == null) return;
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex != -1) {
      final area = _areas[areaIndex];
      area.rules.removeWhere((r) => r.id == ruleId);
      // Optimistic UI Update
      notifyListeners();
      await _syncAreaRules(areaId);
    }
  }

  Future<void> _syncAreaRules(String areaId) async {
    if (_uid == null) return;
    final area = getArea(areaId);
    if (area == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('areas')
          .doc(areaId)
          .update({
        'rules': area.rules.map((r) => r.toMap()).toList()
      });
    } catch (e) {
      debugPrint('Error syncing rules: $e');
    }
  }

  Future<void> _syncAreaDevices(String areaId) async {
    if (_uid == null) return;
    final area = getArea(areaId);
    if (area == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('areas')
          .doc(areaId)
          .update({
        'devices': area.devices.map((d) => d.toMap()).toList()
      });
    } catch (e) {
      debugPrint('Error syncing devices for automation: $e');
    }
  }
}

/// Helper class for one-time orphan cleanup
class _OrphanCleanup {
  final String docId;
  final Area area;
  _OrphanCleanup(this.docId, this.area);
}
