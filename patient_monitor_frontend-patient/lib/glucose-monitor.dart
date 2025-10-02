import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // For groupBy function

class GlucoseMonitoringPage extends StatefulWidget {
  const GlucoseMonitoringPage({Key? key}) : super(key: key);

  @override
  State<GlucoseMonitoringPage> createState() => _GlucoseMonitoringPageState();
}

class _GlucoseMonitoringPageState extends State<GlucoseMonitoringPage> {
  List<VitalRecord> vitals = [];
  List<GlucoseSummary> glucoseSummaries = [];
  bool isLoading = true;
  String errorMessage = '';
  Timer? _timer;
  String selectedTimeContext = 'All'; // Default to show all
  Map<String, String> readingTimeContexts = {}; // Store user-selected contexts

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
            processGlucoseData();
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

  void processGlucoseData() {
    // Filter records that have glucose values and group by hour
    final glucoseReadings = vitals
        .where((v) => v.glucose != null)
        .map((v) {
          final readingId = '${v.id}_${v.createdAt.millisecondsSinceEpoch}';
          return GlucoseReading(
            id: readingId,
            value: v.glucose!,
            timestamp: v.createdAt,
            timeContext: readingTimeContexts[readingId] ?? 'Not Set',
          );
        })
        .toList();

    final groupedReadings = groupBy(glucoseReadings, (reading) {
      return DateTime(
        reading.timestamp.year,
        reading.timestamp.month,
        reading.timestamp.day,
        reading.timestamp.hour,
      );
    });

    glucoseSummaries = groupedReadings.entries.map((entry) {
      final readings = entry.value;
      
      // Filter readings based on selected time context
      final filteredReadings = selectedTimeContext == 'All' 
          ? readings 
          : readings.where((r) => r.timeContext == selectedTimeContext).toList();
      
      if (filteredReadings.isEmpty) {
        return null; // Skip this summary if no readings match the filter
      }
      
      final values = filteredReadings.map((r) => r.value).toList();
      
      final mean = values.average;
      final max = values.reduce((a, b) => a > b ? a : b);
      final std = calculateStandardDeviation(values);
      final spikes = values.where((v) => v >= 140).length;

      return GlucoseSummary(
        hourStart: entry.key,
        meanGlucose: mean,
        maxGlucose: max,
        stdGlucose: std,
        numSpikes: spikes,
        readings: filteredReadings,
      );
    }).where((summary) => summary != null).cast<GlucoseSummary>().toList();

    glucoseSummaries.sort((a, b) => b.hourStart.compareTo(a.hourStart));
  }

  double calculateStandardDeviation(List<double> values) {
    if (values.length <= 1) return 0.0;
    final mean = values.average;
    final squaredDiffs = values.map((v) => pow(v - mean, 2)).toList();
    final variance = squaredDiffs.average;
    return sqrt(variance);
  }

  String getRiskAssessment(double meanGlucose, String timeContext) {
    switch (timeContext) {
      case 'Fasting':
        return meanGlucose >= 95 ? 'High Risk' : 'Low Risk';
      case '1h post-meal':
        return meanGlucose >= 180 ? 'High Risk' : 'Low Risk';
      case '2h post-meal':
        return meanGlucose >= 155 ? 'High Risk' : 'Low Risk';
      case 'Random':
        return meanGlucose >= 140 ? 'High Risk' : 'Low Risk';
      default:
        return 'Unknown Risk';
    }
  }

  Color getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high risk':
        return Colors.red;
      case 'low risk':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void updateReadingTimeContext(String readingId, String context) {
    setState(() {
      readingTimeContexts[readingId] = context;
      processGlucoseData(); // Reprocess data with new context
    });
  }

