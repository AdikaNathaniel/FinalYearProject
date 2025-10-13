import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RiskAssessmentPage extends StatefulWidget {
  const RiskAssessmentPage({super.key});

  @override
  State<RiskAssessmentPage> createState() => _RiskAssessmentPageState();
}

class _RiskAssessmentPageState extends State<RiskAssessmentPage> {
  final TextEditingController _patientIdController = TextEditingController();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _fetchRiskAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/anaemia-risk/assessments?patientId=${_patientIdController.text.trim()}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null && data['result'].isNotEmpty) {
          _showRiskAssessmentDialog(data['result'][0]);
        } else {
          _showErrorDialog('No risk assessment found for this patient');
        }
      } else {
        _showErrorDialog('Failed to fetch risk assessment (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Error fetching risk assessment: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showRiskAssessmentDialog(Map<String, dynamic> result) {
    final riskClass = result["riskClass"] ?? "UNKNOWN";
    final riskColor = riskClass == "HIGH RISK" ? Colors.redAccent : Colors.green;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(
          child: Text('Risk Assessment Result'),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Icon(
                  Icons.health_and_safety,
                  size: 60,
                  color: riskColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Patient ID:', result["patientId"]?.toString() ?? 'N/A'),
              const Divider(),
              _buildDetailRow(
                'Risk Level:',
                riskClass,
                valueStyle: TextStyle(
                  color: riskColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              _buildDetailRow(
                'Probability:',
                (result["calculatedRisk"] as double?)?.toStringAsFixed(3) ?? 'N/A',
              ),
              const Divider(),
              _buildDetailRow(
                'Date:',
                _formatDate(result["createdAt"]?.toString()),
              ),
              const SizedBox(height: 16),
              const Text(
                'Risk Factors:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildChip("Vomiting", result["excessiveVomiting"]),
                  _buildChip("Diarrhea", result["diarrhea"]),
                  _buildChip("Heavy Flow", result["historyHeavyMenstrualFlow"]),
                  _buildChip("Infections", result["infections"]),
                  _buildChip("Chronic Disease", result["chronicDisease"]),
                  _buildChip("Multiple Pregnancy", result["multiplePregnancy"]),
                  _buildChip("Poverty", result["poverty"]),
                  _buildChip("No Healthcare", result["lackOfAccessHealthcare"]),
                  _buildChip("Low Education", result["education"]),
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
      _patientIdController.clear();
    });
  }

  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
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
              style: valueStyle ?? const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool value) {
    return Chip(
      avatar: Icon(
        value ? Icons.check_circle : Icons.cancel,
        color: value ? Colors.green : Colors.red,
        size: 18,
      ),
      label: Text(label),
      backgroundColor: value ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
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
        title: const Text('Anaemia Risk Assessment'),
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
                        Icons.health_and_safety,
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
                          prefixIcon: Icon(Icons.badge),
                          hintText: 'e.g., PAT12345',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a patient ID' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _fetchRiskAssessment,
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
                                  'Check Risk',
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