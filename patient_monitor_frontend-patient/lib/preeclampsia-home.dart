import 'package:flutter/material.dart';
import 'create-prescription.dart';
import 'view_prescription.dart';
import 'create-prescription.dart';
import 'symptom-list.dart';
import 'symptom-by-name.dart';

class PreeclampsiaHomePage extends StatelessWidget {
  const PreeclampsiaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
  title: const Text(
    'Preeclampsia Manager',
    style: TextStyle(color: Colors.white),
  ),
  centerTitle: true,
  backgroundColor: Colors.blueAccent,
),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildOptionCard(
            context,
            icon: Icons.local_hospital,
            iconColor: Colors.blue,
            title: 'Preeclampsia Management',
            subtitle: 'Manage and monitor preeclampsia cases',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SymptomListPage()),
              );
            },
          ),
        
           const SizedBox(height: 16),
          _buildOptionCard(
            context,
            icon: Icons.monitor_heart_outlined,
            iconColor: Colors.blue,
            title: 'Preeclampsia Vitals Monitor',
            subtitle: 'Access and review all patient prescriptions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FindSymptomByNamePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 30, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}


