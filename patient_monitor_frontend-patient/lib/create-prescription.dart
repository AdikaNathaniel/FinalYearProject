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

  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Prescription'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(patientNameController, "Patient Name", Icons.person),
            _buildTextField(drugNameController, "Drug Name", Icons.medication),
            _buildTextField(dosageController, "Dosage", Icons.local_pharmacy),
            _buildTextField(routeOfAdministrationController, "Route of Administration (Oral/Topical/Intravenous)", Icons.local_hospital),
            _buildTextField(frequencyController, "Frequency Per Day", Icons.access_time),
            _buildTextField(durationController, "Duration", Icons.calendar_today),
            _buildTextField(startDateController, "Start Date (YYYY-MM-DD)", Icons.date_range),
            _buildTextField(endDateController, "End Date (YYYY-MM-DD)", Icons.date_range),
            _buildTextField(quantityController, "Quantity", Icons.confirmation_number, keyboardType: TextInputType.number),
            _buildTextField(reasonController, "Reason", Icons.info_outline),
            _buildTextField(notesController, "Notes (Referral Information)", Icons.description),
            
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
              onPressed: isSubmitting ? null : submitPrescription,
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Submit Prescription",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
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
      ),
    );
  }

  Future<void> submitPrescription() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/prescriptions'),
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
          const SnackBar(content: Text('Prescription submitted successfully!')),
        );
        // Clear fields after submission
        clearFields();
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit prescription')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
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