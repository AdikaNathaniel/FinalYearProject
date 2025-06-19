import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import 'set_profile.dart'; // Add this import

class ViewAppointmentsPage extends StatefulWidget {
  final String userEmail;

  ViewAppointmentsPage({required this.userEmail});

  @override
  _ViewAppointmentsPageState createState() => _ViewAppointmentsPageState();
}

class _ViewAppointmentsPageState extends State<ViewAppointmentsPage> {
  List<dynamic> appointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3100/api/v1/appointments'));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData['success'] == true && decodedData.containsKey('result')) {
          setState(() {
            appointments = decodedData['result'];
          });
        } else {
          setState(() {
            appointments = [];
          });
        }
      } else {
        setState(() {
          appointments = [];
        });
      }
    } catch (e) {
      print("Error fetching appointments: $e");
      setState(() {
        appointments = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteAppointment(String patientName) async {
    await http.delete(Uri.parse('http://localhost:3100/api/v1/appointments/last'));
    fetchAppointments();
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
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SetProfilePage(userEmail: widget.userEmail)),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 10),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
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
                    _showSnackbar("Logout failed: ${responseData['message']}");
                  }
                } else {
                  _showSnackbar("Logout failed: Server error");
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

  void _showSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.blue, Colors.red],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('All Appointments', style: TextStyle(color: Colors.white)),
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
              onPressed: () => _showUserInfoDialog(context),
            ),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : appointments.isEmpty
                ? Center(
                    child: Text(
                      'No Appointments Available',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      var appointment = appointments[index];
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(15),
                          leading: Icon(Icons.person, color: Colors.blueAccent, size: 30),
                          title: Text(
                            appointment['details']?['patient_name'] ?? 'Unknown',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${appointment['day']} at ${appointment['time']}\n" +
                            "Condition: ${appointment['details']?['condition'] ?? 'N/A'}\n" +
                            "Notes: ${appointment['details']?['notes'] ?? 'N/A'}",
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent, size: 28),
                            onPressed: () => deleteAppointment(appointment['details']?['patient_name']),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}