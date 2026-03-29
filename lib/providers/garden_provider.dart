import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/area.dart';
import '../models/area_config.dart';
import '../models/sensor_reading.dart';
import '../models/sensor.dart';
import '../models/device.dart';
import '../models/automation_rule.dart';
import '../services/weather_service.dart';
import 'auth_provider.dart';

class GardenProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Area> _areas = [];
  bool _isLoading = true;
  String? _uid;
  StreamSubscription? _areasSubscription;
  Timer? _timerCheckTimer;
  Timer? _weatherTimer;
  String _language = 'vi';
  final WeatherService _weatherService = WeatherService();
  WeatherData? _currentWeather;
  List<WeatherData> _forecast = [];

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
    // Check timers every second
    _timerCheckTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkTimers(),
    );
    
    // Check weather every 15 minutes
    _weatherTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => fetchWeather(),
    );
    fetchWeather(); // Initial fetch
  }

  @override
  void dispose() {
    _timerCheckTimer?.cancel();
    _weatherTimer?.cancel();
    _areasSubscription?.cancel();
    super.dispose();
  }

  void updateAuth(AuthProvider auth) {
    final newUid = auth.uid;
    if (_uid == newUid) return;
    
    _uid = newUid;
    _areasSubscription?.cancel();
    
    if (_uid == null) {
      _areas = [];
      _isLoading = false;
      notifyListeners();
    } else {
      _listenToAreas();
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
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final area = Area.fromMap(doc.id, data);
          updatedAreas.add(area);
        } catch (e) {
          debugPrint('Error parsing area ${doc.id}: $e');
        }
      }
      _areas = updatedAreas;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to areas: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addArea(String name, {List<String>? initialDeviceTypes}) async {
    if (_uid == null) return;
    
    try {
      final List<Device> devices = [];
      if (initialDeviceTypes != null) {
        for (final type in initialDeviceTypes) {
           String devName = '';
           switch(type) {
             case 'pump': devName = 'Máy bơm'; break;
             case 'fan': devName = 'Quạt thông gió'; break;
             case 'light': devName = 'Đèn chiếu sáng'; break;
             case 'mist': devName = 'Phun sương'; break;
             case 'valve': devName = 'Van nước'; break;
             default: devName = 'Thiết bị mới';
           }
           devices.add(Device(
             id: '${type}_${DateTime.now().millisecondsSinceEpoch}',
             name: devName,
             type: type,
           ));
        }
      } else {
        // Default devices if none specified
        devices.addAll([
          Device(id: 'pump_1', name: 'Máy bơm 1', type: 'pump'),
          Device(id: 'fan_1', name: 'Quạt thông gió', type: 'fan'),
        ]);
      }

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

      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('areas')
          .add(newArea.toMap());
    } catch (e) {
      debugPrint('Error adding area: $e');
    }
  }

  Future<void> deleteArea(String areaId) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('areas')
          .doc(areaId)
          .delete();
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
      if (!area.isAutoMode) {
        final deviceIndex = area.devices.indexWhere((d) => d.id == deviceId);
        if (deviceIndex != -1) {
          final device = area.devices[deviceIndex];
          device.isOn = !device.isOn;
          device.clearTimer();
          
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
            debugPrint('Error toggling device: $e');
          }
        }
      }
    }
  }

  /// Set a timer on a device. When the timer expires, the device will toggle.
  /// In production, this would write to Firebase and use Cloud Functions
  /// for server-side timer execution.
  void setDeviceTimer(String areaId, String deviceId, Duration duration) async {
    if (_uid == null) return;
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex != -1) {
      final area = _areas[areaIndex];
      if (!area.isAutoMode) {
        final deviceIndex = area.devices.indexWhere((d) => d.id == deviceId);
        if (deviceIndex != -1) {
          area.devices[deviceIndex].setTimer(duration);
          
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
  }

  void cancelDeviceTimer(String areaId, String deviceId) async {
    if (_uid == null) return;
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex != -1) {
      final area = _areas[areaIndex];
      final deviceIndex = area.devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex != -1) {
        area.devices[deviceIndex].clearTimer();
        
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

  /// Periodically check all device timers and toggle expired ones.
  void _checkTimers() {
    bool changed = false;
    for (final area in _areas) {
      if (area.isAutoMode) continue;
      for (final device in area.devices) {
        if (device.hasActiveTimer && device.timerRemaining == Duration.zero) {
          device.isOn = !device.isOn;
          device.clearTimer();
          changed = true;
        }
      }
    }
    // Also notify every second if any device has an active timer (to update countdown)
    final hasAnyTimer = _areas.any((a) =>
        !a.isAutoMode && a.devices.any((d) => d.hasActiveTimer));
    if (changed || hasAnyTimer) {
      notifyListeners();
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

  void addDevice(String areaId, String name, String type) async {
    if (_uid == null) return;
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex != -1) {
      final area = _areas[areaIndex];
      final newDevice = Device(
        id: 'dev_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: type,
      );
      area.devices.add(newDevice);
      
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
        debugPrint('Error adding device: $e');
      }
    }
  }

  void deleteDevice(String areaId, String deviceId) async {
    if (_uid == null) return;
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex != -1) {
      final area = _areas[areaIndex];
      area.devices.removeWhere((d) => d.id == deviceId);
      
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
        debugPrint('Error deleting device: $e');
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
    // Weather is the only non-realtime data here that needs manual refresh
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
