import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert.dart';
import 'auth_provider.dart';

enum AlertFilter { all, unread, read }

class AlertProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Alert> _alerts = [];
  AlertFilter _filter = AlertFilter.all;
  bool _isLoading = true;
  String? _uid;
  StreamSubscription? _subscription;
  bool _disposed = false;

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

  AlertProvider();

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void updateAuth(AuthProvider auth) {
    final newUid = auth.uid;
    if (_uid == newUid) return;
    
    _uid = newUid;
    _subscription?.cancel();
    
    if (_uid == null) {
      _alerts = [];
      _isLoading = false;
      notifyListeners();
    } else {
      _listenToAlerts();
    }
  }

  void _listenToAlerts() {
    _isLoading = true;
    notifyListeners();

    _subscription = _firestore
        .collection('users')
        .doc(_uid)
        .collection('alerts')
        .orderBy('time', descending: true)
        .snapshots()
        .listen((snapshot) {
      _alerts = snapshot.docs.map((doc) => Alert.fromMap(doc.id, doc.data())).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to alerts: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  void setFilter(AlertFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void markAsRead(String alertId) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('alerts')
          .doc(alertId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking alert as read: $e');
    }
  }

  void markAllAsRead() async {
    if (_uid == null) return;
    final batch = _firestore.batch();
    for (var alert in _alerts.where((a) => !a.isRead)) {
      final ref = _firestore
          .collection('users')
          .doc(_uid)
          .collection('alerts')
          .doc(alert.id);
      batch.update(ref, {'isRead': true});
    }
    
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all alerts as read: $e');
    }
  }

  /// Delete a single alert by id.
  void deleteAlert(String alertId) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('alerts')
          .doc(alertId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting alert: $e');
    }
  }

  /// Delete all alerts that have been read.
  void deleteReadAlerts() async {
    if (_uid == null) return;
    final batch = _firestore.batch();
    for (var alert in _alerts.where((a) => a.isRead)) {
      final ref = _firestore
          .collection('users')
          .doc(_uid)
          .collection('alerts')
          .doc(alert.id);
      batch.delete(ref);
    }
    
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting read alerts: $e');
    }
  }

  Future<void> refreshAlerts() async {
    // Alerts are real-time, but manual refresh can provide user feedback
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }
}
