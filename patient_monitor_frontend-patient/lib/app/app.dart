import 'package:flutter/material.dart';
// import 'package:face_auth_flutter/app/app_routes.dart';
// import 'package:face_auth_flutter/app/auth/auth_state.dart';
// import 'app_routes.dart';
// import 'auth/auth_state.dart';

import 'package:patient_monitor/app/app_routes.dart';
import 'package:patient_monitor/app/auth/auth_state.dart';

import 'package:provider/provider.dart';

class FaceAuthApp extends StatelessWidget {
  const FaceAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthState(),
      child: MaterialApp(
        title: 'Face Authentication',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: AppRoutes.login,
        routes: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}