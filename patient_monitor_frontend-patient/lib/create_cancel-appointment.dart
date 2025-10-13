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

  // Changed from automatically set to selectable
  String _selectedDay = '';
  String _selectedTime = '';
  TimeOfDay? _selectedTimeOfDay;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Set initial values to current date and time
    DateTime now = DateTime.now();
    _selectedDate = now;
    _selectedTimeOfDay = TimeOfDay.fromDateTime(now);
    
    // Format the date immediately (doesn't need context)
    _selectedDay =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    
    // Don't format time here - will be done in build when context is available
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now context is available, format the time
    if (_selectedTimeOfDay != null && _selectedTime.isEmpty) {
      _selectedTime = _selectedTimeOfDay!.format(context);
    }
  }

  void _updateDateTimeStrings() {
    if (_selectedDate != null) {
      _selectedDay =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    }
    if (_selectedTimeOfDay != null) {
      _selectedTime = _selectedTimeOfDay!.format(context);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateTimeStrings();
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimeOfDay ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTimeOfDay) {
      setState(() {
        _selectedTimeOfDay = picked;
        _updateDateTimeStrings();
      });
    }
  }

  Future<void> createAppointment() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTimeOfDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select both date and time')),
        );
        return;
      }

      Map<String, dynamic> appointment = {
        "email": "patient@example.com",
        "day": _selectedDay,
        "time": _selectedTime,
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
          Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/appointments'),
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
        await http.delete(Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/appointments/last'));

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Appointment deleted successfully!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete appointment.')));
    }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.settings),
                SizedBox(width: 10),
                Text('Settings'),
              ],
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                // Call logout API
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

  void _showSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildTimeDatePicker(String label, String value, VoidCallback onTap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: label.contains("Time") 
            ? Icon(Icons.access_time, color: Colors.blue)
            : Icon(Icons.calendar_today, color: Colors.blue),
        title: Text('$label: $value'),
        trailing: Icon(Icons.arrow_drop_down, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Appointment',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
              _showUserInfoDialog(context);
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white, // Changed to white background
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(_nameController, "Patient Name", Icons.person),
                        const SizedBox(height: 16),
                        _buildTextField(_conditionController, "Condition", Icons.medical_services),
                        const SizedBox(height: 16),
                        _buildTextField(_notesController, "Notes", Icons.notes),
                        const SizedBox(height: 16),
                        
                        // Selectable Date
                        _buildTimeDatePicker(
                          "Date", 
                          _selectedDay.isEmpty ? "Select Date" : _selectedDay,
                          () => _selectDate(context)
                        ),
                        
                        // Selectable Time
                        _buildTimeDatePicker(
                          "Time", 
                          _selectedTime.isEmpty ? "Select Time" : _selectedTime,
                          () => _selectTime(context)
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _commonButton("Create Appointment", Colors.green, createAppointment),
                  const SizedBox(width: 10),
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
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
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