import 'dart:async';
import 'package:flutter/material.dart';
import '../models/area.dart';
import '../models/area_config.dart';
import '../models/sensor_reading.dart';
import '../data/mock_data.dart';

class GardenProvider extends ChangeNotifier {
  List<Area> _areas = [];
  bool _isLoading = true;
  Timer? _timerCheckTimer;

  // Cache sensor history per area to avoid regenerating
  // In production, this would be fetched from Firebase
  final Map<String, SensorHistory> _sensorHistoryCache = {};

  List<Area> get areas => _areas;
  bool get isLoading => _isLoading;

  int get totalAreas => _areas.length;
  int get totalActiveDevices =>
      _areas.fold<int>(0, (sum, area) => sum + area.activeDeviceCount);

  GardenProvider() {
    loadData();
    // Check timers every second
    _timerCheckTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkTimers(),
    );
  }

  @override
  void dispose() {
    _timerCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    // Removed artificial delay

    _areas = MockData.getAreas();
    _isLoading = false;
    notifyListeners();
  }

  Area? getArea(String id) {
    try {
      return _areas.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get 24h sensor history for an area.
  /// In production, replace with Firebase Firestore query:
  /// ```dart
  /// final snapshot = await FirebaseFirestore.instance
  ///   .collection('areas/$areaId/sensor_history')
  ///   .where('timestamp', isGreaterThan: cutoff.millisecondsSinceEpoch)
  ///   .orderBy('timestamp')
  ///   .get();
  /// ```
  SensorHistory getSensorHistory(String areaId) {
    if (!_sensorHistoryCache.containsKey(areaId)) {
      _sensorHistoryCache[areaId] = MockData.getSensorHistory(areaId);
    }
    return _sensorHistoryCache[areaId]!;
  }

  void toggleAreaMode(String areaId) {
    final index = _areas.indexWhere((a) => a.id == areaId);
    if (index != -1) {
      _areas[index].isAutoMode = !_areas[index].isAutoMode;
      // Clear all timers when switching to auto mode
      if (_areas[index].isAutoMode) {
        for (final device in _areas[index].devices) {
          device.clearTimer();
        }
      }
      notifyListeners();
    }
  }

  void toggleDevice(String areaId, String deviceId) {
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex != -1) {
      final area = _areas[areaIndex];
      // Only allow toggle in manual mode
      if (!area.isAutoMode) {
        final deviceIndex = area.devices.indexWhere((d) => d.id == deviceId);
        if (deviceIndex != -1) {
          area.devices[deviceIndex].isOn = !area.devices[deviceIndex].isOn;
          // Clear timer when manually toggling
          area.devices[deviceIndex].clearTimer();
          notifyListeners();
        }
      }
    }
  }

  /// Set a timer on a device. When the timer expires, the device will toggle.
  /// In production, this would write to Firebase and use Cloud Functions
  /// for server-side timer execution.
  void setDeviceTimer(String areaId, String deviceId, Duration duration) {
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex != -1) {
      final area = _areas[areaIndex];
      if (!area.isAutoMode) {
        final deviceIndex = area.devices.indexWhere((d) => d.id == deviceId);
        if (deviceIndex != -1) {
          area.devices[deviceIndex].setTimer(duration);
          notifyListeners();
        }
      }
    }
  }

  /// Cancel an active timer on a device.
  void cancelDeviceTimer(String areaId, String deviceId) {
    final areaIndex = _areas.indexWhere((a) => a.id == areaId);
    if (areaIndex != -1) {
      final deviceIndex =
          _areas[areaIndex].devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex != -1) {
        _areas[areaIndex].devices[deviceIndex].clearTimer();
        notifyListeners();
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

  /// Update the display name of a garden area.
  /// In production, write to Firebase:
  ///   DatabaseReference.child('zones/${areaId}/name').set(newName)
  void updateAreaName(String areaId, String newName) {
    final index = _areas.indexWhere((a) => a.id == areaId);
    if (index != -1) {
      _areas[index].name = newName.trim();
      notifyListeners();
    }
  }

  /// Update the automation config of a garden area.
  /// In production, write to Firebase:
  ///   DatabaseReference.child('zones/${areaId}/configs').update(config.toMap())
  void updateAreaConfig(String areaId, AreaConfig newConfig) {
    final index = _areas.indexWhere((a) => a.id == areaId);
    if (index != -1) {
      _areas[index].config = newConfig;
      notifyListeners();
    }
  }
}
