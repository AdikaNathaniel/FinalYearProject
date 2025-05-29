import 'package:flutter/material.dart';
// import 'support-list.dart'; 
// import 'support-id.dart'; 
// import 'support-name.dart';
import 'support-request.dart';
import 'support-get-id.dart';
import 'support-get-name.dart';

class SupportSettingsPage extends StatelessWidget {
  final String userEmail;
  const SupportSettingsPage({super.key, required this.userEmail});

  void _onOptionSelected(BuildContext context, String option) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$option tapped')),
    );
  }

  Widget _buildSupportCard({
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
        title: const Text('Support Settings'),
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

            // Get All Support Requests
            _buildSupportCard(
              icon: Icons.list_alt,
              title: 'Get All Support Requests',
              iconColor: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupportRequestsPage()),
                );
              },
            ),

             _buildSupportCard(
  icon: Icons.find_in_page, 
  title: 'Get Support Request By Id',
  iconColor: Colors.orange,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupportByIdPage()),
    );
  },
),

 _buildSupportCard(
  icon: Icons.receipt_long, 
  title: 'Get Support Request By Name',
  iconColor: Colors.orange,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupportByNamePage()),
    );
  },
),


            // Get Support by ID
            // _buildSupportCard(
            //   icon: Icons.numbers,
            //   title: 'Get Support by ID',
            //   iconColor: Colors.blue,
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const SupportByIdPage()),
            //     );
            //   },
            // ),

            // Get Support by Name
            // _buildSupportCard(
            //   icon: Icons.person_search,
            //   title: 'Get Support by Name',
            //   iconColor: Colors.teal,
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const SupportByNamePage()),
            //     );
            //   },
            // ),

            const SizedBox(height: 16), // Bottom spacing
          ],
        ),
      ),
    );
  }
}