import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
  title: 'Preeclampsia Monitor',
  theme: ThemeData(primarySwatch: Colors.blue),
  home: HomePage(),
));

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Preeclampsia Monitor')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Preeclampsia Risk Assessment',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VitalsInputPage()),
                );
              },
              child: Text('Enter Vitals'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VitalsInputPage extends StatefulWidget {
  @override
  _VitalsInputPageState createState() => _VitalsInputPageState();
}

class _VitalsInputPageState extends State<VitalsInputPage> {
  final _formKey = GlobalKey<FormState>();
  
  double systolicBP = 120.0;
  double diastolicBP = 80.0;
  int proteinUrine = 0;
  double? mapValue; // Added to store calculated MAP
  
  // Hardcoded values
  final double glucose = 90.0;
  final double temperature = 36.5;
  final int heartRate = 75;
  final int spo2 = 98;
  
  String? predictionResult;
  String? clinicalRationale;

  Future<void> _sendVitalsToKafka() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Calculate MAP
    mapValue = (systolicBP + 2 * diastolicBP) / 3;
    
    final vitalsData = {
      'patientId': 'flutter-001',
      'systolic': systolicBP,
      'diastolic': diastolicBP,
      'map': mapValue,
      'proteinuria': proteinUrine,
      'glucose': glucose,
      'temperature': temperature,
      'heartRate': heartRate,
      'spo2': spo2,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      // Simulate sending to Kafka
      print('Simulating Kafka send: $vitalsData');
      
      // Calculate clinical severity locally for immediate feedback
      final severity = _calculateClinicalSeverity(mapValue!, proteinUrine, glucose);
      setState(() {
        predictionResult = severity['severity'];
        clinicalRationale = severity['rationale'];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vitals analyzed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to analyze vitals: $e')),
      );
    }
  }

  Map<String, String> _calculateClinicalSeverity(double mapVal, int protein, double glucose) {
    String severityNote = "";
    if (glucose > 140) severityNote = " (Elevated Glucose)";
    else if (glucose < 70) severityNote = " (Low Glucose)";
    
    if (70 <= mapVal && mapVal <= 100) {
      return {
        'severity': 'No Preeclampsia',
        'rationale': 'MAP in normal range (70-100)$severityNote'
      };
    } else if (107 <= mapVal && mapVal <= 113) {
      return {
        'severity': 'Mild',
        'rationale': protein >= 1 
          ? 'MAP: ${mapVal.toStringAsFixed(1)} (107-113), Protein: $protein+ (≥1)$severityNote'
          : 'MAP: ${mapVal.toStringAsFixed(1)} (107-113), Protein: $protein (below threshold)$severityNote'
      };
    } else if (114 <= mapVal && mapVal <= 129) {
      return {
        'severity': 'Moderate',
        'rationale': protein >= 2
          ? 'MAP: ${mapVal.toStringAsFixed(1)} (114-129), Protein: $protein+ (≥2)$severityNote'
          : 'MAP: ${mapVal.toStringAsFixed(1)} (114-129), Protein: $protein (below threshold)$severityNote'
      };
    } else if (mapVal >= 130) {
      return {
        'severity': 'Severe',
        'rationale': protein >= 2
          ? 'MAP: ${mapVal.toStringAsFixed(1)} (≥130), Protein: $protein+ (≥2)$severityNote'
          : 'MAP: ${mapVal.toStringAsFixed(1)} (≥130), Protein: $protein (below threshold)$severityNote'
      };
    } else if (101 <= mapVal && mapVal <= 106) {
      return {
        'severity': 'No Preeclampsia',
        'rationale': 'MAP: ${mapVal.toStringAsFixed(1)} (101-106) - Borderline$severityNote'
      };
    }
    return {
      'severity': 'No Preeclampsia',
      'rationale': 'MAP: ${mapVal.toStringAsFixed(1)} - Below thresholds$severityNote'
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preeclampsia Risk Assessment'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVitalInput(
                'Systolic BP (mmHg)',
                70, 200, systolicBP, (v) => systolicBP = v,
                validator: (v) => (v != null && (v < 70 || v > 200)) ? 'Invalid range (70-200)' : null,
              ),
              _buildVitalInput(
                'Diastolic BP (mmHg)',
                40, 120, diastolicBP, (v) => diastolicBP = v,
                validator: (v) => (v != null && (v < 40 || v > 120)) ? 'Invalid range (40-120)' : null,
              ),
              _buildDropdownInput(
                'Proteinuria',
                [0, 1, 2, 3, 4],
                proteinUrine, (v) => proteinUrine = v!,
              ),
              SizedBox(height: 20),
              // Card(
              //   child: Padding(
              //     padding: EdgeInsets.all(16),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //           'Automatically Collected Vitals',
              //           style: Theme.of(context).textTheme.titleMedium,
              //         ),
              //         SizedBox(height: 8),
              //         Text('Glucose: ${glucose.toStringAsFixed(1)} mg/dL'),
              //         Text('Temperature: ${temperature.toStringAsFixed(1)}°C'),
              //         Text('Heart Rate: $heartRate bpm'),
              //         Text('SpO2: $spo2%'),
              //       ],
              //     ),
              //   ),
              // ),
              // SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendVitalsToKafka,
                child: Text('Assess Risk'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (predictionResult != null) ...[
                SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Risk Assessment',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Calculated MAP: ${mapValue?.toStringAsFixed(1)} mmHg',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Severity: ${predictionResult!}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getSeverityColor(predictionResult!),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Clinical Rationale: $clinicalRationale'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Severe': return Colors.red;
      case 'Moderate': return Colors.orange;
      case 'Mild': return Colors.yellow[700]!;
      default: return Colors.green;
    }
  }

  Widget _buildVitalInput(
    String label,
    double min,
    double max,
    double value,
    Function(double) onSaved, {
    String? Function(double?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          suffixText: 'mmHg',
        ),
        initialValue: value.toStringAsFixed(0),
        keyboardType: TextInputType.number,
        validator: (v) {
          if (v == null || v.isEmpty) return 'Please enter a value';
          final numValue = double.tryParse(v);
          if (numValue == null) return 'Please enter a valid number';
          return validator?.call(numValue);
        },
        onSaved: (v) => onSaved(double.parse(v!)),
      ),
    );
  }

  Widget _buildDropdownInput<T>(
    String label,
    List<T> options,
    T value,
    Function(T?) onSaved,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        value: value,
        items: options.map((T value) {
          return DropdownMenuItem<T>(
            value: value,
            child: Text(value.toString()),
          );
        }).toList(),
        onChanged: (T? newValue) {
          setState(() {
            onSaved(newValue);
          });
        },
      ),
    );
  }
}