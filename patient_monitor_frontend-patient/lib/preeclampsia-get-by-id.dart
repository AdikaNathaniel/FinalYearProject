import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GetRecordByIdPage extends StatefulWidget {
  @override
  _GetRecordByIdPageState createState() => _GetRecordByIdPageState();
}

class _GetRecordByIdPageState extends State<GetRecordByIdPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController idController = TextEditingController();
  Map<String, dynamic>? record;
  bool isLoading = false;

  Future<void> fetchRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      record = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/preeclampsia-vitals/${idController.text}'),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse.containsKey('result') && jsonResponse['result'] is List) {
          final List<dynamic> result = jsonResponse['result'];
          
          if (result.isNotEmpty) {
            _showRecordDialog(result[0]);
          } else {
            _showErrorDialog('No record found for this ID');
          }
        } else {
          _showErrorDialog('Invalid response format from server');
        }
      } else {
        _showErrorDialog('Failed to fetch record (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showRecordDialog(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(child: Text('Patient Record')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Patient ID:', record['patientId']?.toString() ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Systolic BP:', '${record['systolicBP']} mmHg'),
              const Divider(),
              _buildDetailRow('Diastolic BP:', '${record['diastolicBP']} mmHg'),
              const Divider(),
              _buildDetailRow('Protein in Urine:', '${record['proteinUrine']} mg/dL'),
              const Divider(),
              _buildDetailRow('Mean Arterial Pressure:', '${record['map']?.toStringAsFixed(1) ?? 'N/A'} mmHg'),
              const Divider(),
              _buildDetailRow('Status:', record['status']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'UNKNOWN'),
              const Divider(),
              _buildDetailRow('Created:', _formatDate(record['createdAt']?.toString())),
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
      idController.clear();
    });
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Record by Patient ID'),
        backgroundColor: const Color(0xFF2196F3),
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
                        Icons.search,
                        size: 48,
                        color: Color(0xFF2196F3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Enter Patient ID',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: idController,
                        decoration: const InputDecoration(
                          labelText: 'Patient ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          hintText: 'Enter patient ID',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a Patient ID' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : fetchRecord,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Search Record',
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
    idController.dispose();
    super.dispose();
  }
}