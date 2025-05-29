import 'package:flutter/material.dart';
import 'create-notification.dart';
import 'notification-list.dart';
import 'delete-notification.dart';
import 'notification-id.dart';
import 'notification-role.dart';
import 'notification-sent.dart';
import 'notification-update.dart';


class NotificationSettingsPage extends StatelessWidget {
  final String userEmail;
  const NotificationSettingsPage({super.key, required this.userEmail});

  void _onOptionSelected(BuildContext context, String option) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$option tapped')),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Display admin email at the top
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Admin: $userEmail',
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            _buildNotificationCard(
  icon: Icons.add_alert,
  title: 'Create Notification',
  iconColor: Colors.green,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateNotificationPage()),
    );
  },
),

            


  _buildNotificationCard(
  icon: Icons.group,
  title: 'Get Notifications by Role',
  iconColor: Colors.teal,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const   NotificationsByRolePage()),
    );
  },
),

            
//             _buildNotificationCard(
//   icon: Icons.group,
//   title: 'Create Notifications By Role',
//   iconColor: Colors.green,
//   onTap: () {
//     Navigator.push(
//       context,
//        MaterialPageRoute(builder: (context) => const   NotificationsByRolePage()),
//     );
//   },
// ),
            

                _buildNotificationCard(
  icon: Icons.notifications_active,
  title: 'Get All Notifications',
  iconColor: Colors.orange,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationListPage()),
    );
  },
),
            

            // NotificationUpdatePage
            // _buildNotificationCard(
            //   icon: Icons.edit_notifications,
            //   title: 'Update Notification',
            //   iconColor: Colors.blue,
            //   onTap: () => _onOptionSelected(context, 'Update Notification'),
            // ),



             _buildNotificationCard(
  icon: Icons.info_outline,
  title: 'Update Notification ',
  iconColor: Colors.blue,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationUpdatePage()),
    );
  },
),
            

            


                  _buildNotificationCard(
  icon: Icons.info_outline,
  title: 'Get Notification by ID',
  iconColor: Colors.orange,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationByIdPage()),
    );
  },
),
      
            
                          _buildNotificationCard(
  icon: Icons.check_circle_outline,
  title: 'Mark Notification as Sent',
  iconColor: Colors.indigo,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationSentPage()),
    );
  },
),
            



          _buildNotificationCard(
  icon: Icons.delete_forever,
  title: 'Delete Notifications',
  iconColor: Colors.red,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeleteNotificationPage()),
    );
  },
),
            const SizedBox(height: 16), // Bottom spacing
          ],
        ),
      ),
    );
  }
}