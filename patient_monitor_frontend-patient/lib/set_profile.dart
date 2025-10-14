import 'package:flutter/material.dart';
import 'create-pin.dart'; 
import 'update-pin.dart';
import 'delete-pin.dart';
import 'update-password.dart';
import 'dart:convert';

class SetProfilePage extends StatelessWidget {
  final String userEmail;
  
  const SetProfilePage({super.key, required this.userEmail});

  void _onOptionSelected(BuildContext context, String option) {
    // You can navigate or trigger modals here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$option tapped')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardCard(
              context,
              title: 'Update PIN',
              icon: Icons.edit,
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PinUpdateScreen()),
                );
              },
            ),
            
            const SizedBox(height: 15),
            
            _buildDashboardCard(
              context,
              title: 'Delete PIN',
              icon: Icons.delete_outline,
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PinDeleteScreen()),
                );
              },
            ),
            
            const SizedBox(height: 15),
            
            _buildDashboardCard(
              context,
              title: 'Update Password',
              icon: Icons.lock_reset,
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UpdatePasswordPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}