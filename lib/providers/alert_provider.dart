import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../data/mock_data.dart';

enum AlertFilter { all, unread, read }

class AlertProvider extends ChangeNotifier {
  List<Alert> _alerts = [];
  AlertFilter _filter = AlertFilter.all;
  bool _isLoading = true;

  List<Alert> get alerts => _filteredAlerts;
  List<Alert> get allAlerts => _alerts;
  AlertFilter get filter => _filter;
  bool get isLoading => _isLoading;
  int get unreadCount => _alerts.where((a) => !a.isRead).length;
  int get readCount => _alerts.where((a) => a.isRead).length;

  List<Alert> get _filteredAlerts {
    switch (_filter) {
      case AlertFilter.unread:
        return _alerts.where((a) => !a.isRead).toList();
      case AlertFilter.read:
        return _alerts.where((a) => a.isRead).toList();
      case AlertFilter.all:
        return _alerts;
    }
  }

  AlertProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    // Removed artificial delay

    _alerts = MockData.getAlerts();
    _isLoading = false;
    notifyListeners();
  }

  void setFilter(AlertFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void markAsRead(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var alert in _alerts) {
      alert.isRead = true;
    }
    notifyListeners();
  }

  /// Delete a single alert by id.
  void deleteAlert(String alertId) {
    _alerts.removeWhere((a) => a.id == alertId);
    notifyListeners();
  }

  /// Delete all alerts that have been read.
  void deleteReadAlerts() {
    _alerts.removeWhere((a) => a.isRead);
    notifyListeners();
  }
}
