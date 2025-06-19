import 'package:flutter/material.dart';
import 'create_cancel-appointment.dart';
import 'login_page.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'wellness-page.dart';
import 'protein-strip.dart';
import 'pregnancy-health.dart';
import 'pregnancy-chatbot.dart';
import 'pregnant-woman-chat.dart';
import 'create-emergency.dart';
import 'emergency-contact.dart';
import 'notification-list.dart'; 
import 'support-create.dart';
import 'medic-list.dart';
import 'doctor-by-name.dart';
import 'symptom-checker.dart';
import 'set_profile.dart'; 
import 'map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Metrics Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        cardTheme: CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const HealthDashboard(userEmail: 'user@example.com'),
    );
  }
}

class HealthDashboard extends StatefulWidget {
  final String userEmail;

  const HealthDashboard({Key? key, required this.userEmail}) : super(key: key);

  @override
  _HealthDashboardState createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  String weightValue = '68.5 kg';
  final TextEditingController _emergencyMessageController = TextEditingController();

  Future<void> _sendEmergencyAlert(String message) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3100/api/v1/emergency/contacts/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"message": message}),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          _showSnackbar(context, "Emergency alert sent successfully!", Colors.green);
        } else {
          _showSnackbar(context, "Failed to send alert: ${responseData['message']}", Colors.red);
        }
      } else {
        _showSnackbar(context, "Failed to send alert: Server error", Colors.red);
      }
    } catch (e) {
      _showSnackbar(context, "Error: ${e.toString()}", Colors.red);
    }
  }

  void _showEmergencyAlertDialog(BuildContext context) {
    final List<String> emergencyMessages = [
      "I'm pregnant and need help now.",
      "I feel dizzy",
      "I need to go to the hospital urgently.",
      "I'm bleeding",
      "My water just broke,I need assistance.",
    ];

    String? selectedMessage;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Emergency Alert'),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select an emergency message:'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedMessage,
                  onChanged: (value) => setState(() => selectedMessage = value),
                  items: emergencyMessages.map((message) {
                    return DropdownMenuItem<String>(
                      value: message,
                      child: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  isExpanded: true,
                  validator: (value) =>
                      value == null ? 'Please select a message' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedMessage != null && selectedMessage!.isNotEmpty) {
                  Navigator.pop(context);
                  _sendEmergencyAlert(selectedMessage!);
                } else {
                  _showSnackbar(context, "Please select an emergency message", Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Send Alert'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Metrics Dashboard',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: CircleAvatar(
              child: Text(
                widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.blue),
              ),
              backgroundColor: Colors.white,
            ),
            onPressed: () {
              _showUserInfoDialog(context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Center(
                child: Text(
                  'PREGNANT WOMAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Create-Cancel Appointment'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          CreateCancelAppointmentPage(userEmail: widget.userEmail)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety),
              title: const Text('Pregnancy Tips'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WellnessTipsScreen(userEmail: widget.userEmail),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.science),
              title: const Text('Protein In Urine'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UrineStripColorSelector(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Pregnancy InfoDesk'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PregnancyHealthForm(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.pregnant_woman, color: Colors.pinkAccent),
              title: const Text('Pregnancy Chatbot'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PregChatBotPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emergency, color: Colors.red), 
              title: const Text('Emergency Contacts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmergencyContactsPage(userEmail: widget.userEmail),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.teal),
              title: const Text('Support Desk'), 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SupportFormPage(), 
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.blue),
              title: const Text('View All Medics Profile'), 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicsListPage(), 
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.healing, color: Colors.pinkAccent),
              title: const Text('How Are You Feeling?'), 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SymptomForm(), 
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.blue),
              title: const Text(
                'Find Your Favorite Medic',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              visualDensity: VisualDensity.comfortable,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FindDoctorByNamePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue,
                Colors.red,
              ],
            ),
          ),
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              MetricCard(
                title: 'Body Temperature',
                value: '37.2°C',
                icon: Icons.thermostat,
                color: Colors.red,
                lastUpdated: '2 hours ago',
              ),
              MetricCard(
                title: 'Blood Pressure',
                value: '120/80 mmHg',
                icon: Icons.favorite,
                color: Colors.pink,
                lastUpdated: '3 hours ago',
              ),
              MetricCard(
                title: 'Blood Glucose',
                value: '5.4 mmol/L',
                icon: Icons.water_drop,
                color: Colors.purple,
                lastUpdated: '1 hour ago',
              ),
              MetricCard(
                title: 'Oxygen Saturation',
                value: '98%',
                icon: Icons.air,
                color: Colors.blue,
                lastUpdated: '30 minutes ago',
              ),
              MetricCard(
                title: 'Heart Rate',
                value: '72 BPM',
                icon: Icons.monitor_heart,
                color: Colors.red,
                lastUpdated: '15 minutes ago',
              ),
              MetricCard(
                title: 'Weight',
                value: weightValue,
                icon: Icons.monitor_weight,
                color: Colors.green,
                lastUpdated: '1 day ago',
                onEdit: _showWeightInputDialog,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showWeightInputDialog(context);
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Newly Measured Weight',
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _showUserInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(child: Text('Profile')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email),
                const SizedBox(width: 10),
                Text(widget.userEmail),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _showEmergencyAlertDialog(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 10),
                  const Text(
                    'Send An Emergency Alert',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetProfilePage(userEmail: widget.userEmail),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings, color: Colors.blue),
                  const SizedBox(width: 10),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationListPage(),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_active, color: Colors.blue),
                  const SizedBox(width: 10),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPage(),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, color: Colors.green),
                  const SizedBox(width: 10),
                  const Text(
                    'View Location Of PregMama',
                    style: TextStyle(
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),         
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final response = await http.put(
                  Uri.parse('http://localhost:3100/api/v1/users/logout'),
                  headers: {'Content-Type': 'application/json'},
                );

                if (response.statusCode == 200) {
                  final responseData = json.decode(response.body);
                  if (responseData['success']) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  } else {
                    _showSnackbar(
                        context,
                        "Logout failed: ${responseData['message']}",
                        Colors.red);
                  }
                } else {
                  _showSnackbar(
                      context, "Logout failed: Server error", Colors.red);
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showWeightInputDialog(BuildContext context) {
    final TextEditingController weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Weight'),
        content: TextField(
          controller: weightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (weightController.text.isNotEmpty) {
                setState(() {
                  weightValue = '${weightController.text} kg';
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String lastUpdated;
  final Function(BuildContext)? onEdit;

  const MetricCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.lastUpdated,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onEdit != null) {
          onEdit!(context);
        }
      },
      child: Card(
        elevation: 8,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.2),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Last updated: $lastUpdated',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}