import 'package:flutter/material.dart';
import 'anemia-result.dart';
import 'get-anemia-risk-by-id.dart';
import 'anemia-stats.dart';
import 'anemia-assessment.dart';
import 'anemia-get-by-id.dart';

class AnaemiaHomePage extends StatelessWidget {
  const AnaemiaHomePage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Anaemia Risk Home",
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
              title: "Risk Assessment",
              icon: Icons.health_and_safety,
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AnaemiaAssessmentScreen()),
                );
              },
            ),
            
            const SizedBox(height: 15),
            
            _buildDashboardCard(
              context,
              title: "Anemia Results",
              icon: Icons.assignment,
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AnaemiaResultsScreen()),
                );
              },
            ),
            
            const SizedBox(height: 15),
            
            _buildDashboardCard(
              context,
              title: "Find Patient",
              icon: Icons.assignment_ind,
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GetAnaemiaByIdPage()),
                );
              },
            ),
            
            const SizedBox(height: 15),
            
            _buildDashboardCard(
              context,
              title: "Anaemia Statistics",
              icon: Icons.pie_chart,
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AnaemiaRiskStatisticsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}