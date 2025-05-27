import 'package:flutter/material.dart';
import 'create-emergency.dart'; 
import 'emergency-list.dart';
import 'emergency-search.dart';
import 'emergency-update.dart';
import 'emergency-delete.dart';

class EmergencyContactsPage extends StatelessWidget {
  final String userEmail;
  
  const EmergencyContactsPage({super.key, required this.userEmail});

  Widget _buildSettingCard({
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
        title: const Text('Emergency Contacts Management'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
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
                  const Icon(Icons.account_circle, size: 30, color: Colors.redAccent),
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

            // Emergency Contact Actions
            _buildSettingCard(
              icon: Icons.contact_emergency,
              title: 'Add New Emergency Contact',
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateEmergencyContact()),
                );
              },
            ),
            

        
        _buildSettingCard(
              icon: Icons.contact_emergency,
              title: 'View All Emergency Contacts',
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EmergencyContactsList()),
                );
              },
            ),


            // EmergencyContactsList
            // _buildSettingCard(
            //   icon: Icons.contacts,
            //   title: 'View All Emergency Contacts',
            //   iconColor: Colors.blue,
            //   onTap: () {
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(content: Text('View All Contacts functionality coming soon')),
            //     );
            //   },
            // ),
            
             _buildSettingCard(
              icon: Icons.contact_page,
              title: 'Find An Emergency Contact',
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EmergencyContactSearch()),
                );
              },
            ),


            // UpdateEmergencyContact

             _buildSettingCard(
              icon: Icons.edit,
              title: 'Edit Emergency Contact',
              iconColor: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpdateEmergencyContact()),
                );
              },
            ),
        
            

            // DeleteEmergencyContactPage
             _buildSettingCard(
              icon: Icons.delete_forever,
              title: 'Remove Emergency Contact',
              iconColor: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  DeleteEmergencyContactPage()),
                );
              },
            ),

            // _buildSettingCard(
            //   icon: Icons.delete_forever,
            //   title: 'Remove Emergency Contact',
            //   iconColor: Colors.red,
            //   onTap: () {
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(content: Text('Remove Contact functionality coming soon')),
            //     );
            //   },
            // ),

            const SizedBox(height: 16),

            // Additional Help Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 1,
                color: Colors.grey[50],
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Emergency contacts will be notified in case of urgent situations',
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
}