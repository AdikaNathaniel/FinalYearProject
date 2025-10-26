import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'view-appointment.dart';
import 'create_cancel-appointment.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'doctor-chat.dart';
import 'set_profile.dart';
import 'support-create.dart';
import 'doctor-profile.dart';
import 'symptom-list.dart';
import 'symptom-by-name.dart';
import 'appointment-schedule-by-medic.dart';
import 'medic-appointment-details.dart';
import 'medic-appointment-status-details.dart';
import 'appointment-status-update.dart';
import 'prescriptions-home.dart';
import 'appointments-home.dart';
import 'preeclampsia-home.dart';
import 'map.dart'; 
import 'preeclampsia-live.dart';
import 'glucose-monitor.dart';
import 'vitals-input.dart';
import 'hardware-live-data.dart';
import 'anemia-home.dart';
import 'vitals-health-data-list.dart';
import 'vitals-health-data-get-specific-user.dart';
import 'csv.dart';
import 'chart-data.dart';
import 'notification-list.dart';
import 'medic-chat.dart';


class PregnancyComplicationsPage extends StatefulWidget {
  final String userEmail;

  PregnancyComplicationsPage({required this.userEmail});

  @override
  _PregnancyComplicationsPageState createState() => _PregnancyComplicationsPageState();
}

class _PregnancyComplicationsPageState extends State<PregnancyComplicationsPage> {
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
      Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/users/logout'),
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
        _showSnackbar("Logout failed: ${responseData['message']}");
      }
    } else {
      _showSnackbar("Logout failed: Server error");
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
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          Row(
            children: [
              Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
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
            onPressed: () => _showUserInfoDialog(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  'MEDICAL OFFICER',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Prescriptions'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrescriptionHomePage()),
                );
              },
            ),

             ListTile(
              leading: Icon(Icons.show_chart, color: Colors.cyan),
              title: Text('Retrieve Readings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CsvPage()),
                );
              },
            ),
         

            // ListTile(
            //   leading: Icon(Icons.medication),
            //   title: Text('Doctor Chat'),
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => DoctorChatPage()),
            //     );
            //   },
            // ),


            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Support Desk'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SupportFormPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.medical_services),
              title: Text('Create A Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DoctorProfilePage()),
                );
              },
            ),

           


            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Appointments'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AppointmentHomePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.monitor_heart),
              title: Text('Anemia Predictions'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AnaemiaHomePage()),
                );
              },
            ),

            


             ListTile(
              leading: Icon(Icons.bloodtype),
              title: Text('Glucose Monitoring'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GlucoseMonitoringPage()),
                );
              },
            ),


            ListTile(
              leading: Icon(Icons.bloodtype),
              title: Text('Charts Data '),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChartsDataPage()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.edit),
              title: Text('View Manually Entered Vitals'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VitalsHealthDataListPage()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.history),
              title: Text('View Vitals History'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VitalsHistoryPage()),
                );
              },
            ),
  
            ListTile(
              leading: Icon(Icons.monitor_heart),
              title: Text('Live Vitals Data'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LiveVitalsHardwareDataPage()),
                );
              },
            ),

// ListTile(
//   leading: Icon(Icons.medical_services, color: Colors.blue),
//   title: Text('Patient Consultations'),
//   onTap: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => DoctorChatPage(
//           doctorId: 'doctor_456',     // Replace with actual doctor ID
//           doctorName: 'Dr. Smith',    // Replace with actual doctor name
//         ),
//       ),
//     );
//   },
// ),

            ListTile(
              leading: Icon(Icons.health_and_safety),
              title: Text('Preeclampsia Dashboard'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PreeclampsiaDashboard()),
                );
              },
            )
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
                      severityIndicator(complications[currentIndex]['severity']!)
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
        message = 'Immediate attention is needed. Contact your healthcare provider.';
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
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }

  void _showUserInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(child: Text('Profile')),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.userEmail,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                  children: const [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Send An Emergency Alert',
                        style: TextStyle(color: Colors.black),
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
                  children: const [
                    Icon(Icons.settings, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: TextStyle(color: Colors.black),
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
                  children: const [
                    Icon(Icons.notifications_active, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Notifications',
                      style: TextStyle(color: Colors.black),
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
                      builder: (context) => SupportFormPage(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.chat_bubble_outline, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Need Help?',
                      style: TextStyle(color: Colors.black),
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
                  children: const [
                    Icon(Icons.map, color: Colors.black, size: 18),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'View Location Of PregMama',
                        style: TextStyle(color: Colors.black, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),         
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  final response = await http.put(
                    Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/users/logout'),
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
                      _showSnackbarWithColor("Logout failed: ${responseData['message']}", Colors.red);
                    }
                  } else {
                    _showSnackbarWithColor("Logout failed: Server error", Colors.red);
                  }
                },
                child: const Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
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

  void _showEmergencyAlertDialog(BuildContext context) {
    final List<String> emergencyMessages = [
      "I'm pregnant and need help now.",
      "I feel dizzy",
      "I need to go to the hospital urgently.",
      "I'm bleeding",
      "My water just broke, I need assistance.",
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
                  _showSnackbarWithColor("Please select an emergency message", Colors.red);
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

  Future<void> _sendEmergencyAlert(String message) async {
    try {
      final response = await http.post(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/emergency/contacts/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"message": message}),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          _showSnackbarWithColor("Emergency alert sent successfully!", Colors.green);
        } else {
          _showSnackbarWithColor("Failed to send alert: ${responseData['message']}", Colors.red);
        }
      } else {
        _showSnackbarWithColor("Failed to send alert: Server error", Colors.red);
      }
    } catch (e) {
      _showSnackbarWithColor("Error: ${e.toString()}", Colors.red);
    }
  }

  void _showSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showSnackbarWithColor(String message, Color color) {
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