import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FindSymptomByNamePage extends StatefulWidget {
  const FindSymptomByNamePage({super.key});

  @override
  State<FindSymptomByNamePage> createState() => _FindSymptomByNamePageState();
}

class _FindSymptomByNamePageState extends State<FindSymptomByNamePage> {
  final TextEditingController _nameController = TextEditingController();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _fetchAndShowSymptom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/symptoms/${_nameController.text.trim()}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Access the nested symptom data correctly
        final symptom = data['result']['symptom'] ?? {};
        _showSymptomDialog(symptom);
      } else {
        _showErrorDialog('Symptom record not found (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Error fetching symptom: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSymptomDialog(Map<String, dynamic> symptom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: const Text('Symptom Details'),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // User information
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    symptom['username']?.toString() ?? 'N/A',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(),
              
              // Symptoms
              Row(
                children: [
                  const Icon(Icons.headphones, color: Colors.red),
                  const SizedBox(width: 8),
                  Text("Headache: ${symptom['feelingHeadache']?.toString() ?? 'N/A'}"),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(Icons.sick, color: Colors.green),
                  const SizedBox(width: 8),
                  Text("Vomiting/Nausea: ${symptom['vomitingAndNausea']?.toString() ?? 'N/A'}"),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(Icons.pan_tool_alt, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text("Pain at Top of Tummy: ${symptom['painAtTopOfTommy']?.toString() ?? 'N/A'}"),
                ],
              ),
              const SizedBox(height: 8),
              
              // Creation date
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text("Created: ${_formatDateTime(symptom['createdAt']?.toString())}"),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    ).then((_) {
      // Clear the field after dialog is closed
      _nameController.clear();
    });
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return date.toString().split('.')[0];
    } catch (e) {
      return dateString;
    }
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
        title: const Text('Find Symptom by Name'),
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
                        Icons.medical_services,
                        size: 48,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Enter Patient Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Patient Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          hintText: 'e.g., Michelle Owusu',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _fetchAndShowSymptom,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Find Symptom',
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
    _nameController.dispose();
    super.dispose();
  }
}