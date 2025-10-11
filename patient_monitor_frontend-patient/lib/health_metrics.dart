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
import  'hardware_vitals.dart';
import  'paystack-home.dart';
// import 'hardware-live-data.dart';
import 'anemia-assessment.dart';
import 'chart-data.dart';
import 'appointment-schedule-by-medic.dart';
import 'bluetooth-wearable.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Metrics',
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
  final TextEditingController _emergencyMessageController = TextEditingController();
  Map<String, dynamic>? vitalData;
  bool isLoading = true;
  String errorMessage = '';
  int? selectedProteinLevel;
  Color? selectedProteinColor;
  Timer? _alertTimer;
  bool _showAlertDialog = false;
  bool _hasPostedInitialData = false;
  bool _isOnDashboardPage = false;
  bool _wearableDialogShown = false;

  @override
  void initState() {
    super.initState();
    _isOnDashboardPage = true;
    _fetchVitalData();
    Timer.periodic(const Duration(seconds: 120), (Timer t) => _fetchVitalData());
    
    _alertTimer = Timer.periodic(const Duration(minutes: 3), (Timer t) {
      if (_isOnDashboardPage && mounted) {
        _checkAlarmingValues();
        _sendPredictionData();
      }
    });
  }

  @override
  void dispose() {
    _isOnDashboardPage = false;
    _alertTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchVitalData() async {
    try {
      final response = await http.get(
        Uri.parse('https://finalyearproject-3-y6io.onrender.com/api/v1/heltec-live-vitals/latest'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            vitalData = responseData['result'];
            isLoading = false;
          });
          if (_isOnDashboardPage && mounted) {
            _checkAlarmingValues();
            _checkForZeroVitals();
          }
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Failed to fetch data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _checkForZeroVitals() {
    if (vitalData == null || !mounted || _wearableDialogShown) return;

    final heartRate = vitalData?['heartRate']?.toDouble() ?? 0.0;
    final spo2 = vitalData?['spo2']?.toDouble() ?? 0.0;

    if (heartRate == 0 || spo2 == 0) {
      _wearableDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showWearableCheckDialog(context);
        }
      });
    }
  }

  Future<void> _fetchLatestNonZeroVitalData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final response = await http.get(
        Uri.parse('https://finalyearproject-3-y6io.onrender.com/api/v1/heltec-live-vitals'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['result'] != null) {
          List<dynamic> allData = responseData['result'];
          
          Map<String, dynamic>? latestValidData;
          
          for (var data in allData) {
            final heartRate = data['heartRate']?.toDouble() ?? 0.0;
            final spo2 = data['spo2']?.toDouble() ?? 0.0;
            
            if (heartRate != 0 && spo2 != 0) {
              latestValidData = data;
              break;
            }
          }
          
          if (latestValidData != null) {
            setState(() {
              vitalData = latestValidData;
              isLoading = false;
              errorMessage = '';
              _wearableDialogShown = false;
            });
            if (_isOnDashboardPage && mounted) {
              _checkAlarmingValues();
            }
          } else {
            setState(() {
              errorMessage = 'No valid vital data available';
              isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Failed to fetch data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  double _scaleProteinLevel(double rawLevel) {
    return rawLevel;
  }

  Future<void> _sendPredictionData() async {
    try {
      final systolicBP = vitalData?['systolicBP']?.toDouble() ?? 0.0;
      final diastolicBP = vitalData?['diastolicBP']?.toDouble() ?? 0.0;
      final rawProteinLevel = selectedProteinLevel?.toDouble() ?? 0.0;
      final proteinUrine = _scaleProteinLevel(rawProteinLevel);

      print('Sending prediction data - Systolic: $systolicBP, Diastolic: $diastolicBP, Protein: $proteinUrine');

      final response = await http.put(
        Uri.parse('https://finalyearproject-3-y6io.onrender.com/api/v1/heltec-esp32-predictions/patient/001'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'systolicBP': systolicBP,
          'diastolicBP': diastolicBP,
          'proteinUrine': proteinUrine,
        }),
      );

      print('PUT Response Status: ${response.statusCode}');
      print('PUT Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('Prediction data updated successfully');
          _hasPostedInitialData = true;
        } else {
          print('Failed to update prediction data: ${responseData['message']}');
        }
      } else {
        print('Failed to update prediction data: Server error ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending prediction data: ${e.toString()}');
    }
  }

  void _checkAlarmingValues() {
    if (vitalData == null || !_isOnDashboardPage || !mounted) return;
    
    final systolicBP = vitalData?['systolicBP']?.toDouble();
    final diastolicBP = vitalData?['diastolicBP']?.toDouble();
    final heartRate = vitalData?['heartRate']?.toDouble();
    final spo2 = vitalData?['spo2']?.toDouble();
    final bodyTemp = vitalData?['bodyTemp']?.toDouble();
    final proteinLevel = selectedProteinLevel ?? vitalData?['proteinLevel']?.toInt();
    
    List<String> alerts = [];

    if (systolicBP != null && diastolicBP != null) {
      final map = diastolicBP + (1/3) * (systolicBP - diastolicBP);

      if (map >= 107 && proteinLevel != null && proteinLevel >= 2) {
        alerts.add('Please consult your clinical team for blood pressure management and urine infection treatment.');
      } else if (map >= 107) {
        alerts.add('Please consult your clinical team for blood pressure management.');
      } else if (proteinLevel != null && proteinLevel >= 2) {
        alerts.add('Please consult your clinical team to treat urine infections.');
      }
    }

    if (heartRate != null && (heartRate < 60 || heartRate > 130)) {
      alerts.add('Please check in with your clinical care team for guidance on your heart rate monitoring.');
    }

    if (spo2 != null && spo2 < 94) {
      alerts.add('Please check in with your clinical care team for guidance on your oxygen monitoring.');
    }

    if (bodyTemp != null && (bodyTemp >= 38 || bodyTemp <= 30)) {
      alerts.add('Please check in with your clinical care team for guidance on your temperature monitoring.');
    }

    if (alerts.isNotEmpty && !_showAlertDialog && _isOnDashboardPage && mounted) {
      _showAlertDialog = true;
      _showAlarmingValuesAlert(alerts);
    }
  }

  void _showAlarmingValuesAlert(List<String> alerts) {
    if (!mounted || !_isOnDashboardPage) return;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Health Alerts",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            elevation: 12,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.health_and_safety,
                      color: Colors.teal, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Health Alerts",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                children: alerts.asMap().entries.map((entry) {
                  int index = entry.key + 1;
                  String msg = entry.value;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          radius: 16,
                          child: Text(
                            "$index",
                            style: const TextStyle(
                                color: Colors.teal, 
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            msg,
                            style: const TextStyle(fontSize: 15, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            actions: [
              TextButton(
                onPressed: () {
                  _showAlertDialog = false;
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("OK", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendProteinLevelToBackend(int proteinLevel) async {
    try {
      final response = await http.patch(
        Uri.parse('https://finalyearproject-3-y6io.onrender.com/api/v1/heltec-live-vitals/latest/protein-level'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"proteinLevel": proteinLevel}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showSnackbar(context, "Protein level updated successfully!", Colors.green);
          _sendPredictionData();
        } else {
          _showSnackbar(context, "Failed to update protein level: ${responseData['message']}", Colors.red);
        }
      } else {
        _showSnackbar(context, "Failed to update protein level: Server error ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      _showSnackbar(context, "Error updating protein level: ${e.toString()}", Colors.red);
    }
  }

  String _getTimeAgo(String timestamp) {
    try {
      final createdAt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(createdAt);

      if (difference.inSeconds < 1) return 'Just now';
      if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
      if (difference.inMinutes < 60) return '${difference.inMinutes}min ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _sendEmergencyAlert(String message) async {
    try {
      final response = await http.post(
        Uri.parse('https://finalyearproject-3-y6io.onrender.com/api/v1/emergery/contacts/send'),
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

  void _showUrineStripDialog(BuildContext context) {
    final List<Color> colors = [
      Color(0xFF00C2C7), 
      Color(0xFFE5B7A5), 
      Color(0xFFB794C0), 
      Color(0xFFD8D8D8), 
      Color(0xFFF0D56D), 
      Color(0xFFF5C243), 
      Color(0xFFFFA500), 
      Color(0xFFFFD700), 
      Color(0xFFD2B48C), 
      Color(0xFF8B5A2B), 
    ];

    int? selectedIndex = selectedProteinLevel;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Urine Strip Color',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.0),
                
                const Text(
                  'Tap on the color that matches your urine strip',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.0),
                ),
                SizedBox(height: 12.0),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final scaledLevel = _scaleProteinLevel(index.toDouble()).toStringAsFixed(1);
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                              selectedProteinLevel = index;
                              selectedProteinColor = colors[index];
                            });
                            _sendProteinLevelToBackend(index);
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 45.0,
                            height: 45.0,
                            decoration: BoxDecoration(
                              color: colors[index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedIndex == index ? Colors.blue : Colors.transparent,
                                width: 3.0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Text('$index', 
                             textAlign: TextAlign.center, 
                             style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold)),
                      ],
                    );
                  }),
                ),
                SizedBox(height: 12.0),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final actualIndex = index + 5;
                    final scaledLevel = _scaleProteinLevel(actualIndex.toDouble()).toStringAsFixed(1);
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = actualIndex;
                              selectedProteinLevel = actualIndex;
                              selectedProteinColor = colors[actualIndex];
                            });
                            _sendProteinLevelToBackend(actualIndex);
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 45.0,
                            height: 45.0,
                            decoration: BoxDecoration(
                              color: colors[actualIndex],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedIndex == actualIndex ? Colors.blue : Colors.transparent,
                                width: 3.0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Text('$actualIndex', 
                             textAlign: TextAlign.center, 
                             style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold)),
                      ],
                    );
                  }),
                ),
                SizedBox(height: 16.0),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double? mapValue;
    if (vitalData != null && 
        vitalData!['systolicBP'] != null && 
        vitalData!['diastolicBP'] != null) {
      final systolicBP = vitalData!['systolicBP'].toDouble();
      final diastolicBP = vitalData!['diastolicBP'].toDouble();
      mapValue = diastolicBP + (1/3) * (systolicBP - diastolicBP);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Metrics ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchLatestNonZeroVitalData();
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              child: Text(
                widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.blue, fontSize: 16),
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
              title: const Text('Schedule Appointment'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppointmentScheduleByMedicPage(),
                  ),
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

            // ListTile(
            //   leading: const Icon(Icons.info),
            //   title: const Text('Pregnancy InfoDesk'),
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => PregnancyHealthForm(),
            //       ),
            //     );
            //   },
            // ),
            
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
              leading: const Icon(Icons.attach_money, color: Colors.teal),
              title: const Text('Make Payment'), 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaystackInitiatePage(), 
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
              leading: const Icon(Icons.pregnant_woman, color: Colors.pinkAccent),
              title: const Text('Anemia Assessment'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnaemiaAssessmentScreen(),
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
              leading: Icon(Icons.bloodtype),
              title: Text('Charts Data'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChartsDataPage()),
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
          padding: const EdgeInsets.all(12),
          child: isLoading 
            ? const Center(child: CircularProgressIndicator
            (color: Colors.blueAccent))
            : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 0.95,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        MetricCard(
                          title: 'Blood Glucose',
                          value: '${vitalData?['glucose']?.toStringAsFixed(1) ?? 'N/A'} mg/dL',
                          icon: Icons.water_drop,
                          color: Colors.purple,
                          lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                        ),
                        
                        MetricCard(
                          title: 'Blood Pressure',
                          value: '${vitalData?['systolicBP']?.toStringAsFixed(0) ?? 'N/A'}/${vitalData?['diastolicBP']?.toStringAsFixed(0) ?? 'N/A'} mmHg',
                          icon: Icons.favorite,
                          color: Colors.pink,
                          lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                        ),
                        
                        MetricCard(
                          title: 'Heart Rate',
                          value: '${vitalData?['heartRate']?.toStringAsFixed(0) ?? 'N/A'} BPM',
                          icon: Icons.monitor_heart,
                          color: Colors.red,
                          lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                        ),
                        
                        MetricCard(
                          title: 'Oxygen Saturation',
                          value: '${vitalData?['spo2']?.toStringAsFixed(0) ?? 'N/A'}%',
                          icon: Icons.air,
                          color: Colors.blue,
                          lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                        ),
                        
                        MetricCard(
                          title: 'Body Temperature',
                          value: '${vitalData?['bodyTemp']?.toStringAsFixed(1) ?? 'N/A'}°C',
                          icon: Icons.thermostat,
                          color: Colors.orange,
                          lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                        ),
                        
                        GestureDetector(
                          onTap: () => _showUrineStripDialog(context),
                          child: Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.indigo.withOpacity(0.2),
                                    ),
                                    child: Icon(
                                      Icons.science,
                                      color: selectedProteinLevel != null 
                                          ? selectedProteinColor ?? Colors.indigo
                                          : Colors.indigo,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Protein in Urine',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      selectedProteinLevel != null 
                                          ? 'Level: $selectedProteinLevel'
                                          : 'Tap to Test',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: selectedProteinLevel != null 
                                            ? Colors.black87 
                                            : Colors.blue,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    selectedProteinLevel != null 
                                        ? 'Last updated: Just now'
                                        : 'Click me to test',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _showUrineStripDialog(context),
      //   child: const Icon(Icons.add),
      //   tooltip: 'Add Protein Test Result',
      //   backgroundColor: Colors.blueAccent,
      // ),
    );
  }


  void _showUserInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 20, color: Colors.blue),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.userEmail,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showEmergencyAlertDialog(context);
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.emergency, size: 20, color: Colors.red),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text(
                          'Send An Emergency Alert',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
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
                    children: [
                      const Icon(Icons.settings_outlined, size: 20, color: Colors.blueGrey),
                      const SizedBox(width: 12),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

            
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WearableDevicePairingPage(userEmail: widget.userEmail),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.bluetooth, size: 20, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text(
                          'Pair With Bluetooth Device',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
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
                    children: [
                      const Icon(Icons.notifications_active_outlined, size: 20, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
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
                    children: [
                      const Icon(Icons.help_outline, size: 20, color: Colors.purple),
                      const SizedBox(width: 12),
                      const Text(
                        'Need Help?',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
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
                    children: [
                      const Icon(Icons.location_on, size: 20, color: Colors.green),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text(
                          'View Location Of PregMama',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              TextButton(
                onPressed: () async {
                  final response = await http.put(
                    Uri.parse('https://finalyearproject-3-y6io.onrender.com/api/v1/users/logout'),
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
                          context,
                          "Logout failed: Server error",
                          Colors.red);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWearableCheckDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Wearable Check'),
        content: const Text('Are You Wearing The Wearable?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchLatestNonZeroVitalData();
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WearableDevicePairingPage(userEmail: widget.userEmail),
                ),
              );
            },
            child: const Text('Yes'),
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

  const MetricCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.lastUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lastUpdated,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}