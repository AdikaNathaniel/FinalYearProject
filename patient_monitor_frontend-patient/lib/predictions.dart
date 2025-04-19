import 'dart:async';
import 'dart:math'; // Import the dart:math package
import 'package:flutter/material.dart';
import 'view-appointment.dart';
import 'create_cancel-appointment.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'view_prescription.dart';
import 'create-prescription.dart';
import 'doctor-chat.dart';
import 'Doctor/PatientViewWithLiveData.dart';
import 'Doctor/AbnormalVitalsPage.dart';
import 'Doctor/DoctorInputPage.dart';
import 'Doctor/ReportDiagnosticPage.dart';
import 'Doctor/PatientQueryPage.dart';

class PregnancyComplicationsPage extends StatefulWidget {
  final String userEmail;


  PregnancyComplicationsPage({
    required this.userEmail,
 
  });

  @override
  _PregnancyComplicationsPageState createState() =>
      _PregnancyComplicationsPageState();
}

class _PregnancyComplicationsPageState
    extends State<PregnancyComplicationsPage> {
  List<Map<String, String>> complications = [
    {'name': 'Preeclampsia', 'severity': 'Mid'},
    {'name': 'Anemia', 'severity': 'High'},
    {'name': 'Gestational Diabetes', 'severity': 'Low'}
  ];

  int currentIndex = 0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Update the displayed complication every 30 seconds
    Timer.periodic(Duration(seconds: 30), (timer) {
      setState(() {
        currentIndex = (currentIndex + 1) % complications.length;
        _randomizeSeverities();
      });
    });
  }

  void _randomizeSeverities() {
    const severities = ['Low', 'Mid', 'High'];
    for (var complication in complications) {
      complication['severity'] = severities[_random.nextInt(severities.length)];
    }
  }

  void _logout() async {
    final response = await http.put(
      Uri.parse('http://localhost:3100/api/v1/users/logout'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        _showSuccessDialog("Logout successfully");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        _showSnackbar("Logout failed: ${responseData['message']}", Colors.red);
      }
    } else {
      _showSnackbar("Logout failed: Server error", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text(
            'Pregnancy Complication Prediction',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          // Add theme toggle switch
          Row(
            children: [
              Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              // Switch(
              //   value: isDarkMode,
              //   onChanged: (value) {
              //     widget.themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
              //   },
              // ),
            ],
          ),
          IconButton(
            icon: CircleAvatar(
              child: Text(
                widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'U',
                style: TextStyle(color: Colors.blue),
              ),
              backgroundColor: Colors.white,
            ),
            onPressed: () {
              // Show user info dialog
              _showUserInfoDialog();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Center(
                child: Text(
                  'MEDICAL OFFICER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Medical Appointments'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ViewAppointmentsPage(userEmail: widget.userEmail)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Create-Cancel Appointment'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateCancelAppointmentPage(userEmail: widget.userEmail)),
                );
              },
            ),
             ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Create Prescription'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreatePrescriptionPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.medication),
              title: Text('View Prescriptions'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrescriptionPage(), // Use widget.themeNotifier
                  ),
                );
              },
            ),

             ListTile(
              leading: Icon(Icons.medication),
              title: Text('Pregnant Woman Chat'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorChatPage(), // Use widget.themeNotifier
                  ),
                );
              },
            ),

             ListTile(
              leading: Icon(Icons.medication),
              title: Text('Anomalies Page'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AbnormalVitalsScreen(), // Use widget.themeNotifier
                  ),
                );
              },
            ),
                     
             ListTile(
              leading: Icon(Icons.monitor_heart),
              title: Text('View Live Vitals Data'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientVitalsPage(), // Use widget.themeNotifier
                  ),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.monitor_heart),
              title: Text('Comments Page'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorInputPage(), // Use widget.themeNotifier
                  ),
                );
              },
            ),

             ListTile(
              leading: Icon(Icons.monitor_heart),
              title: Text('Diagnostic Report'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiagnosticToolPage(), // Use widget.themeNotifier
                  ),
                );
              },
            ),

               ListTile(
              leading: Icon(Icons.monitor_heart),
              title: Text('Patient Data Query'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientQueryPage(), // Use widget.themeNotifier
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.red],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade100, Colors.pink.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        complications[currentIndex]['name']!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 10),
                      severityIndicator(
                          complications[currentIndex]['severity']!)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget severityIndicator(String severity) {
    Color color;
    String message;

    switch (severity) {
      case 'Low':
        color = Colors.green;
        message = 'Monitor your health, stay active and hydrated!';
        break;
      case 'Mid':
        color = Colors.orange;
        message = 'Watch for symptoms and consult your doctor regularly.';
        break;
      case 'High':
        color = Colors.red;
        message =
            'Immediate attention is needed. Contact your healthcare provider.';
        break;
      default:
        color = Colors.grey;
        message = 'Consult your doctor for further guidance.';
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            severity,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showUserInfoDialog() {
    String email = widget.userEmail;
    // String role = 'Doctor'; 

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
                Text(email),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                // Icon(Icons.person),
                SizedBox(width: 10),
                // Text(role),
              ],
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: _logout, // Call logout function when pressed
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

  void _showSnackbar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}