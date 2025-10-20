import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnaemiaAssessmentScreen extends StatefulWidget {
  const AnaemiaAssessmentScreen({super.key});

  @override
  _AnaemiaAssessmentScreenState createState() => _AnaemiaAssessmentScreenState();
}

class _AnaemiaAssessmentScreenState extends State<AnaemiaAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDate;

  Map<String, bool?> riskFactors = {
    'excessiveVomiting': null,
    'diarrhea': null,
    'historyHeavyMenstrualFlow': null,
    'infections': null,
    'chronicDisease': null,
    'familyHistory': null,
    'shortInterpregnancyInterval': null,
    'multiplePregnancy': null,
    'poverty': null,
    'lackOfAccessHealthcare': null,
    'education': null,
  };

  bool _isLoading = false;

  @override
  void dispose() {
    _patientIdController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Function to calculate age from date of birth
  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Function to show date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)), // Default to 25 years ago
      firstDate: DateTime(1900), // Allow selection from 1900
      lastDate: DateTime.now(), // Cannot select future dates
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, // Primary color for selected date
              onPrimary: Colors.white, // Text color on primary
              surface: Colors.white, // Background color
              onSurface: Colors.black, // Text color on surface
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _showResultsDialog(dynamic responseData) {
    final result = responseData['result'];
    final probability = result['probability'];
    final riskClass = result['riskClass'];
    final rawScore = result['rawScore'];
    final bmiValue = result['bmiValue'];
    
    // Determine color based on risk level
    Color riskColor;
    IconData riskIcon;
    
    switch (riskClass.toLowerCase()) {
      case 'mild':
        riskColor = Colors.orange;
        riskIcon = Icons.warning;
        break;
      case 'moderate':
        riskColor = Colors.orangeAccent;
        riskIcon = Icons.warning_amber;
        break;
      case 'severe':
        riskColor = Colors.red;
        riskIcon = Icons.error;
        break;
      default:
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: riskColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    riskIcon,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Anaemia Risk Assessment Result',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        riskClass,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${probability.toStringAsFixed(1)}% Probability',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultMetric('Raw Score', rawScore.toString()),
                    _buildResultMetric('BMI', bmiValue.toStringAsFixed(1)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Key Contributing Factors:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Show top 3 contributing factors
                ..._getTopContributingFactors(result['featureContributions'])
                    .take(3)
                    .map((factor) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_forward,
                                color: riskColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  factor['name'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                '${factor['contribution'].toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: riskColor,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: riskColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultMetric(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getTopContributingFactors(
      Map<String, dynamic> featureContributions) {
    List<Map<String, dynamic>> factors = [];

    featureContributions.forEach((key, value) {
      if (value['contribution'] > 0) {
        String displayName = _getDisplayName(key);
        factors.add({
          'name': displayName,
          'contribution': value['contribution'],
        });
      }
    });

    // Sort by contribution in descending order
    factors.sort((a, b) => b['contribution'].compareTo(a['contribution']));

    return factors;
  }

  String _getDisplayName(String key) {
    switch (key) {
      case 'excessiveVomiting':
        return 'Excessive Vomiting';
      case 'diarrhea':
        return 'Diarrhea';
      case 'historyHeavyMenstrualFlow':
        return 'Heavy Menstrual Flow';
      case 'infections':
        return 'Infections';
      case 'chronicDisease':
        return 'Chronic Disease';
      case 'familyHistory':
        return 'Family History';
      case 'bmiLow':
        return 'Low BMI';
      case 'shortInterpregnancyInterval':
        return 'Short Pregnancy Interval';
      case 'multiplePregnancy':
        return 'Multiple Pregnancy';
      case 'age35OrLess':
        return 'Age 35 or Less';
      case 'poverty':
        return 'Poverty';
      case 'lackOfAccessHealthcare':
        return 'Limited Healthcare Access';
      case 'education':
        return 'Education Level';
      default:
        return key;
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if date of birth is selected
    if (_selectedDate == null) {
      _showErrorDialog('Please select your date of birth');
      return;
    }

    setState(() => _isLoading = true);

    // Calculate age from selected date of birth
    final int calculatedAge = _calculateAge(_selectedDate!);

    final data = {
      "patientId": _patientIdController.text.trim(), // Include patient ID
      "weight": double.parse(_weightController.text),
      "height": double.parse(_heightController.text),
      "age": calculatedAge, // Send calculated age to backend
      ...riskFactors.map((key, value) => MapEntry(key, value ?? false)),
    };

    try {
      final response = await http.post(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/anaemia-risk/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        _showResultsDialog(responseData);
      } else {
        // Parse error response if available
        String errorMessage = 'Failed to submit anaemia assessment. Status: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Use default error message if parsing fails
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildRiskFactorCard(String title, String description, IconData icon, String key) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(description),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        riskFactors[key] = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: riskFactors[key] == false ? Colors.blue : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: riskFactors[key] == false ? Colors.blue : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'No',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: riskFactors[key] == false ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        riskFactors[key] = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: riskFactors[key] == true ? Colors.blue : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: riskFactors[key] == true ? Colors.blue : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'Yes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: riskFactors[key] == true ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
        title: const Text(
          'Anaemia Risk Assessment',
          style: TextStyle(
            color: Colors.white, // Text color
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,        
        backgroundColor: Colors.blue,
        elevation: 4,             
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Patient Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _patientIdController,
                decoration: const InputDecoration(
                  labelText: 'Patient ID',
                  hintText: 'Enter patient ID (e.g., 12345)',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter patient ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.monitor_weight),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter weight';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height (m)',
                  prefixIcon: Icon(Icons.height),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter height';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dobController,
                readOnly: true, // Make it read-only so user must use date picker
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: 'Select your date of birth',
                  prefixIcon: const Icon(Icons.cake),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.blue),
                    onPressed: _selectDate,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onTap: _selectDate, // Allow tapping the field to open date picker
                validator: (value) {
                  if (_selectedDate == null) return 'Please select your date of birth';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Risk Factors',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildRiskFactorCard(
                'Excessive Vomiting',
                'Have you experienced frequent vomiting during your pregnancy?',
                Icons.sick,
                'excessiveVomiting',
              ),
              _buildRiskFactorCard(
                'Diarrhoea',
                'Do you experience diarrhea or other digestive problems frequently?',
                Icons.water,
                'diarrhea',
              ),
              _buildRiskFactorCard(
                'Heavy Menstrual Flow',
                'Have you had heavy menstrual bleeding in the past?',
                Icons.bloodtype,
                'historyHeavyMenstrualFlow',
              ),
              _buildRiskFactorCard(
                'Infections',
                'Are you experiencing any infections currently?',
                Icons.coronavirus,
                'infections',
              ),
              _buildRiskFactorCard(
                'Chronic Disease',
                'Do you have any long-term health conditions?',
                Icons.local_hospital,
                'chronicDisease',
              ),
              _buildRiskFactorCard(
                'Family History of Anaemia',
                'Do your close family members have anaemia?',
                Icons.family_restroom,
                'familyHistory',
              ),
              _buildRiskFactorCard(
                'Short Interpregnancy Interval',
                'Is this pregnancy less than 18 months after your previous one?',
                Icons.child_care,
                'shortInterpregnancyInterval',
              ),
              _buildRiskFactorCard(
                'Multiple Pregnancy',
                'Are you carrying more than one baby?',
                Icons.pregnant_woman,
                'multiplePregnancy',
              ),
              _buildRiskFactorCard(
                'Socioeconomic Status',
                'Do you face financial challenges affecting nutrition or healthcare?',
                Icons.monetization_on,
                'poverty',
              ),
              _buildRiskFactorCard(
                'Access to Healthcare',
                'Do you have difficulty accessing medical care?',
                Icons.local_pharmacy,
                'lackOfAccessHealthcare',
              ),
              _buildRiskFactorCard(
                'Education Level',
                'Have you completed only primary school or less?',
                Icons.school,
                'education',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isLoading ? null : _submitAssessment,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Assessment',
                      style: TextStyle(color: Colors.white),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}