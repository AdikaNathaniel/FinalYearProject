import 'package:flutter/material.dart';
import 'create-prescription.dart';
import 'view_prescription.dart';
import 'appointment-schedule-by-medic.dart';
import  'medic-appointment-details.dart';
import 'medic-appointment-status-details.dart';
import  'appointment-status-update.dart';

class AppointmentHomePage extends StatelessWidget {
  const AppointmentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text(
    'Appointments Manager',
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
            title: 'Schedule Appointment',
            subtitle: 'Schedule a new appointment for a pregnant woman',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppointmentScheduleByMedicPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
             icon: Icons.bar_chart,
             iconColor: Colors.blue,
          title: 'Doctor Appointment Stats',
           subtitle: 'Track doctor appointments and performance insights',

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorAppointmentsStatsPage()),
              );
            },
          ),




           const SizedBox(height: 16),
          _buildOptionCard(
            context,
            icon: Icons.event_note,
            iconColor: Colors.blue,
             title: 'Appointment Details',
             subtitle: 'Review and update patient appointment records',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorAppointmentsPage()),
              );
            },
          ),


          const SizedBox(height: 16),
          _buildOptionCard(
            context,
          icon: Icons.update,
          iconColor: Colors.blue,
         title: 'Update Appointment Status',
          subtitle: 'Modify and track the status of appointments',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdateAppointmentStatusPage()),
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



