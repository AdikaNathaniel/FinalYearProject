import 'package:flutter/material.dart';
import 'anemia-result.dart';
import 'get-anemia-risk-by-id.dart';
import 'anemia-stats.dart';
import 'anemia-assessment.dart';
import 'anemia-get-by-id.dart';

class AnaemiaHomePage extends StatelessWidget {
  const AnaemiaHomePage({super.key});

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 6,
        shadowColor: color.withOpacity(0.4),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 35,
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 20),
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
  title: const Text(
    "Anaemia Risk Home",
    style: TextStyle(
      color: Colors.white, // set title text color to white
    ),
  ),
  backgroundColor: Colors.teal,
  centerTitle: true,
),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildCard(
                icon: Icons.health_and_safety,
                title: "Risk Assessment",
                subtitle: "Perform a new assessment",
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AnaemiaAssessmentScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildCard(
                icon: Icons.assignment,
                title: "Results",
                subtitle: "View patient risk results",
                color: Colors.redAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AnaemiaResultsScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildCard(
                icon: Icons.assignment_ind,
                title: "Get Anemia Risk By Patient ID",
                subtitle: "View patient-specific risk results",
                color: Colors.purpleAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GetAnaemiaByIdPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildCard(
                icon: Icons.pie_chart,
                title: "Statistics",
                subtitle: "View overall anaemia risk data",
                color: Colors.blue,
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
      ),
    );
  }
}