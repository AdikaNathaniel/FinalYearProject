import 'package:flutter/material.dart';
// import 'auth/login_page.dart';
// import 'auth/register_page.dart';
// import 'home/home_page.dart';
// import 'home/admin_page.dart';

import 'package:patient_monitor/app/home/home_page.dart';
import 'package:patient_monitor/app/home/admin_page.dart';
import 'package:patient_monitor/app/auth/login_page.dart';
import 'package:patient_monitor/app/auth/register_page.dart';



class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String home = '/home';
  static const String admin = '/admin';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginPage(),
        register: (context) => const RegisterPage(),
        home: (context) => const HomePage(),
        admin: (context) => const AdminPage(),
      };
}