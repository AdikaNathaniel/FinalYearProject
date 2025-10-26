import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

import 'view-appointment.dart';
import 'create_cancel-appointment.dart';
import 'login_page.dart';
// import 'doctor-chat.dart';
import 'set_profile.dart';
import 'support-create.dart';
import 'doctor-profile.dart';
import 'symptom-list.dart';
import 'symptom-by-name.dart';
import 'appointment-schedule-by-medic.dart';
import 'medic-appointment-details.dart';
import 'medic-appointment-status-details.dart';
import 'appointment-status-update.dart';
import 'prescriptions-home.dart';
import 'appointments-home.dart';
import 'preeclampsia-home.dart';
import 'map.dart';
import 'preeclampsia-live.dart';
import 'glucose-monitor.dart';
import 'vitals-input.dart';
import 'hardware-live-data.dart';
import 'anemia-home.dart';
import 'vitals-health-data-list.dart';
import 'vitals-health-data-get-specific-user.dart';
import 'csv.dart';
import 'chart-data.dart';
import 'medic-chat.dart';

class AWOPASummarisedPage extends StatefulWidget {
  final String userEmail;

  const AWOPASummarisedPage({super.key, required this.userEmail});

  @override
  State<AWOPASummarisedPage> createState() => _AWOPASummarisedPageState();
}

class _AWOPASummarisedPageState extends State<AWOPASummarisedPage> {
  final TextEditingController _patientIdController = TextEditingController();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _currentPatientData;

  Future<Map<String, dynamic>> _fetchPatientData() async {
    final Map<String, dynamic> results = {};

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/heltec-live-vitals/latest')),
        http.get(Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/heltec-live-vitals/latest')),
        http.get(Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/symptoms/search?query=${_patientIdController.text.trim()}')),
        http.get(Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/anaemia-risk/assessments/patient/${_patientIdController.text.trim()}')),
      ]);

      if (responses[0].statusCode == 200) {
        final data = json.decode(responses[0].body);
        results['vitals'] = data['result'];
      }

      if (responses[1].statusCode == 200) {
        final data = json.decode(responses[1].body);
        results['preeclampsia'] = data['result'];
      }

      if (responses[2].statusCode == 200) {
        final data = json.decode(responses[2].body);
        results['symptoms'] = data['result'] != null && data['result'].isNotEmpty
            ? data['result'][0]
            : null;
      }

      if (responses[3].statusCode == 200) {
        final data = json.decode(responses[3].body);
        results['anaemia'] = data['result'] != null && data['result'].isNotEmpty
            ? data['result'][0]
            : null;
      }

      return results;
    } catch (e) {
      throw Exception('Failed to fetch patient data: $e');
    }
  }

  // Calculate MAP using the formula: (systolicBP + 2 * diastolicBP) / 3
  double _calculateMAP(double systolicBP, double diastolicBP) {
    return (systolicBP + 2 * diastolicBP) / 3;
  }

  // Determine preeclampsia status based on MAP and proteinUrine
  String _determineStatus(double map, int proteinUrine) {
    if (proteinUrine < 2) {
      return 'no_preeclampsia';
    } else if (map >= 130) {
      return 'severe preeclampsia';
    } else if (map >= 125 && map <= 129) {
      return 'moderate preeclampsia';
    } else if (map >= 114 && map <= 124) {
      return 'mild preeclampsia';
    } else {
      return 'no_preeclampsia';
    }
  }

