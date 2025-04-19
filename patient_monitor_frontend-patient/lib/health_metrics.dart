import 'package:flutter/material.dart';
import 'create_cancel-appointment.dart';
import 'login_page.dart'; // Import for logout navigation
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'wellness-page.dart';
import 'protein-strip.dart';
import 'pregnancy-health.dart';
import 'pregnancy-chatbot.dart';
import 'pregnant-woman-chat.dart';


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
      home: HealthDashboard(userEmail: 'user@example.com'), // Pass userEmail here
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
                style: TextStyle(color: Colors.blue),
              ),
              backgroundColor: Colors.white,
            ),
            onPressed: () {
              _showUserInfoDialog(context); // Show user info dialog
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
              leading: Icon(Icons.calendar_today),
              title: Text('Create-Cancel Appointment'),
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
              leading: Icon(Icons.health_and_safety),
              title: Text('Pregnancy Tips'),
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
              leading: Icon(Icons.science),
              title: Text('Protein In Urine'),
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
  leading: Icon(Icons.info),
  title: Text('Pregnancy InfoDesk'),
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
  title: const Text('Pregnancy Chatbot'), // Add a title text
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PregChatBotPage(), // Ensure PregChatBotPage is a const constructor
      ),
    );
  },
),
ListTile(
  leading: const Icon(Icons.pregnant_woman, color: Colors.pinkAccent),
  title: const Text('Doctor Chat'), // Add a title text
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PregnantWomanChatPage(), // Ensure PregChatBotPage is a const constructor
      ),
    );
  },
),
          ],
        ),
      ),
      body: SingleChildScrollView(
        // Wrap the body in SingleChildScrollView
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
            shrinkWrap: true, // Allow GridView to take only the space it needs
            physics:
                NeverScrollableScrollPhysics(), // Disable scrolling in GridView
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
                onEdit: _showWeightInputDialog, // Pass the edit function
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showWeightInputDialog(context); // Show weight input dialog
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
        title: Center(child: Text('Profile')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email),
                SizedBox(width: 10),
                Text(widget.userEmail),
              ],
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                // Call logout API
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
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
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
        title: Text('Enter Weight'),
        content: TextField(
          controller: weightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Weight (kg)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (weightController.text.isNotEmpty) {
                setState(() {
                  weightValue = '${weightController.text} kg'; // Update the weight value
                });
                Navigator.pop(context);
              }
            },
            child: Text('Submit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: Duration(seconds: 2),
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
  final Function(BuildContext)? onEdit; // Callback for editing weight

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
          onEdit!(context); // Call the edit function if it exists
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