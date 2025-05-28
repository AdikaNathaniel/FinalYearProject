import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  final String userEmail;
  
  const NotificationsPage({super.key, required this.userEmail});

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, 
                size: 16, 
                color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Management'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Information Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: const Border(bottom: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle, size: 30, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current User', 
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(userEmail,
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w500,
                          color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notification Actions
            _buildNotificationCard(
              icon: Icons.notifications,
              title: 'View All Notifications',
              iconColor: Colors.blue,
              onTap: () {},
            ),
            
            _buildNotificationCard(
              icon: Icons.notification_important,
              title: 'Find Notification by ID',
              iconColor: Colors.orange,
              onTap: () {
                _showNotificationIdDialog(context);
              },
            ),

            const SizedBox(height: 16),

            // Additional Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 1,
                color: Colors.grey[50],
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'View and manage all your system notifications here',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationIdDialog(BuildContext context) {
    final TextEditingController idController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Notification ID'),
          content: TextField(
            controller: idController,
            decoration: const InputDecoration(
              hintText: 'Notification ID',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.text,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('View'),
              onPressed: () {
                final notificationId = idController.text.trim();
                if (notificationId.isNotEmpty) {
                  Navigator.of(context).pop();
                  // TODO: Add navigation or action for viewing the notification
                }
              },
            ),
          ],
        );
      },
    );
  }
}