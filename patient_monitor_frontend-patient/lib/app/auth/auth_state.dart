import 'package:flutter/material.dart';
// import 'models/user_model.dart';
import 'package:patient_monitor/app/models/user_model.dart';

class AuthState with ChangeNotifier {
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  void login(User user, String token) {
    _currentUser = user;
    _token = token;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _token = null;
    notifyListeners();
  }
}