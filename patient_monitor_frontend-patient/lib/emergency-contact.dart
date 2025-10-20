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
        title: const Text('Manage Contacts'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Emergency Contact Actions
            _buildSettingCard(
              icon: Icons.contact_emergency,
              title: 'Add Emergency Contact',
              iconColor: Colors.blue,
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
              iconColor: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EmergencyContactsList()),
                );
              },
            ),
            
            _buildSettingCard(
              icon: Icons.contact_page,
              title: 'Find An Emergency Contact',
              iconColor: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EmergencyContactSearch()),
                );
              },
            ),

            _buildSettingCard(
              icon: Icons.edit,
              title: 'Edit Emergency Contact',
              iconColor: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpdateEmergencyContact()),
                );
              },
            ),
        
            _buildSettingCard(
              icon: Icons.delete_forever,
              title: 'Remove Emergency Contact',
              iconColor: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  DeleteEmergencyContactPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}