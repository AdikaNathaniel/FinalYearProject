import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';

class PreeclampsiaVitals extends StatefulWidget {
  const PreeclampsiaVitals({Key? key}) : super(key: key);

  @override
  State<PreeclampsiaVitals> createState() => _PreeclampsiaVitalsState();
}

class _PreeclampsiaVitalsState extends State<PreeclampsiaVitals> {
  List<VitalRecord> vitals = [];
  bool isLoading = true;
  String errorMessage = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchVitals();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchVitals();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchVitals() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/vitals'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            vitals = (data['result'] as List)
                .map((item) => VitalRecord.fromJson(item))
                .toList();
            // Changed to sort in ascending order (earliest first)
            vitals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            isLoading = false;
            errorMessage = '';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'normal':
        return Colors.green;
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

  String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text(
          'Preeclampsia Prediction',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchVitals,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red[700], fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          onPressed: fetchVitals,
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : vitals.isEmpty
                  ? const Center(
                      child: Text(
                        'No vitals recorded yet.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchVitals,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: vitals.length,
                        itemBuilder: (context, index) {
                          final vital = vitals[index];
                          return VitalCard(vital: vital);
                        },
                      ),
                    ),
    );
  }
}

class VitalRecord {
  final String id;
  final String patientId;
  final int systolic;
  final int diastolic;
  final double map;
  final int proteinuria;
  final double temperature;
  final int heartRate;
  final int spo2;
  final String severity;
  final String rationale;
  final String mlSeverity;
  final Map<String, double> mlProbability;
  final DateTime createdAt;

  VitalRecord({
    required this.id,
    required this.patientId,
    required this.systolic,
    required this.diastolic,
    required this.map,
    required this.proteinuria,
    required this.temperature,
    required this.heartRate,
    required this.spo2,
    required this.severity,
    required this.rationale,
    required this.mlSeverity,
    required this.mlProbability,
    required this.createdAt,
  });

  factory VitalRecord.fromJson(Map<String, dynamic> json) {
    return VitalRecord(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      systolic: json['systolic'] ?? 0,
      diastolic: json['diastolic'] ?? 0,
      map: (json['map'] ?? 0.0).toDouble(),
      proteinuria: json['proteinuria'] ?? 0,
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      heartRate: json['heartRate'] ?? 0,
      spo2: json['spo2'] ?? 0,
      severity: json['severity'] ?? '',
      rationale: json['rationale'] ?? '',
      mlSeverity: json['mlSeverity'] ?? '',
      mlProbability: Map<String, double>.from(
        json['mlProbability']?.map((key, value) => MapEntry(key, value.toDouble())) ?? {},
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class VitalCard extends StatelessWidget {
  final VitalRecord vital;

  const VitalCard({Key? key, required this.vital}) : super(key: key);

  Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'normal':
        return Colors.green;
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

  String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Patient: ${vital.patientId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                Chip(
                  label: Text(
                    vital.severity.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: getSeverityColor(vital.severity),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vitals Grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                VitalItem(icon: Icons.favorite, label: 'BP', value: '${vital.systolic}/${vital.diastolic}', unit: 'mmHg', color: Colors.red),
                VitalItem(icon: Icons.thermostat, label: 'Temp', value: vital.temperature.toStringAsFixed(1), unit: '°C', color: Colors.orange),
                VitalItem(icon: Icons.monitor_heart, label: 'HR', value: '${vital.heartRate}', unit: 'bpm', color: Colors.pink),
                VitalItem(icon: Icons.air, label: 'SpO2', value: '${vital.spo2}', unit: '%', color: Colors.blue),
                VitalItem(icon: Icons.science, label: 'MAP', value: vital.map.toStringAsFixed(1), unit: 'mmHg', color: Colors.purple),
                VitalItem(icon: Icons.water_drop, label: 'Protein', value: '${vital.proteinuria}', unit: '+', color: Colors.teal),
              ],
            ),
            const SizedBox(height: 16),

            // ML Prediction
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ML Prediction: ${vital.mlSeverity}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: getSeverityColor(vital.mlSeverity),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...vital.mlProbability.entries.map((entry) => Row(
                  children: [
                    SizedBox(width: 80, child: Text('${entry.key}:', style: const TextStyle(fontSize: 12))),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: entry.value,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(getSeverityColor(entry.key)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(entry.value * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12)),
                  ],
                )),

            const SizedBox(height: 16),

            // Rationale
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    vital.rationale,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Time
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatDateTime(vital.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VitalItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const VitalItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                text: value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}