  Future<void> _fetchAndShowPatientSummary() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final patientData = await _fetchPatientData();
      _currentPatientData = patientData;
      _showPatientSummaryDialog(patientData);
    } catch (e) {
      _showErrorDialog('Error fetching patient data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _logout() async {
    final response = await http.put(
      Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/users/logout'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        _showSuccessDialog("Logout successfully");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        _showSnackbar("Logout failed: ${responseData['message']}");
      }
    } else {
      _showSnackbar("Logout failed: Server error");
    }
  }

  void _showPatientSummaryDialog(Map<String, dynamic> patientData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services, color: Colors.blue, size: 24),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'PATIENT MEDICAL SUMMARY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Patient ID
                  Text(
                    'Patient ID: ${_patientIdController.text.trim()}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tabs for different data sections
                  SizedBox(
                    height: 500,
                    child: DefaultTabController(
                      length: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: const TabBar(
                              isScrollable: true,
                              labelStyle: TextStyle(fontSize: 12),
                              tabs: [
                                Tab(text: 'Vitals'),
                                Tab(text: 'Preeclampsia'),
                                Tab(text: 'Symptoms'),
                                Tab(text: 'Anaemia'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildVitalsTab(patientData['vitals']),
                                _buildPreeclampsiaTab(patientData['preeclampsia']),
                                _buildSymptomsTab(patientData['symptoms']),
                                _buildAnaemiaTab(patientData['anaemia']),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                      ElevatedButton(
                        onPressed: () => _generateAndDownloadPdf(patientData),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Download PDF'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      _patientIdController.clear();
    });
  }

  Widget _buildVitalsTab(dynamic vitalsData) {
    if (vitalsData == null) {
      return const Center(child: Text('No vitals data available'));
    }
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDataCard(
            'Core Vitals',
            [
              _buildDataRow('Glucose', '${vitalsData['glucose']} mg/dL', Icons.monitor_heart),
              _buildDataRow('Heart Rate', '${vitalsData['heartRate']} bpm', Icons.favorite),
              _buildDataRow('SpO2', '${vitalsData['spo2']}%', Icons.air),
              _buildDataRow('Body Temp', '${vitalsData['bodyTemp']}°C', Icons.thermostat),
            ],
          ),
          _buildDataCard(
            'Blood Pressure',
            [
              _buildDataRow('Systolic', '${vitalsData['systolicBP']} mmHg', Icons.speed),
              _buildDataRow('Diastolic', '${vitalsData['diastolicBP']} mmHg', Icons.speed),
            ],
          ),
          _buildDataCard(
            'Other Metrics',
            [
              _buildDataRow('Skin Temp', '${vitalsData['skinTemp']}°C', Icons.thermostat_auto)
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreeclampsiaTab(dynamic preeclampsiaData) {
    if (preeclampsiaData == null) {
      return const Center(child: Text('No preeclampsia data available'));
    }
    
    // Extract values from the live vitals data
    final systolicBP = preeclampsiaData['systolicBP'] ?? 0.0;
    final diastolicBP = preeclampsiaData['diastolicBP'] ?? 0.0;
    final proteinUrine = preeclampsiaData['proteinLevel'] ?? 0;
    
    // Calculate MAP and status using the formulas
    final double map = _calculateMAP(systolicBP, diastolicBP);
    final String status = _determineStatus(map, proteinUrine);
    
    Color statusColor = Colors.grey;
    
    if (status == 'no_preeclampsia') {
      statusColor = Colors.green;
    } else if (status.contains('preeclampsia')) {
      statusColor = Colors.orange;
    }
    
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            color: statusColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.warning, size: 40, color: Colors.orange),
                  const SizedBox(height: 10),
                  Text(
                    'Status: ${status.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          _buildDataCard(
            'Blood Pressure',
            [
              _buildDataRow('Systolic', '${systolicBP.toStringAsFixed(1)} mmHg', Icons.speed),
              _buildDataRow('Diastolic', '${diastolicBP.toStringAsFixed(1)} mmHg', Icons.speed),
              _buildDataRow('MAP', '${map.toStringAsFixed(1)} mmHg', Icons.speed),
            ],
          ),
          _buildDataCard(
            'Urine Analysis',
            [
              _buildDataRow('Protein in Urine', '$proteinUrine', Icons.science),
            ],
          ),
          if (preeclampsiaData['createdAt'] != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Last updated: ${_formatDate(preeclampsiaData['createdAt'])}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSymptomsTab(dynamic symptomsData) {
    if (symptomsData == null) {
      return const Center(child: Text('No symptoms data available'));
    }
    
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.sick, size: 40, color: Colors.purple),
                  const SizedBox(height: 10),
                  Text(
                    'Patient: ${symptomsData['username'] ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          _buildDataCard(
            'Reported Symptoms',
            [
              _buildSymptomRow('Headache', symptomsData['feelingHeadache'], Icons.headset),
              _buildSymptomRow('Dizziness', symptomsData['feelingDizziness'], Icons.airline_seat_legroom_reduced),
              _buildSymptomRow('Nausea/Vomiting', symptomsData['vomitingAndNausea'], Icons.sick),
              _buildSymptomRow('Abdominal Pain', symptomsData['painAtTopOfTommy'], Icons.personal_injury),
            ],
          ),
          if (symptomsData['createdAt'] != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Reported on: ${_formatDate(symptomsData['createdAt'])}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnaemiaTab(dynamic anaemiaData) {
    if (anaemiaData == null) {
      return const Center(child: Text('No anaemia assessment available'));
    }
    
    final riskClass = anaemiaData['riskClass'] ?? 'Unknown';
    final probability = anaemiaData['probability']?.toStringAsFixed(1) ?? 'N/A';
    
    Color riskColor = Colors.grey;
    IconData riskIcon = Icons.help;
    
    switch (riskClass.toLowerCase()) {
      case 'low':
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
        break;
      case 'moderate':
        riskColor = Colors.orange;
        riskIcon = Icons.warning;
        break;
      case 'high':
        riskColor = Colors.red;
        riskIcon = Icons.error;
        break;
    }
    
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            color: riskColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(riskIcon, size: 40, color: riskColor),
                  const SizedBox(height: 10),
                  Text(
                    'Risk Level: $riskClass',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Probability: $probability%',
                    style: TextStyle(
                      fontSize: 14,
                      color: riskColor,
                    ),
                  ),
                  Text(
                    'Raw Score: ${anaemiaData['rawScore'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          _buildDataCard(
            'Key Metrics',
            [
              _buildDataRow('BMI Value', anaemiaData['bmiValue']?.toStringAsFixed(1) ?? 'N/A', Icons.monitor_weight),
              _buildDataRow('Age ≤35', _formatBoolean(anaemiaData['age35OrLess']), Icons.cake),
            ],
          ),
          
          _buildDataCard(
            'Risk Factors',
            [
              _buildSymptomRow('Excessive Vomiting', anaemiaData['excessiveVomiting'], Icons.sick),
              _buildSymptomRow('Diarrhea', anaemiaData['diarrhea'], Icons.wc),
              _buildSymptomRow('Heavy Menstrual Flow', anaemiaData['historyHeavyMenstrualFlow'], Icons.bloodtype),
              _buildSymptomRow('Infections', anaemiaData['infections'], Icons.coronavirus),
              _buildSymptomRow('Chronic Disease', anaemiaData['chronicDisease'], Icons.medical_services),
              _buildSymptomRow('Family History', anaemiaData['familyHistory'], Icons.family_restroom),
              _buildSymptomRow('Low BMI', anaemiaData['bmiLow'], Icons.monitor_weight),
              _buildSymptomRow('Short Interpregnancy Interval', anaemiaData['shortInterpregnancyInterval'], Icons.calendar_today),
              _buildSymptomRow('Multiple Pregnancy', anaemiaData['multiplePregnancy'], Icons.child_care),
              _buildSymptomRow('Poverty', anaemiaData['poverty'], Icons.money_off),
              _buildSymptomRow('Lack of Healthcare Access', anaemiaData['lackOfAccessHealthcare'], Icons.local_hospital),
              _buildSymptomRow('Low Education', anaemiaData['education'], Icons.school),
            ],
          ),
          
          // Feature Contributions Section - Improved Layout
          if (anaemiaData['featureContributions'] != null)
          _buildFeatureContributionsCard(anaemiaData['featureContributions']),
          
          if (anaemiaData['createdAt'] != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Assessed on: ${_formatDate(anaemiaData['createdAt'])}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureContributionsCard(dynamic featureContributions) {
    if (featureContributions == null) {
      return _buildDataCard('Feature Contributions', [
        const Text('No feature contributions data')
      ]);
    }
    
    final contributions = featureContributions as Map<String, dynamic>;
    final List<Widget> contributionWidgets = [];
    
    contributions.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final input = value['input']?.toString() ?? 'N/A';
        final weight = value['weight']?.toString() ?? 'N/A';
        final contribution = value['contribution']?.toStringAsFixed(2) ?? 'N/A';
        
        contributionWidgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatFeatureName(key),
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Input: $input',
                        style: const TextStyle(fontSize: 10, color: Colors.blue),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Weight: $weight',
                        style: const TextStyle(fontSize: 10, color: Colors.green),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Contribution: $contribution',
                        style: const TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    });
    
    return _buildDataCard('Feature Contributions', contributionWidgets);
  }

  String _formatFeatureName(String key) {
    String result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (Match m) => ' ${m[1]}',
    );
    
    result = result.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
    
    return result;
  }

  Widget _buildDataCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomRow(String label, dynamic value, IconData icon) {
    final isPresent = _isTrue(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isPresent ? Colors.red : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                color: isPresent ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  bool _isTrue(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value > 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  String _formatBoolean(dynamic value) {
    return _isTrue(value) ? 'Yes' : 'No';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - HH:mm').format(date);
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

  // PDF Generation and Download Functionality
  Future<void> _generateAndDownloadPdf(Map<String, dynamic> patientData) async {
    setState(() => isLoading = true);
    
    try {
      final pdfBytes = await _generatePdfBytes(patientData);
      await _saveAndOpenPdf(pdfBytes);
    } catch (e) {
      _showErrorDialog('Error generating PDF: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<Uint8List> _generatePdfBytes(Map<String, dynamic> patientData) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMMM d, yyyy - h:mm a');
    final formattedDate = dateFormat.format(DateTime.now());
    final patientId = _patientIdController.text.trim();

    final normalTextStyle = pw.TextStyle(fontSize: 10);
    final boldTextStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    final titleTextStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800);
    final headerTextStyle = pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey300)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PATIENT MEDICAL SUMMARY',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      formattedDate,
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Text(
                    'Patient ID: $patientId',
                    style: headerTextStyle,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Vitals', style: titleTextStyle),
                  pw.SizedBox(height: 8),
                  ..._buildPdfVitalsSection(patientData['vitals'], normalTextStyle, boldTextStyle),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Preeclampsia Assessment', style: titleTextStyle),
                  pw.SizedBox(height: 8),
                  ..._buildPdfPreeclampsiaSection(patientData['preeclampsia'], normalTextStyle, boldTextStyle),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Symptoms', style: titleTextStyle),
                  pw.SizedBox(height: 8),
                  ..._buildPdfSymptomsSection(patientData['symptoms'], normalTextStyle, boldTextStyle),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Anaemia Risk Assessment', style: titleTextStyle),
                  pw.SizedBox(height: 8),
                  ..._buildPdfAnaemiaSection(patientData['anaemia'], normalTextStyle, boldTextStyle),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  List<pw.Widget> _buildPdfVitalsSection(dynamic vitalsData, pw.TextStyle normalTextStyle, pw.TextStyle boldTextStyle) {
    if (vitalsData == null) {
      return [pw.Text('No vitals data available', style: normalTextStyle)];
    }
    
    return [
      pw.Text('Core Vitals:', style: boldTextStyle),
      pw.SizedBox(height: 6),
      pw.Row(children: [pw.Text('Glucose: ', style: boldTextStyle), pw.Text('${vitalsData['glucose']} mg/dL', style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Heart Rate: ', style: boldTextStyle), pw.Text('${vitalsData['heartRate']} bpm', style: normalTextStyle)]),
      pw.Row(children: [pw.Text('SpO2: ', style: boldTextStyle), pw.Text('${vitalsData['spo2']}%', style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Body Temp: ', style: boldTextStyle), pw.Text('${vitalsData['bodyTemp']}°C', style: normalTextStyle)]),
      pw.SizedBox(height: 6),
      pw.Text('Blood Pressure:', style: boldTextStyle),
      pw.SizedBox(height: 6),
      pw.Row(children: [pw.Text('Systolic: ', style: boldTextStyle), pw.Text('${vitalsData['systolicBP']} mmHg', style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Diastolic: ', style: boldTextStyle), pw.Text('${vitalsData['diastolicBP']} mmHg', style: normalTextStyle)]),
      pw.SizedBox(height: 6),
      pw.Text('Other Metrics:', style: boldTextStyle),
      pw.SizedBox(height: 6),
      pw.Row(children: [pw.Text('Skin Temp: ', style: boldTextStyle), pw.Text('${vitalsData['skinTemp']}°C', style: normalTextStyle)])
    ];
  }

  List<pw.Widget> _buildPdfPreeclampsiaSection(dynamic preeclampsiaData, pw.TextStyle normalTextStyle, pw.TextStyle boldTextStyle) {
    if (preeclampsiaData == null) {
      return [pw.Text('No preeclampsia data available', style: normalTextStyle)];
    }
    
    // Calculate MAP and status for PDF as well
    final systolicBP = preeclampsiaData['systolicBP'] ?? 0.0;
    final diastolicBP = preeclampsiaData['diastolicBP'] ?? 0.0;
    final proteinUrine = preeclampsiaData['proteinLevel'] ?? 0;
    final double map = _calculateMAP(systolicBP, diastolicBP);
    final String status = _determineStatus(map, proteinUrine);
    
    return [
      pw.Text('Status: $status', style: boldTextStyle.copyWith(color: PdfColors.orange)),
      pw.SizedBox(height: 6),
      pw.Text('Blood Pressure:', style: boldTextStyle),
      pw.SizedBox(height: 6),
      pw.Row(children: [pw.Text('Systolic: ', style: boldTextStyle), pw.Text('${systolicBP.toStringAsFixed(1)} mmHg', style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Diastolic: ', style: boldTextStyle), pw.Text('${diastolicBP.toStringAsFixed(1)} mmHg', style: normalTextStyle)]),
      pw.Row(children: [pw.Text('MAP: ', style: boldTextStyle), pw.Text('${map.toStringAsFixed(1)} mmHg', style: normalTextStyle)]),
      pw.SizedBox(height: 6),
      pw.Text('Urine Analysis:', style: boldTextStyle),
      pw.SizedBox(height: 6),
      pw.Row(children: [pw.Text('Protein in Urine: ', style: boldTextStyle), pw.Text('$proteinUrine', style: normalTextStyle)]),
      if (preeclampsiaData['createdAt'] != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Text('Last updated: ${_formatDate(preeclampsiaData['createdAt'])}', style: normalTextStyle.copyWith(color: PdfColors.grey)),
        ),
    ];
  }

  List<pw.Widget> _buildPdfSymptomsSection(dynamic symptomsData, pw.TextStyle normalTextStyle, pw.TextStyle boldTextStyle) {
    if (symptomsData == null) {
      return [pw.Text('No symptoms data available', style: normalTextStyle)];
    }
    
    return [
      pw.Text('Patient: ${symptomsData['username'] ?? 'Unknown'}', style: boldTextStyle),
      pw.SizedBox(height: 6),
      pw.Text('Reported Symptoms:', style: boldTextStyle),
      pw.SizedBox(height: 6),
      pw.Row(children: [pw.Text('Headache: ', style: boldTextStyle), pw.Text(_formatBoolean(symptomsData['feelingHeadache']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Dizziness: ', style: boldTextStyle), pw.Text(_formatBoolean(symptomsData['feelingDizziness']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Nausea/Vomiting: ', style: boldTextStyle), pw.Text(_formatBoolean(symptomsData['vomitingAndNausea']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Abdominal Pain: ', style: boldTextStyle), pw.Text(_formatBoolean(symptomsData['painAtTopOfTommy']), style: normalTextStyle)]),
      if (symptomsData['createdAt'] != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Text('Reported on: ${_formatDate(symptomsData['createdAt'])}', style: normalTextStyle.copyWith(color: PdfColors.grey)),
        ),
    ];
  }

  List<pw.Widget> _buildPdfAnaemiaSection(dynamic anaemiaData, pw.TextStyle normalTextStyle, pw.TextStyle boldTextStyle) {
    if (anaemiaData == null) {
      return [pw.Text('No anaemia assessment available', style: normalTextStyle)];
    }
    
    final riskClass = anaemiaData['riskClass'] ?? 'Unknown';
    final probability = anaemiaData['probability']?.toStringAsFixed(1) ?? 'N/A';
    
    return [
      pw.Text('Risk Level: $riskClass', style: boldTextStyle.copyWith(color: PdfColors.red)),
      pw.Text('Probability: $probability%', style: normalTextStyle),
      pw.Text('Raw Score: ${anaemiaData['rawScore'] ?? 'N/A'}', style: normalTextStyle),
      pw.SizedBox(height: 6),
      pw.Text('Key Metrics:', style: boldTextStyle),
      pw.SizedBox(height: 6),
      pw.Row(children: [pw.Text('BMI Value: ', style: boldTextStyle), pw.Text(anaemiaData['bmiValue']?.toStringAsFixed(1) ?? 'N/A', style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Age ≤35: ', style: boldTextStyle), pw.Text(_formatBoolean(anaemiaData['age35OrLess']), style: normalTextStyle)]),
      pw.SizedBox(height: 6),
      pw.Text('Risk Factors:', style: boldTextStyle),
      pw.SizedBox(height: 6),
      pw.Row(children: [pw.Text('Excessive Vomiting: ', style: boldTextStyle), pw.Text(_formatBoolean(anaemiaData['excessiveVomiting']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Diarrhea: ', style: boldTextStyle), pw.Text(_formatBoolean(anaemiaData['diarrhea']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Heavy Menstrual Flow: ', style: boldTextStyle), pw.Text(_formatBoolean(anaemiaData['historyHeavyMenstrualFlow']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Infections: ', style: boldTextStyle), pw.Text(_formatBoolean(anaemiaData['infections']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Chronic Disease: ', style: boldTextStyle), pw.Text(_formatBoolean(anaemiaData['chronicDisease']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Family History: ', style: boldTextStyle), pw.Text(_formatBoolean(anaemiaData['familyHistory']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Low BMI: ', style: boldTextStyle), pw.Text(_formatBoolean(anaemiaData['bmiLow']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Short Interpregnancy Interval: ', style: boldTextStyle), pw.Text(_formatBoolean(anaemiaData['shortInterpregnancyInterval']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Multiple Pregnancy: ', style: boldTextStyle), pw.Text(_formatBoolean(anaemiaData['multiplePregnancy']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Poverty: ', style: boldTextStyle), pw.Text(_formatBoolean(anaemiaData['poverty']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Lack of Healthcare Access: ', style: boldTextStyle), pw.Text(_formatBoolean(anaemiaData['lackOfAccessHealthcare']), style: normalTextStyle)]),
      pw.Row(children: [pw.Text('Low Education: ', style: boldTextStyle), pw.Text(_formatBoolean(anaemiaData['education']), style: normalTextStyle)]),
      if (anaemiaData['createdAt'] != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Text('Assessed on: ${_formatDate(anaemiaData['createdAt'])}', style: normalTextStyle.copyWith(color: PdfColors.grey)),
        ),
    ];
  }

  // Save and Open PDF functionality for mobile
  Future<void> _saveAndOpenPdf(Uint8List pdfBytes) async {
    try {
      // Get the directory for saving the file
      final directory = await getExternalStorageDirectory();
      final downloadsDirectory = Directory('/storage/emulated/0/Download');
      
      // Use Downloads directory if available, otherwise use app directory
      final saveDir = downloadsDirectory.existsSync() ? downloadsDirectory : directory!;
      
      // Create filename with timestamp
      final fileName = 'patient_summary_${_patientIdController.text.trim()}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = '${saveDir.path}/$fileName';
      
      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      
      // Open the file
      await OpenFile.open(filePath);
      
      _showSuccessDialog('PDF downloaded successfully!\nFile: $fileName');
      
    } catch (e) {
      // Fallback: Use getApplicationDocumentsDirectory if external storage fails
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'patient_summary_${_patientIdController.text.trim()}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
        final filePath = '${directory.path}/$fileName';
        
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
        await OpenFile.open(filePath);
        
        _showSuccessDialog('PDF saved to app documents!\nFile: $fileName');
      } catch (e) {
        _showErrorDialog('Failed to save PDF: $e');
      }
    }
  }

  void _showUserInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  const Text(
                    'Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Email row
                  _buildProfileItem(
                    icon: Icons.email_outlined,
                    text: widget.userEmail,
                    onTap: null,
                  ),
                  
                  // Settings row
                  _buildProfileItem(
                    icon: Icons.settings_outlined,
                    text: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetProfilePage(userEmail: widget.userEmail),
                        ),
                      );
                    },
                  ),
                  
                  // Map row
                  _buildProfileItem(
                    icon: Icons.location_on,
                    text: 'View Location Of PregMama',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapPage(),
                        ),
                      );
                    },
                  ),
                  
                  // Support row
                  _buildProfileItem(
                    icon: Icons.help_outline,
                    text: 'Need Help?',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupportFormPage(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
      
                  // Logout button
                  TextButton(
                    onPressed: _logout,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Close button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null) 
                const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Medical Summary',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          Row(
            children: [
              Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            ],
          ),
          IconButton(
            icon: CircleAvatar(
              child: Text(
                widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.blue),
              ),
              backgroundColor: Colors.white,
            ),
            onPressed: () => _showUserInfoDialog(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Center(
                  child: Text(
                    'MEDICAL OFFICER',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text('Prescriptions'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PrescriptionHomePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.show_chart, color: Colors.blue),
                title: const Text('Retrieve Readings'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CsvPage()),
                  );
                },
              ),

              // ListTile(
              //   leading: const Icon(Icons.medication, color: Colors.blue),
              //   title: const Text('Doctor Chat'),
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => DoctorChatPage()),
              //     );
              //   },
              // ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.blue),
                title: const Text('Support Desk'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SupportFormPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.blue),
                title: const Text('Create A Profile'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorProfilePage(),
                    ),
                  );
                },
              ),

              // ListTile(
              //   leading: const Icon(Icons.monitor_heart, color: Colors.blue),
              //   title: const Text('Preeclampsia Symptoms'),
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => const PreeclampsiaHomePage(),
              //       ),
              //     );
              //   },
              // ),

              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text('Appointments'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AppointmentHomePage()),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.monitor_heart, color: Colors.blue),
                title: const Text('Anaemia Prediction'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AnaemiaHomePage()),
                  );
                },
              ),

              // ListTile(
              //   leading: const Icon(Icons.monitor_heart, color: Colors.blue),
              //   title: const Text('Live Preeclampsia Predictions'),
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => const PreeclampsiaHomePage(),
              //       ),
              //     );
              //   },
              // ),

                ListTile(
                leading: Icon(Icons.bloodtype, color: Colors.blue),
                title: Text('Charts Data'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChartsDataPage()),
                  );
                },
              ),


              ListTile(
                leading: const Icon(Icons.bloodtype, color: Colors.blue),
                title: const Text('Glucose Monitoring'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GlucoseMonitoringPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Manual Vitals'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VitalsHealthDataListPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text('View Vitals History'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VitalsHistoryPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.monitor_heart, color: Colors.blue),
                title: const Text('Live Vitals'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LiveVitalsHardwareDataPage()),
                  );
                },
              ),


//               ListTile(
//   leading: Icon(Icons.medical_services, color: Colors.blue),
//   title: Text('Patient Consultations'),
//   onTap: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => DoctorChatPage(
//           doctorId: 'doctor_456',     // Replace with actual doctor ID
//           doctorName: 'Dr. Smith',    // Replace with actual doctor name
//         ),
//       ),
//     );
//   },
// ),
              ListTile(
                leading: const Icon(Icons.health_and_safety, color: Colors.blue),
                title: const Text('Preeclampsia Prediction'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PreeclampsiaDashboard()),
                  );
                },
              ),
            ],
          ),
        ),
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
                        Icons.medical_information,
                        size: 48,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Comprehensive Patient Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _patientIdController,
                        decoration: const InputDecoration(
                          labelText: 'Patient ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                          hintText: 'e.g., 001',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a patient ID' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _fetchAndShowPatientSummary,
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
                                  'Get Patient Summary',
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