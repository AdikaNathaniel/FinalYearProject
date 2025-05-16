import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreatePrescriptionPage extends StatefulWidget {
  @override
  _CreatePrescriptionPageState createState() => _CreatePrescriptionPageState();
}

class _CreatePrescriptionPageState extends State<CreatePrescriptionPage> {
  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController drugNameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController routeOfAdministrationController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text(
            'Create Prescription',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.red], // Gradient background
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildTextField(Icons.person, "Patient Name", patientNameController),
              buildTextField(Icons.medication, "Drug Name", drugNameController),
              buildTextField(Icons.local_pharmacy, "Dosage", dosageController),
              buildTextField(Icons.local_hospital, "Route of Administration(Oral/Topical/Intravenous)", routeOfAdministrationController),
              buildTextField(Icons.access_time, "Frequency Per Day", frequencyController),
              buildTextField(Icons.calendar_today, "Duration", durationController),
              buildTextField(Icons.date_range, "Start Date (YYYY-MM-DD)", startDateController),
              buildTextField(Icons.date_range, "End Date (YYYY-MM-DD)", endDateController),
              buildTextField(Icons.confirmation_number, "Quantity", quantityController),
              buildTextField(Icons.info_outline, "Reason", reasonController),
              const SizedBox(height: 20),
              buildTextField(Icons.info_outline, "Notes(Referral Information)", notesController),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, // Make the button full width
                child: ElevatedButton(
                  onPressed: submitPrescription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Submit Prescription",
                    style: TextStyle(fontSize: 16, color: Colors.white), // Set text color to white
                    textAlign: TextAlign.center, // Center align text
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(IconData icon, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white), // Set text color to white
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white), // Change label color to white
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1), // Background color of the input field
        ),
      ),
    );
  }

  Future<void> submitPrescription() async {
    final response = await http.post(
      Uri.parse('http://localhost:3100/api/v1/prescriptions'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'patient_name': patientNameController.text,
        'drug_name': drugNameController.text,
        'dosage': dosageController.text,
        'route_of_administration': routeOfAdministrationController.text,
        'frequency': frequencyController.text,
        'duration': durationController.text,
        'start_date': startDateController.text,
        'end_date': endDateController.text,
        'quantity': int.tryParse(quantityController.text) ?? 0,
        'reason': reasonController.text,
        'notes': notesController.text,
      }),
    );

    if (response.statusCode == 201) {
      // Successfully submitted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prescription submitted successfully!')),
      );
      // Clear fields after submission
      clearFields();
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit prescription')),
      );
    }
  }

  void clearFields() {
    patientNameController.clear();
    drugNameController.clear();
    dosageController.clear();
    routeOfAdministrationController.clear();
    frequencyController.clear();
    durationController.clear();
    startDateController.clear();
    endDateController.clear();
    quantityController.clear();
    reasonController.clear();
    notesController.clear();
  }
}