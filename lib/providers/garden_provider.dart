import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/area.dart';
import '../models/area_config.dart';
import '../models/sensor_reading.dart';
import '../models/sensor.dart';
import '../models/device.dart';
import 'auth_provider.dart';

class GardenProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Area> _areas = [];
  bool _isLoading = true;
  String? _uid;
  StreamSubscription? _areasSubscription;
  Timer? _timerCheckTimer;

  List<Area> get areas => _areas;
  bool get isLoading => _isLoading;

  int get totalAreas => _areas.length;
  int get totalActiveDevices =>
      _areas.fold<int>(0, (sum, area) => sum + area.activeDeviceCount);

  GardenProvider() {
    // Check timers every second
    _timerCheckTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkTimers(),
    );
  }

  @override
  void dispose() {
    _timerCheckTimer?.cancel();
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
          
          // Fallback: If area has no devices (old data), add some defaults
          if (area.devices.isEmpty) {
            area.devices.addAll([
              Device(id: 'pump_1', name: 'Máy bơm 1', type: 'pump'),
              Device(id: 'fan_1', name: 'Quạt thông gió', type: 'fan'),
            ]);
            // Optionally update Firestore here, but for now just show in UI
          }
          
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
}
