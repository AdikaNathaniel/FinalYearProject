import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GetAnaemiaByIdPage extends StatefulWidget {
  const GetAnaemiaByIdPage({super.key});

  @override
  State<GetAnaemiaByIdPage> createState() => _GetAnaemiaByIdPageState();
}

class _GetAnaemiaByIdPageState extends State<GetAnaemiaByIdPage> {
  final TextEditingController _patientIdController = TextEditingController();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _fetchAndShowAnaemiaAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/anaemia-risk/assessments/patient/${_patientIdController.text.trim()}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null && data['result'].isNotEmpty) {
          final assessment = data['result'][0]; // Get the first assessment
          _showAssessmentDialog(assessment);
        } else {
          _showErrorDialog('No assessment found for this patient ID');
        }
      } else {
        _showErrorDialog('Assessment not found (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Error fetching assessment: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showAssessmentDialog(Map<String, dynamic> assessment) {
    final featureContributions = assessment['featureContributions'] ?? {};
    final probability = assessment['probability']?.toStringAsFixed(2) ?? 'N/A';
    final riskClass = assessment['riskClass']?.toString() ?? 'N/A';
    final rawScore = assessment['rawScore']?.toString() ?? 'N/A';
    final bmiValue = assessment['bmiValue']?.toStringAsFixed(2) ?? 'N/A';
    final createdAt = _formatDate(assessment['createdAt']?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(
          child: Text('Anaemia Risk Assessment'),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Risk Summary Card
              Card(
                color: _getRiskColor(riskClass),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'RISK LEVEL: $riskClass',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Probability: $probability%',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Raw Score: $rawScore',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Patient Details
              const Text(
                'Patient Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
              const Divider(),
              _buildDetailRow('Patient ID:', assessment['patientId']?.toString() ?? 'N/A'),
              _buildDetailRow('BMI Value:', bmiValue),
              _buildDetailRow('Assessment Date:', createdAt),
              const SizedBox(height: 16),
              
              // Feature Contributions
              const Text(
                'Feature Contributions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
              const Divider(),
              ..._buildFeatureContributions(featureContributions),
              const SizedBox(height: 16),
              
              // Input Values
              const Text(
                'Input Values',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
              const Divider(),
              _buildDetailRow('Excessive Vomiting:', _formatBoolean(assessment['excessiveVomiting'])),
              _buildDetailRow('Diarrhea:', _formatBoolean(assessment['diarrhea'])),
              _buildDetailRow('Heavy Menstrual Flow:', _formatBoolean(assessment['historyHeavyMenstrualFlow'])),
              _buildDetailRow('Infections:', _formatBoolean(assessment['infections'])),
              _buildDetailRow('Chronic Disease:', _formatBoolean(assessment['chronicDisease'])),
              _buildDetailRow('Family History:', _formatBoolean(assessment['familyHistory'])),
              _buildDetailRow('BMI Low:', _formatBoolean(assessment['bmiLow'])),
              _buildDetailRow('Short Interpregnancy:', _formatBoolean(assessment['shortInterpregnancyInterval'])),
              _buildDetailRow('Multiple Pregnancy:', _formatBoolean(assessment['multiplePregnancy'])),
              _buildDetailRow('Age ≤35:', _formatBoolean(assessment['age35OrLess'])),
              _buildDetailRow('Poverty:', _formatBoolean(assessment['poverty'])),
              _buildDetailRow('Lack of Healthcare:', _formatBoolean(assessment['lackOfAccessHealthcare'])),
              _buildDetailRow('Education:', _formatBoolean(assessment['education'])),
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
      _patientIdController.clear();
    });
  }

  Color _getRiskColor(String riskClass) {
    switch (riskClass.toLowerCase()) {
      case 'mild':
        return Colors.orange;
      case 'moderate':
        return Colors.deepOrange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatBoolean(dynamic value) {
    if (value == null) return 'No';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is num) return value > 0 ? 'Yes' : 'No';
    return value.toString();
  }

  List<Widget> _buildFeatureContributions(Map<String, dynamic> contributions) {
    final widgets = <Widget>[];
    contributions.forEach((key, value) {
      final contribution = value['contribution']?.toStringAsFixed(2) ?? '0.00';
      final input = value['input']?.toString() ?? '0';
      final weight = value['weight']?.toString() ?? '0';
      
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  _formatFeatureName(key),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  '$contribution%',
                  style: TextStyle(
                    fontSize: 12,
                    color: double.parse(contribution) > 0 ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Input: $input',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Text(
                  'Weight: $weight',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
      widgets.add(const Divider(height: 8));
    });
    return widgets;
  }

  String _formatFeatureName(String key) {
    // Convert camelCase to readable text
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .toLowerCase()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
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
        title: const Text('Assessment by ID'),
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
                        'Enter Patient ID',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _patientIdController,
                        decoration: const InputDecoration(
                          labelText: 'Patient ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          hintText: 'e.g., patient-910',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a patient ID' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _fetchAndShowAnaemiaAssessment,
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
                                  'Get Assessment',
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
    _patientIdController.dispose();
    super.dispose();
  }
}