  void showTimeContextSelectionDialog(GlucoseReading reading) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Set Time Context'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reading: ${reading.value.toStringAsFixed(1)} mg/dL'),
              Text('Time: ${DateFormat('MMM dd, HH:mm').format(reading.timestamp)}'),
              const SizedBox(height: 16),
              ...['Fasting', '1h post-meal', '2h post-meal', 'Random'].map((timeContext) {
                return RadioListTile<String>(
                  title: Text(timeContext),
                  value: timeContext,
                  groupValue: reading.timeContext == 'Not Set' ? null : reading.timeContext,
                  onChanged: (String? value) {
                    if (value != null) {
                      updateReadingTimeContext(reading.id, value);
                      Navigator.of(dialogContext).pop();
                    }
                  },
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text(
          'Glucose Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchVitals,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by Time Context:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['All', 'Fasting', '1h post-meal', '2h post-meal', 'Random', 'Not Set']
                      .map((context) => FilterChip(
                            label: Text(context),
                            selected: selectedTimeContext == context,
                            onSelected: (bool selected) {
                              setState(() {
                                selectedTimeContext = context;
                                processGlucoseData();
                              });
                            },
                            selectedColor: Colors.teal.withOpacity(0.3),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
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
                    : glucoseSummaries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bloodtype, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  selectedTimeContext == 'All' 
                                    ? 'No glucose readings recorded yet.'
                                    : 'No glucose readings found for "$selectedTimeContext" context.',
                                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                if (selectedTimeContext != 'All') ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tap on individual readings to set their time context.',
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchVitals,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: glucoseSummaries.length,
                              itemBuilder: (context, index) {
                                final summary = glucoseSummaries[index];
                                return GlucoseSummaryCard(
                                  summary: summary,
                                  onReadingTap: showTimeContextSelectionDialog,
                                  getRiskAssessment: getRiskAssessment,
                                );
                              },
                            ),
                          ),
          ),
        ],
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
  final double? glucose;
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
    this.glucose,
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
      glucose: json['glucose']?.toDouble(),
      rationale: json['rationale'] ?? '',
      mlSeverity: json['mlSeverity'] ?? '',
      mlProbability: Map<String, double>.from(
        json['mlProbability']?.map((key, value) => MapEntry(key, value.toDouble())) ?? {},
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class GlucoseReading {
  final String id;
  final double value;
  final DateTime timestamp;
  final String timeContext;

  GlucoseReading({
    required this.id,
    required this.value,
    required this.timestamp,
    required this.timeContext,
  });
}

class GlucoseSummary {
  final DateTime hourStart;
  final double meanGlucose;
  final double maxGlucose;
  final double stdGlucose;
  final int numSpikes;
  final List<GlucoseReading> readings;

  GlucoseSummary({
    required this.hourStart,
    required this.meanGlucose,
    required this.maxGlucose,
    required this.stdGlucose,
    required this.numSpikes,
    required this.readings,
  });
}

class GlucoseSummaryCard extends StatelessWidget {
  final GlucoseSummary summary;
  final Function(GlucoseReading) onReadingTap;
  final String Function(double, String) getRiskAssessment;

  const GlucoseSummaryCard({
    Key? key,
    required this.summary,
    required this.onReadingTap,
    required this.getRiskAssessment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate overall risk based on readings with set contexts
    final readingsWithContext = summary.readings.where((r) => r.timeContext != 'Not Set').toList();
    final overallRisk = readingsWithContext.isNotEmpty 
        ? _calculateOverallRisk(readingsWithContext)
        : 'Unknown Risk';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hour: ${DateFormat('HH:00').format(summary.hourStart)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text(
                    overallRisk.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getRiskColor(overallRisk),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildMetricItem('Mean', '${summary.meanGlucose.toStringAsFixed(1)} mg/dL', Icons.show_chart),
                _buildMetricItem('Max', '${summary.maxGlucose.toStringAsFixed(1)} mg/dL', Icons.arrow_upward),
                _buildMetricItem('Variability', '${summary.stdGlucose.toStringAsFixed(1)}', Icons.insights),
                _buildMetricItem('Spikes', '${summary.numSpikes}', Icons.warning),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Total readings: ${summary.readings.length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // Individual readings
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: summary.readings.map((reading) {
                return GestureDetector(
                  onTap: () => onReadingTap(reading),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: reading.timeContext == 'Not Set' 
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      border: Border.all(
                        color: reading.timeContext == 'Not Set' 
                            ? Colors.orange
                            : Colors.blue,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${reading.value.toStringAsFixed(0)} (${reading.timeContext})',
                      style: TextStyle(
                        fontSize: 11,
                        color: reading.timeContext == 'Not Set' 
                            ? Colors.orange[700]
                            : Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (summary.readings.any((r) => r.timeContext == 'Not Set')) ...[
              const SizedBox(height: 8),
              Text(
                'Tap on orange readings to set their time context',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _calculateOverallRisk(List<GlucoseReading> readings) {
    final contextGroups = groupBy(readings, (reading) => reading.timeContext);
    int highRiskCount = 0;
    int totalContexts = contextGroups.length;

    for (final entry in contextGroups.entries) {
      final context = entry.key;
      final contextReadings = entry.value;
      final meanValue = contextReadings.map((r) => r.value).average;
      final risk = getRiskAssessment(meanValue, context);
      if (risk == 'High Risk') {
        highRiskCount++;
      }
    }

    if (highRiskCount > 0) {
      return 'High Risk';
    } else if (totalContexts > 0) {
      return 'Low Risk';
    } else {
      return 'Unknown Risk';
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high risk':
        return Colors.red;
      case 'low risk':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}