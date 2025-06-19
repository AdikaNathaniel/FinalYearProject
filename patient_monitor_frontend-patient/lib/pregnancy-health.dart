import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PregnancyHealthForm extends StatefulWidget {
  @override
  _PregnancyHealthFormState createState() => _PregnancyHealthFormState();
}

class _PregnancyHealthFormState extends State<PregnancyHealthForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text input fields
  final TextEditingController parityController = TextEditingController();
  final TextEditingController gravidaController = TextEditingController();
  final TextEditingController gestationalAgeController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  // Dropdown selections
  String? hasDiabetes;
  String? hasAnemia;
  String? hasPreeclampsia;
  String? hasGestationalDiabetes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pregnancy Health Information",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 _buildTextField(nameController, "What is your name?", "Enter Your Name"),
                _buildTextField(parityController, "How many times have you given birth?", "Enter number of births"),
                _buildTextField(gravidaController, "How many times have you been pregnant?", "Enter number of pregnancies"),
                _buildTextField(gestationalAgeController, "How many weeks pregnant are you?", "Enter weeks (e.g. 20)"),
                _buildTextField(ageController, "How old are you?", "Enter your age (years)"),
                _buildDropdownField("Have you ever had diabetes?", (value) => setState(() => hasDiabetes = value)),
                _buildDropdownField("Have you ever had anemia?", (value) => setState(() => hasAnemia = value)),
                _buildDropdownField("Have you ever had preeclampsia?", (value) => setState(() => hasPreeclampsia = value)),
                _buildDropdownField("Have you ever had gestational diabetes?", (value) => setState(() => hasGestationalDiabetes = value)),

                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _sendData(); // Call the function to send data
                      }
                    },
                    child: Text("Save Information"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.pinkAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to send data to the API
  Future<void> _sendData() async {
    final url = Uri.parse('http://localhost:3100/api/v1/health');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'parity': int.parse(parityController.text),
        'gravida': int.parse(gravidaController.text),
        'gestationalAge': int.parse(gestationalAgeController.text),
        'age': int.parse(ageController.text),
        'hasDiabetes': hasDiabetes,
        'hasAnemia': hasAnemia,
        'hasPreeclampsia': hasPreeclampsia,
        'hasGestationalDiabetes': hasGestationalDiabetes,
        'name': int.parse(nameController.text),
      }),
    );

    if (response.statusCode == 201) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Information saved successfully!")),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save information. Please try again.")),
      );
    }
  }

  // Helper function to build text fields
  Widget _buildTextField(TextEditingController controller, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.pink[50],
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "This field is required";
          }
          return null;
        },
      ),
    );
  }

  // Helper function to build dropdown fields
  Widget _buildDropdownField(String label, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: null,
            items: ["Yes", "No"].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.pink[50],
            ),
            validator: (value) {
              if (value == null) {
                return "Please select an option";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}