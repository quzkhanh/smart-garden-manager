import 'package:flutter/material.dart';

enum AuthState { unauthenticated, otpSent, verifying, qrWaiting, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.unauthenticated;
  String _phoneNumber = '';
  String _otp = '';
  bool _isLoading = false;

  AuthState get state => _state;
  String get phoneNumber => _phoneNumber;
  String get otp => _otp;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _state == AuthState.authenticated;

  void setPhoneNumber(String phone) {
    _phoneNumber = phone;
    notifyListeners();
  }

  Future<void> sendOtp(String phone) async {
    _isLoading = true;
    _phoneNumber = phone;
    notifyListeners();

    // Removed artificial delay

    _state = AuthState.otpSent;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> verifyOtp(String otp) async {
    _otp = otp;
    _state = AuthState.verifying;
    _isLoading = true;
    notifyListeners();

    // Removed artificial delay    // Accept any OTP
    _state = AuthState.authenticated;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> startQrLogin() async {
    _state = AuthState.qrWaiting;
    _isLoading = false;
    notifyListeners();

    // Auto-login after 4 seconds
    await Future.delayed(const Duration(seconds: 4));

    if (_state == AuthState.qrWaiting) {
      _state = AuthState.authenticated;
      notifyListeners();
    }
  }

  void cancelQrLogin() {
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  void goBackToPhone() {
    _state = AuthState.unauthenticated;
    _otp = '';
    _isLoading = false;
    notifyListeners();
  }

  void logout() {
    _state = AuthState.unauthenticated;
    _phoneNumber = '';
    _otp = '';
    _isLoading = false;
    notifyListeners();
  }
}
