import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateAppointmentStatusPage extends StatefulWidget {
  const UpdateAppointmentStatusPage({super.key});

  @override
  State<UpdateAppointmentStatusPage> createState() => _UpdateAppointmentStatusPageState();
}

class _UpdateAppointmentStatusPageState extends State<UpdateAppointmentStatusPage> {
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _appointmentIdController = TextEditingController();
  String _selectedStatus = 'Pending';
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // List of available status options
  final List<String> _statusOptions = ['Canceled', 'Pending', 'Confirmed'];

  Future<void> _updateAppointmentStatus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.patch(
        Uri.parse(
          'http://localhost:3100/api/v1/doctors/${Uri.encodeComponent(_doctorNameController.text.trim())}/appointments/${_appointmentIdController.text.trim()}/status',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': _selectedStatus.toLowerCase()}),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog('Status updated successfully!');
      } else {
        final errorData = json.decode(response.body);
        _showErrorDialog(
          errorData['message'] ?? 'Failed to update status (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      _showErrorDialog('Error updating status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Clear the form after successful update
              _doctorNameController.clear();
              _appointmentIdController.clear();
              setState(() => _selectedStatus = 'Pending');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Appointment Status'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Update Appointment Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _doctorNameController,
                        decoration: const InputDecoration(
                          labelText: 'Doctor Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          hintText: 'e.g., Frank Amegah',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter doctor name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _appointmentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Appointment ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                          hintText: 'Enter appointment ID',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter appointment ID' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info),
                        ),
                        items: _statusOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedStatus = newValue!;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a status' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateAppointmentStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Update Status',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _appointmentIdController.dispose();
    super.dispose();
  }
}