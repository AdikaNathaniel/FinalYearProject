import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin-notification.dart';
import 'login_page.dart'; 
import  'support-settings.dart';

class AdminHomePage extends StatefulWidget {
  final String userEmail;
  
  const AdminHomePage({super.key, required this.userEmail});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String _selectedPage = 'Dashboard';

  Future<void> _logout(BuildContext context) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:3100/api/v1/users/logout'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          // Navigate to LoginPage after successful logout
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false
          );
        } else {
          _showSnackbar(
            context, 
            "Logout failed: ${responseData['message']}", 
            Colors.red
          );
        }
      } else {
        _showSnackbar(
          context, 
          "Logout failed: Server error", 
          Colors.red
        );
      }
    } catch (e) {
      _showSnackbar(
        context, 
        "Logout failed: ${e.toString()}", 
        Colors.red
      );
    }
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showUserInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(child: Text('Profile')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 40,
                  child: Icon(Icons.email),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(widget.userEmail)),
              ],
            ),
//             const SizedBox(height: 10),
// InkWell(
//               onTap: () {
//                 Navigator.pop(context); // Close dialog first
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => NotificationSettingsPage(userEmail: widget.userEmail),
//                   ),
//                 );
//               },
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
//                 child: Row(
//                   children: [
//                     const SizedBox(
//                       width: 40,
//                       child: Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
//                     )
//                     // const SizedBox(width: 10),
//                     // const Expanded(
//                     //   child: Text(
//                     //     'Admin Panel',
//                     //     style: TextStyle(
//                     //       fontSize: 16,
//                     //       fontWeight: FontWeight.w500,
//                     //       color: Colors.blueAccent,
//                     //     ),
//                     //   ),
//                     // ),
//                   ],
//                 ),
//               ),
//             ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(
                  width: 40,
                  child: Icon(Icons.settings),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('Settings')),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                await _logout(context);
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Admin Panel'),
      centerTitle: true,
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
    //   leading: IconButton(
    //     icon: const Icon(Icons.arrow_back),
    //     onPressed: () => Navigator.pop(context),
    //   ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => _showUserInfoDialog(context),
            child: CircleAvatar(
              child: Text(
                widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'A',
                style: const TextStyle(color: Colors.blue),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: _selectedPage == 'Dashboard'
          ? _buildDashboard(context)
          : _buildContent(_selectedPage),
    ),
  );
}


  Widget _buildDashboard(BuildContext context) {
    return Column(
      children: [
        _buildNotificationCard(
          context: context,
          icon: Icons.notifications,
          title: 'Notifications',
          iconColor: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationSettingsPage(userEmail: widget.userEmail),
              ),
            );
          },
        ),


        // SupportSettingsPage


         _buildNotificationCard(
          context: context,
          icon: Icons.support_agent,
          title: 'Support',
          iconColor: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SupportSettingsPage(userEmail: widget.userEmail),
              ),
            );
          },
        ),
        // _buildNotificationCard(
        //   context: context,
        //   icon: Icons.support_agent,
        //   title: 'Support',
        //   iconColor: Colors.green,
        //   onTap: () {
        //     setState(() {
        //       _selectedPage = 'Support';
        //     });
        //   },
        // ),
      ],
    );
  }

  Widget _buildContent(String page) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedPage = 'Dashboard';
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                page,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              '$page Page',
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        margin: const EdgeInsets.only(bottom: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}