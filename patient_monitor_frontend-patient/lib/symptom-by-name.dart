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
        
        // Debug print to see the response
        print('API Response: ${response.body}');
        
        if (data['result'] == null || data['result'] is! List || data['result'].isEmpty) {
          _showErrorDialog('No symptom records found');
          return;
        }

        // Get the first symptom record (assuming we want the most recent)
        final symptom = data['result'][0] as Map<String, dynamic>;
        _showSymptomDialog(symptom);
      } else {
        _showErrorDialog('Symptom record not found (Status: ${response.statusCode})');
      }
    } on http.ClientException catch (e) {
      _showErrorDialog('Network error: ${e.message}');
    } on FormatException catch (e) {
      _showErrorDialog('Data format error: ${e.message}');
    } catch (e) {
      _showErrorDialog('Unexpected error: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSymptomDialog(Map<String, dynamic> symptom) {
    // Helper function to display yes/no values more clearly
    String formatYesNo(String? value) {
      if (value == null) return 'Not specified';
      return value.toLowerCase() == 'yes' ? 'Yes' : 'No';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(child: Text('Symptom Details')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Patient Information
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.purple, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    symptom['username']?.toString() ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              
              // Symptoms Section
              const Text('Symptoms:', style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue,
              )),
              const SizedBox(height: 10),
              
              _buildSymptomRow(
                Icons.headphones, 
                Colors.red, 
                'Headache:', 
                formatYesNo(symptom['feelingHeadache']),
              ),
              const SizedBox(height: 8),
              
              _buildSymptomRow(
                Icons.air, 
                Colors.orange, 
                'Dizziness:', 
                formatYesNo(symptom['feelingDizziness']),
              ),
              const SizedBox(height: 8),
              
              _buildSymptomRow(
                Icons.sick, 
                Colors.green, 
                'Vomiting/Nausea:', 
                formatYesNo(symptom['vomitingAndNausea']),
              ),
              const SizedBox(height: 8),
              
              _buildSymptomRow(
                Icons.pan_tool_alt, 
                Colors.blue, 
                'Pain at Top of Tummy:', 
                formatYesNo(symptom['painAtTopOfTommy']),
              ),
              const Divider(height: 20),
              
              // Dates Section
              const Text('Record Date:', style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue,
              )),
              const SizedBox(height: 10),
              
              _buildDateRow(
                Icons.calendar_today,
                'Created:',
                _formatDateTime(symptom['createdAt']),
              ),
              const SizedBox(height: 8),
              
            //   _buildDateRow(
            //     Icons.update,
            //     'Last Updated:',
            //     _formatDateTime(symptom['updatedAt']),
            //   ),
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
      _nameController.clear();
    });
  }

  Widget _buildSymptomRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 5),
        Text(value),
      ],
    );
  }

  Widget _buildDateRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700], size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 5),
        Text(value),
      ],
    );
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
        title: const Text('Find Patient Symptoms'),
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
                                  'Find Symptoms',
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