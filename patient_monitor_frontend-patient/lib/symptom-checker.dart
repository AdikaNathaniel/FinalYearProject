import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SymptomForm extends StatefulWidget {
  @override
  _SymptomFormState createState() => _SymptomFormState();
}

class _SymptomFormState extends State<SymptomForm> {
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _headache;
  String? _dizziness;
  String? _vomiting;
  String? _painTopOfTommy;
  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() &&
        _headache != null &&
        _dizziness != null &&
        _vomiting != null &&
        _painTopOfTommy != null) {
      setState(() => _isSubmitting = true);
      
      try {
        final url = Uri.parse('http://localhost:3100/api/v1/symptoms');

        final data = {
          "patientId": _patientIdController.text,
          "username": _usernameController.text,
          "feelingHeadache": _headache,
          "feelingDizziness": _dizziness,
          "vomitingAndNausea": _vomiting,
          "painAtTopOfTommy": _painTopOfTommy,
        };

        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: json.encode(data),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submitted successfully!')),
          );
          // Clear form after successful submission
          _formKey.currentState?.reset();
          setState(() {
            _headache = null;
            _dizziness = null;
            _vomiting = null;
            _painTopOfTommy = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submission failed: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields before submitting')),
      );
    }
  }

  Widget _buildSymptomTile({
    required String label,
    required IconData icon,
    required String? groupValue,
    required void Function(String?) onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<String>(
                      value: 'yes',
                      groupValue: groupValue,
                      onChanged: onChanged,
                    ),
                    title: Text('Yes'),
                    onTap: () => onChanged('yes'),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<String>(
                      value: 'no',
                      groupValue: groupValue,
                      onChanged: onChanged,
                    ),
                    title: Text('No'),
                    onTap: () => onChanged('no'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Patient ID Field
                      TextFormField(
                        controller: _patientIdController,
                        decoration: InputDecoration(
                          labelText: 'Patient ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                          hintText: 'e.g. 001',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Please enter Patient ID' : null,
                      ),
                      SizedBox(height: 16),
                      // Patient Name Field
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Patient Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          hintText: 'e.g. Owusu Kwame',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Please enter Patient Name' : null,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              _buildSymptomTile(
                label: "Do you feel headache?",
                icon: Icons.headset,
                groupValue: _headache,
                onChanged: (value) => setState(() => _headache = value),
              ),
              SizedBox(height: 12),
              _buildSymptomTile(
                label: "Do you feel dizziness?",
                icon: Icons.autorenew,
                groupValue: _dizziness,
                onChanged: (value) => setState(() => _dizziness = value),
              ),
              SizedBox(height: 12),
              _buildSymptomTile(
                label: "Are you vomiting or feeling nausea?",
                icon: Icons.emoji_food_beverage,
                groupValue: _vomiting,
                onChanged: (value) => setState(() => _vomiting = value),
              ),
              SizedBox(height: 12),
              _buildSymptomTile(
                label: "Is there pain at the top of your tummy?",
                icon: Icons.medical_services,
                groupValue: _painTopOfTommy,
                onChanged: (value) => setState(() => _painTopOfTommy = value),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Symptoms',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}