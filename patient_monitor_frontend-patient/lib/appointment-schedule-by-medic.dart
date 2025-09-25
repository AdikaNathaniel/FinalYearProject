import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class AppointmentScheduleByMedicPage extends StatefulWidget {
  const AppointmentScheduleByMedicPage({Key? key}) : super(key: key);

  @override
  _AppointmentScheduleByMedicPageState createState() =>
      _AppointmentScheduleByMedicPageState();
}

class _AppointmentScheduleByMedicPageState
    extends State<AppointmentScheduleByMedicPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final patientIdController = TextEditingController();
  final phoneController = TextEditingController();
  final doctorController = TextEditingController();
  final locationController = TextEditingController();
  final patientNameController = TextEditingController();
  final purposeController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both date and time')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Combine date and time
      final appointmentDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // Format for API (ISO 8601 format)
      final formattedDate = appointmentDateTime.toIso8601String();

      final response = await http.post(
        Uri.parse('http://localhost:3100/api/v1/sms/appointments/schedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "patientId": patientIdController.text.trim(),
          "phone": phoneController.text.trim(),
          "doctor": doctorController.text.trim(),
          "date": formattedDate,
          "location": locationController.text.trim(),
          "patientName": patientNameController.text.trim(),
          "purpose": purposeController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        await _showSuccessDialog();
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.statusCode} - ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 20),
                Text('Appointment successfully created!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    patientIdController.clear();
    phoneController.clear();
    doctorController.clear();
    locationController.clear();
    patientNameController.clear();
    purposeController.clear();
    
    setState(() {
      selectedDate = null;
      selectedTime = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Appointment'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(patientIdController, "Patient ID", Icons.person, keyboardType: TextInputType.number),
              _buildTextField(patientNameController, "Patient Name", Icons.person),
              _buildTextField(phoneController, "Phone Number", Icons.phone, keyboardType: TextInputType.phone),
              _buildTextField(doctorController, "Doctor", Icons.medical_services),
              _buildTextField(locationController, "Medical Facility", Icons.location_on),
              _buildTextField(purposeController, "Purpose", Icons.description),
              
              const SizedBox(height: 16),
              
              // Date Picker Card
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    selectedDate == null 
                      ? "Select Date" 
                      : "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}",
                  ),
                  onTap: () => _selectDate(context),
                ),
              ),
              
              // Time Picker Card
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    selectedTime == null 
                      ? "Select Time" 
                      : "Time: ${selectedTime!.format(context)}",
                  ),
                  onTap: () => _selectTime(context),
                ),
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSubmitting ? null : _submitForm,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SCHEDULE APPOINTMENT",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {TextInputType? keyboardType}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
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
        validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  @override
  void dispose() {
    patientIdController.dispose();
    phoneController.dispose();
    doctorController.dispose();
    locationController.dispose();
    patientNameController.dispose();
    purposeController.dispose();
    super.dispose();
  }
}