import 'package:flutter/material.dart';
import 'create-prescription.dart';
import 'view_prescription.dart';

class PrescriptionHomePage extends StatelessWidget {
  const PrescriptionHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
  title: const Text(
    'Prescriptions Manager',
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
            icon: Icons.add_circle_outline,
            iconColor: Colors.blue,
            title: 'Create Prescription',
            subtitle: 'Generate and assign a prescription for the patient',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreatePrescriptionPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            icon: Icons.list_alt,
            iconColor: Colors.blue,
            title: 'View Prescriptions',
            subtitle: 'Access and review all patient prescriptions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PrescriptionPage()),
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

// Placeholder Screens
class CreatePrescriptionScreen extends StatelessWidget {
  const CreatePrescriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Prescription')),
      body: const Center(child: Text('Create Prescription Screen')),
    );
  }
}

class ViewPrescriptionsScreen extends StatelessWidget {
  const ViewPrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Prescriptions')),
      body: const Center(child: Text('View Prescriptions Screen')),
    );
  }
}
