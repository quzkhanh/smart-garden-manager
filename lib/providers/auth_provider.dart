import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';
import 'package:crypto/crypto.dart' show sha256;
import 'dart:convert' show utf8;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/device_info_util.dart';

enum AuthState { unauthenticated, otpSent, verifying, qrWaiting, authenticated }

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthState _state = AuthState.unauthenticated;
  String _phoneNumber = '';
  String _otp = '';
  String _verificationId = '';
  String _qrSessionId = '';
  StreamSubscription<DocumentSnapshot>? _qrSubscription;
  bool _isLoading = false;
  bool _isLoggingOut = false;
  String _lastError = '';
  String? _masterUid;
  bool _isFirstTime = true;
  Timer? _heartbeatTimer;
  bool _disposed = false;

  AuthState get state => _state;
  String get phoneNumber {
    if (_phoneNumber.isNotEmpty) return _phoneNumber;
    // Fallback to Firebase Auth user's phone number (persisted across restarts)
    return _auth.currentUser?.phoneNumber ?? '';
  }
  String get otp => _otp;
  String get qrSessionId => _qrSessionId;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _state == AuthState.authenticated;
  String get lastError => _lastError;
  String? get uid => _masterUid ?? _auth.currentUser?.uid;
  bool get isFirstTime => _isFirstTime;

  /// Normalize local phone number to E.164 format
  /// e.g. 0912345678 → +84912345678
  String _normalizePhone(String phone) {
    phone = phone.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (phone.startsWith('+')) return phone; // already international
    if (phone.startsWith('0')) {
      return '+84${phone.substring(1)}';
    }
    return '+84$phone';
  }

  AuthProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initAuth();
  }

  Future<void> _initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _masterUid = prefs.getString('master_uid');
    _isFirstTime = prefs.getBool('is_first_time') ?? true;
    notifyListeners();

    // Check if user is already logged in
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _state = AuthState.authenticated;
        if (uid != null) {
          _saveDeviceLoginInfo(uid!);
        }
        // If logged in, they've clearly passed the "first time" phase or don't need splash
        if (_isFirstTime) {
          completeOnboarding();
        }
        _startHeartbeat();
        notifyListeners();
      } else {
        _stopHeartbeat();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (isAuthenticated) {
        _updateOnlineStatus(true);
      } else {
        _stopHeartbeat();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Track app lifecycle to update online status
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (uid == null) return;
    
    switch (state) {
      case AppLifecycleState.resumed:
        _updateOnlineStatus(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _updateOnlineStatus(false);
        break;
      default:
        break;
    }
  }

  /// Update online/offline status in Firestore for the current device
  Future<void> _updateOnlineStatus(bool isOnline) async {
    if (uid == null) return;
    try {
      final deviceData = await DeviceInfoUtil.getDeviceData();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('logged_devices')
          .doc(deviceData.id)
          .update({
        'isOnline': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to update online status: $e');
    }
  }

  void setPhoneNumber(String phone) {
    _phoneNumber = phone;
    notifyListeners();
  }

  Future<void> sendOtp(String phone) async {
    _isLoading = true;
    _lastError = '';
    final normalizedPhone = _normalizePhone(phone);
    _phoneNumber = normalizedPhone;
    notifyListeners();

    try {
      final regex = RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$|^(\+84[3|5|7|8|9])+([0-9]{8})$');
      if (!regex.hasMatch(phone)) {
        throw FirebaseAuthException(
          code: 'invalid-format',
          message: 'Số điện thoại không hợp lệ. Vui lòng nhập đúng định dạng mạng VN (ví dụ: 098...).',
        );
      }

      final completer = Completer<void>();
      
      // Check if phone exists in allowed_phones
      try {
        final doc = await FirebaseFirestore.instance
            .collection('allowed_phones')
            .doc(normalizedPhone)
            .get()
            .timeout(const Duration(seconds: 5), onTimeout: () {
              throw TimeoutException('Request to Firebase timed out');
            });
        if (!doc.exists) {
          throw FirebaseAuthException(
            code: 'not-registered', 
            message: 'Số điện thoại của bạn chưa được Admin cấp phép truy cập vào Vườn. Vui lòng liên hệ quản trị viên!',
          );
        }
      } catch (e) {
        if (e is FirebaseAuthException) rethrow;
        // If getting document fails due to offline/permission or timeout, let it pass gracefully
        debugPrint('Failed or timed out checking registered phone: $e');
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution on Android
          await _auth.signInWithCredential(credential);
          _state = AuthState.authenticated;
          _isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete();
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          _lastError = e.message ?? 'Lỗi xác thực số điện thoại. Vui lòng kiểm tra lại.';
          _state = AuthState.unauthenticated;
          notifyListeners();
          debugPrint('Phone Auth Failed: ${e.message}');
          if (!completer.isCompleted) completer.complete();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _state = AuthState.otpSent;
          _isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
      
      await completer.future;
    } catch (e) {
      _isLoading = false;
      if (e is FirebaseAuthException && (e.code == 'invalid-format' || e.code == 'not-registered')) {
        _lastError = e.message ?? 'Đã có lỗi xảy ra.';
      } else {
        _lastError = 'Đã có lỗi xảy ra từ Firebase: ${e.toString()}';
      }
      _state = AuthState.unauthenticated;
      notifyListeners();
      debugPrint('Phone Auth Error: $e');
    }
  }

  Future<bool> verifyOtp(String otp) async {
    _otp = otp;
    _state = AuthState.verifying;
    _isLoading = true;
    notifyListeners();

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      
      await _auth.signInWithCredential(credential);
      final user = _auth.currentUser;
      if (user != null) {
        await _saveDeviceLoginInfo(user.uid);
      }
      _state = AuthState.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _state = AuthState.otpSent; 
      notifyListeners();
      debugPrint('OTP Verification Failed: $e');
      return false;
    }
  }

  // Email/password login removed — app uses phone OTP + QR only

  Future<void> startQrLogin() async {
    _state = AuthState.qrWaiting;
    _isLoading = false;
    // Generate a unique session ID using timestamp + random
    final raw = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';
    final hash = sha256.convert(utf8.encode(raw)).toString().substring(0, 16);
    _qrSessionId = 'sg-$hash';
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('qr_sessions').doc(_qrSessionId).set({
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresInSeconds': 120,
      });

      _qrSubscription?.cancel();
      _qrSubscription = FirebaseFirestore.instance
          .collection('qr_sessions')
          .doc(_qrSessionId)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists && snapshot.data()?['status'] == 'approved') {
          _qrSubscription?.cancel();
          // Sign in anonymously to get a real Firebase Auth session
          try {
            await _auth.signInAnonymously();
            final user = _auth.currentUser;
            
            final docData = snapshot.data();
            final approvedBy = docData?['approvedBy'] as String?;
            
            if (approvedBy != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('master_uid', approvedBy);
              _masterUid = approvedBy;
            }
            
            if (user != null && uid != null) {
              await _saveDeviceLoginInfo(uid!);
              // Clean up the session document
              FirebaseFirestore.instance.collection('qr_sessions').doc(_qrSessionId).delete().catchError((_) {});
              _state = AuthState.authenticated;
              notifyListeners();
            }
          } catch (e) {
            debugPrint('Anonymous sign-in after QR failed: $e');
            _lastError = 'Cần bật tính năng Anonymous Auth trên Firebase!';
            _state = AuthState.unauthenticated;
            notifyListeners();
          }
        }
      });
    } catch (e) {
      debugPrint('Firestore Error generating QR Session: $e');
    }
  }

  void cancelQrLogin() {
    _qrSubscription?.cancel();
    if (_qrSessionId.isNotEmpty) {
      FirebaseFirestore.instance.collection('qr_sessions').doc(_qrSessionId).delete().catchError((_) {});
    }
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  void goBackToPhone() {
    _state = AuthState.unauthenticated;
    _otp = '';
    _qrSubscription?.cancel();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveDeviceLoginInfo(String uid) async {
    try {
      final deviceData = await DeviceInfoUtil.getDeviceData();

      // Record device login in Firestore under the specific User ID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('logged_devices')
          .doc(deviceData.id)
          .set({
        'name': deviceData.name,
        'platform': deviceData.platform,
        'isOnline': true,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also ensure the user doc exists
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save device login info: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopHeartbeat();
    WidgetsBinding.instance.removeObserver(this);
    _qrSubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  Future<void> forceLogout(String reason) async {
    if (_isLoggingOut) return;
    _lastError = reason;
    await logout();
  }

  Future<void> logout() async {
    _isLoggingOut = true;
    _lastError = ''; // Clear explicit manual logout error state
    
    try {
      final user = _auth.currentUser;
      if (user != null && uid != null) {
        // Set offline before removing the device doc
        await _updateOnlineStatus(false);
        final deviceData = await DeviceInfoUtil.getDeviceData();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid) // Use uid since it accounts for _masterUid
            .collection('logged_devices')
            .doc(deviceData.id)
            .delete().catchError((_) {});
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('master_uid');
      _masterUid = null;
      
      await _auth.signOut();
      _state = AuthState.unauthenticated;
      _phoneNumber = '';
      _otp = '';
      _verificationId = '';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout Error: $e');
    } finally {
      _isLoggingOut = false;
    }
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    _isFirstTime = false;
    notifyListeners();
  }
}
