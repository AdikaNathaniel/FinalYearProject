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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(title, style: TextStyle(fontSize: 16)),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: onTap,
        ),
        Divider(height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            // Display user email at the top
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.teal),
                  SizedBox(width: 10),
                  Text(
                    'User: $userEmail',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Divider(),
_buildSettingTile(
  icon: Icons.lock_outline,
  title: 'Create PIN',
  iconColor: Colors.green,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatePinPage()),
    );
  },
),
    
    _buildSettingTile(
  icon: Icons.edit,
  title: 'Update PIN',
  iconColor: Colors.blueAccent,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PinUpdateScreen()),
    );
  },
),
           

              _buildSettingTile(
  icon: Icons.delete_outline,
  title: 'Delete PIN',
  iconColor: Colors.red,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PinDeleteScreen()),
    );
  },
),
            

               _buildSettingTile(
  icon: Icons.lock_reset,
  title: 'Update Password',
  iconColor: Colors.orange,
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
}