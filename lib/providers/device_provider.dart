import 'package:flutter/material.dart';
import '../models/logged_device.dart';
import '../data/mock_data.dart';

class DeviceProvider extends ChangeNotifier {
  List<LoggedDevice> _devices = [];
  bool _isLoading = true;

  List<LoggedDevice> get devices => _devices;
  bool get isLoading => _isLoading;
  int get deviceCount => _devices.length;

  DeviceProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    // Removed artificial delay

    _devices = MockData.getLoggedDevices();
    _isLoading = false;
    notifyListeners();
  }

  void renameDevice(String deviceId, String newName) {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      _devices[index].name = newName;
      notifyListeners();
    }
  }

  void logoutDevice(String deviceId) {
    _devices.removeWhere((d) => d.id == deviceId);
    notifyListeners();
  }
}
