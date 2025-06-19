import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'auth/auth_state.dart';
// import 'app_routes.dart';
import 'package:patient_monitor/app/auth/auth_state.dart';
import 'package:patient_monitor/app/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthState>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthState>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome ${user?.username ?? 'User'}'),
            Text('Role: ${user?.role ?? 'Unknown'}'),
            if (user?.role == 'admin')
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.admin),
                child: const Text('Admin Dashboard'),
              ),
          ],
        ),
      ),
    );
  }
}