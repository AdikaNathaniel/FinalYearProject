import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart'; // Import for logout navigation

class CreateCancelAppointmentPage extends StatefulWidget {
  final String userEmail;

  CreateCancelAppointmentPage({required this.userEmail});

  @override
  _CreateCancelAppointmentPageState createState() =>
      _CreateCancelAppointmentPageState();
}

class _CreateCancelAppointmentPageState
    extends State<CreateCancelAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Automatically set the current day and time
  String _currentDay = '';
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    // Set the current day and time
    DateTime now = DateTime.now();
    _currentDay =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _currentTime =
        '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> createAppointment() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> appointment = {
        "email": "patient@example.com",
        "day": _currentDay,
        "time": _currentTime,
        "patient_name": _nameController.text,
        "condition": _conditionController.text.isNotEmpty
            ? _conditionController.text
            : "Routine check-up",
        "notes": _notesController.text.isNotEmpty
            ? _notesController.text
            : "No specific notes"
      };

      try {
        final response = await http.post(
          Uri.parse('http://localhost:3100/api/v1/appointments'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(appointment),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Appointment created successfully!')));
          _nameController.clear();
          _conditionController.clear();
          _notesController.clear(); // Clear input fields after submission
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Failed to create appointment. Status: ${response.statusCode}'),
          ));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error sending request: $e'),
        ));
      }
    }
  }

  Future<void> deleteAppointment() async {
    final response =
        await http.delete(Uri.parse('http://localhost:3100/api/v1/appointments/last'));

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Appointment deleted successfully!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete appointment.')));
    }
  }

  void _showUserInfoDialog(BuildContext context) {
     String email = widget.userEmail;
    // String role = 'Doctor'; // Hardcoded role

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
            Row(
              children: [
                // Icon(Icons.person),
                SizedBox(width: 10),
                // Text(role),
              ],
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
                    _showSnackbar(context, "Logout failed: ${responseData['message']}", Colors.red);
                  }
                } else {
                  _showSnackbar(context, "Logout failed: Server error", Colors.red);
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

  void _showSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appointment Management',
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
      backgroundColor: Colors.white,
      child: Text(
        widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'U',
        style: TextStyle(color: Colors.blue),
      ),
    ),
    onPressed: () {
      _showUserInfoDialog(context); // Show user info dialog
    },
  ),
],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.blue,
              Colors.red,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensure space is used properly
            children: [
              Expanded( // Make form elements take up available space
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Make form fields take full width
                      children: [
                        _inputField("Patient Name", _nameController, icon: Icons.person_outline),
                        const SizedBox(height: 40),
                        _inputField("Condition", _conditionController, icon: Icons.medical_services),
                        const SizedBox(height: 40),
                        _inputField("Notes", _notesController, icon: Icons.notes),
                        const SizedBox(height: 40),
                        TextFormField(
                          readOnly: true,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: "Date",
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                          ),
                          initialValue: _currentDay,
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          readOnly: true,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: "Time",
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                          ),
                          initialValue: _currentTime,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _commonButton("Create Appointment", Colors.green, createAppointment),
                  const SizedBox(width: 20),
                  _commonButton("Cancel Appointment", Colors.red, deleteAppointment),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _commonButton(String text, Color color, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _inputField(String labelText, TextEditingController controller, {IconData? icon}) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter some text';
        }
        return null;
      },
    );
  }
}
