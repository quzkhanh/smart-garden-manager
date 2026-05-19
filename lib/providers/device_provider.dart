import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/logged_device.dart';
import '../utils/device_info_util.dart';

class DeviceProvider extends ChangeNotifier {
  List<LoggedDevice> _devices = [];
  bool _isLoading = true;
  String? _uid;
  String? _currentDeviceId;
  StreamSubscription<QuerySnapshot>? _subscription;
  bool _disposed = false;
  Timer? _refreshTimer;
  
  // Link to AuthProvider to trigger logout if kicked out
  dynamic _authProvider;

  List<LoggedDevice> get devices => _devices;
  bool get isLoading => _isLoading;
  int get deviceCount => _devices.length;

  DeviceProvider() {
    _initCurrentDevice();
  }

  Future<void> _initCurrentDevice() async {
    final data = await DeviceInfoUtil.getDeviceData();
    _currentDeviceId = data.id;
    if (_uid != null) {
      _listenToDevices();
      _startRefreshTimer();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Recalculate online status (based on lastActive timestamp)
      // Only notify if any device's computed online status actually changed
      bool anyChanged = false;
      for (final device in _devices) {
        final wasOnline = device.isOnline;
        final nowOnline = device.isCurrentDevice
            ? true
            : DateTime.now().difference(device.lastActive).inMinutes < 3;
        if (wasOnline != nowOnline) {
          anyChanged = true;
          break;
        }
      }
      if (anyChanged) {
        notifyListeners();
      }
    });
  }

  void updateAuth(dynamic auth) {
    _authProvider = auth;
    final newUid = auth.uid;
    if (_uid == newUid) return;
    _uid = newUid;
    if (_uid == null) {
      _devices = [];
      _subscription?.cancel();
      _isLoading = false;
      notifyListeners();
    } else {
      if (_currentDeviceId != null) {
        _listenToDevices();
      }
    }
  }

  void _listenToDevices() {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('logged_devices')
        .orderBy('lastActive', descending: true)
        .snapshots()
        .listen((snapshot) {
      bool amIStillHere = false;
      
      _devices = snapshot.docs.map((doc) {
        if (doc.id == _currentDeviceId) {
          amIStillHere = true;
        }
        
        final data = doc.data();
        DateTime lastActive = DateTime.now();
        final dynamic rawLastActive = data['lastActive'];
        if (rawLastActive != null && rawLastActive is Timestamp) {
          lastActive = rawLastActive.toDate();
        }
        return LoggedDevice(
          id: doc.id,
          name: data['name'] ?? 'Unknown Device',
          platform: data['platform'] ?? 'unknown',
          lastActive: lastActive,
          isOnline: (data['isOnline'] ?? false) && 
                   DateTime.now().difference(lastActive).inMinutes < 3, // 3 min buffer
          isCurrentDevice: doc.id == _currentDeviceId,
        );
      }).toList();
      
      _isLoading = false;
      notifyListeners();

      // Remote kick out detection
      // If we got the documents, and our device isn't in it, we were kicked.
      if (snapshot.docs.isNotEmpty && !amIStillHere && _currentDeviceId != null) {
        _subscription?.cancel();
        if (_authProvider != null) {
          _authProvider.forceLogout('Phiên đăng nhập đã hết hạn hoặc bị đăng xuất từ thiết bị khác.');
        }
      }
    }, onError: (e) {
      debugPrint('Error listening to logged devices: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> refreshDevices() async {
    if (_uid != null && _currentDeviceId != null) {
      _listenToDevices();
      // Add a slight delay just for visual feedback on pull-to-refresh
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void renameDevice(String deviceId, String newName) {
    if (_uid == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('logged_devices')
        .doc(deviceId)
        .update({'name': newName}).catchError((e) {
      debugPrint('Failed to rename device: $e');
    });
  }

  void logoutDevice(String deviceId) {
    if (_uid == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('logged_devices')
        .doc(deviceId)
        .delete().catchError((e) {
      debugPrint('Failed to logout device: $e');
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
