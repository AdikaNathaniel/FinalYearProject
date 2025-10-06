import 'package:flutter/material.dart';
import 'preeclampsia-get-all.dart';
import 'preeclampsia-get-by-id.dart';
import 'preeclampsia-update.dart';
import 'preeclampsia-delete.dart';
import 'preeclampsia-post.dart';
import 'symptom-list.dart';
import 'symptom-by-name.dart';

class PreeclampsiaDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Preeclampsia Dashboard',
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
            // Dashboard Cards - Start directly with Create New Record
            _buildDashboardCard(
              context,
              title: 'Create New Record',
              icon: Icons.add_circle,
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateRecordPage()),
              ),
            ),
            
            const SizedBox(height: 15),
            
            _buildDashboardCard(
              context,
              title: 'View All Records',
              icon: Icons.list_alt,
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GetAllRecordsPage()),
              ),
            ),
            
            const SizedBox(height: 15),
            
            _buildDashboardCard(
              context,
              title: 'Search Patient',
              icon: Icons.search,
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GetRecordByIdPage()),
              ),
            ),
            
            const SizedBox(height: 15),
            
            _buildDashboardCard(
              context,
              title: 'Update Record',
              icon: Icons.edit,
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdateRecordPage()),
              ),
            ),
            
            const SizedBox(height: 15),
            
            _buildDashboardCard(
              context,
              title: 'Delete Record',
              icon: Icons.delete,
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeleteRecordPage()),
              ),
            ),


             const SizedBox(height: 15),
            
            _buildDashboardCard(
              context,
              title: "Symptoms By ID",
              icon: Icons.person_search,
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FindSymptomPage()),
                );
              },
            ),


            const SizedBox(height: 15),
            
            _buildDashboardCard(
              context,
              title: "All Symptoms",
              icon: Icons.medical_services,
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SymptomListPage()),
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