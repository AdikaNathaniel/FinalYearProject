import 'package:flutter/material.dart';
import 'body-temperature-charts.dart';
import 'heart-rate-charts.dart';
import 'blood-pressure-charts.dart';
import 'blood-glucose-charts.dart';
import 'oxygen-saturation-charts.dart';
import 'protein-level-charts.dart';

class ChartsDataPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Charts Dashboard',
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
            // Body Temperature Card
            _buildDashboardCard(
              context,
              title: 'Body Temperature',
              icon: Icons.thermostat,
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BodyTemperaturePage()),
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Heart Rate Card
            _buildDashboardCard(
              context,
              title: 'Heart Rate',
              icon: Icons.favorite,
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HeartRatePage()),
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Blood Pressure Card
            _buildDashboardCard(
              context,
              title: 'Blood Pressure',
              icon: Icons.monitor_heart,
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BloodPressurePage()),
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Blood Glucose Card
            _buildDashboardCard(
              context,
              title: 'Blood Glucose',
              icon: Icons.water_drop,
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BloodGlucosePage()),
              ),
            ),
            
            const SizedBox(height: 15),


             // Protein Level Card
            _buildDashboardCard(
              context,
              title: 'Protein Level',
              icon: Icons.bubble_chart,
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProteinLevelPage()),
              ),
            ),
            
            const SizedBox(height: 15),
            
            
            // Oxygen Saturation Card
            _buildDashboardCard(
              context,
              title: 'Oxygen Saturation',
              icon: Icons.air,
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OxygenSaturationPage()),
              ),
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