import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Analytics Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const PatientAnalyticsPage(),
    );
  }
}

class PatientAnalyticsPage extends StatefulWidget {
  const PatientAnalyticsPage({Key? key}) : super(key: key);

  @override
  State<PatientAnalyticsPage> createState() => _PatientAnalyticsPageState();
}

class _PatientAnalyticsPageState extends State<PatientAnalyticsPage> {
  final TextEditingController _patientNameController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _patientData;
  String? _patientName;

  @override
  void dispose() {
    _patientNameController.dispose();
    super.dispose();
  }

  Future<void> _searchPatient() async {
    final patientName = _patientNameController.text.trim();
    if (patientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a patient name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await fetchPatientData(patientName);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _patientData = response;
        _patientName = patientName;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<Map<String, dynamic>> fetchPatientData(String patientName) async {
    final encodedName = Uri.encodeComponent(patientName);
    final url = Uri.parse(
      'http://localhost:3100/api/v1/health-analytics/charting-insights?patientName=$encodedName');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load patient data: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Health Analytics'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter Patient Name',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _patientNameController,
                decoration: InputDecoration(
                  hintText: 'Patient Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _searchPatient,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Search', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
              if (_patientData != null) _buildPatientDashboard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientDashboard() {
    final insights = _patientData!['result']['insights'] as List<dynamic>;
    final charts = _patientData!['result']['charts'] as List<dynamic>;

    return Expanded(
      child: Scrollbar(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildInsightsSection(insights),
            const SizedBox(height: 16),
            _buildChartsSection(charts),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(List<dynamic> insights) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Key Insights',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: insights.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insights[index].toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(List<dynamic> charts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Health Charts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: charts.length,
          itemBuilder: (context, index) {
            final chart = charts[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      chart['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildChart(chart),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChart(Map<String, dynamic> chart) {
    final type = chart['type'];
    
    switch (type) {
      case 'line':
        return _buildLineChart(chart);
      case 'bar':
        return _buildBarChart(chart);
      case 'scatter':
        return _buildScatterChart(chart);
      case 'pie':
        return _buildPieChart(chart);
      case 'radar':
        return _buildRadarChart(chart);
      default:
        return const Center(child: Text('Unsupported chart type'));
    }
  }

  Widget _buildLineChart(Map<String, dynamic> chart) {
    final labels = (chart['labels'] as List).cast<String>();
    final datasets = chart['datasets'] as List;
    
    final spots = <List<FlSpot>>[];
    final colors = <Color>[];
    final titles = <String>[];

    for (var dataset in datasets) {
      final data = dataset['data'] as List;
      final dataPoints = <FlSpot>[];

      for (var i = 0; i < data.length; i++) {
        final y = double.parse(data[i].toString());
        dataPoints.add(FlSpot(i.toDouble(), y));
      }

      spots.add(dataPoints);
      colors.add(Color(int.parse(dataset['color'].replaceAll('#', '0xFF'))));
      titles.add(dataset['label']);
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < labels.length) {
                  return Text(
                    labels[value.toInt()],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: List.generate(
          spots.length,
          (i) => LineChartBarData(
            spots: spots[i],
            isCurved: true,
            color: colors[i],
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> chart) {
    final labels = (chart['labels'] as List).cast<String>();
    final datasets = chart['datasets'] as List;

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          labels.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: List.generate(
              datasets.length,
              (datasetIndex) {
                final dataset = datasets[datasetIndex];
                final data = dataset['data'] as List;
                final color = dataset['color'] is List
                    ? Color(int.parse(dataset['color'][index].replaceAll('#', '0xFF')))
                    : Color(int.parse(dataset['color'].replaceAll('#', '0xFF')));

                return BarChartRodData(
                  toY: double.parse(data[index].toString()),
                  color: color,
                  width: 16 / datasets.length,
                  borderRadius: BorderRadius.circular(4),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScatterChart(Map<String, dynamic> chart) {
    final datasets = chart['datasets'] as List;
    final spots = <ScatterSpot>[];
    
    for (var dataset in datasets) {
      final color = Color(int.parse(dataset['color'].replaceAll('#', '0xFF')));
      for (var point in dataset['data'] as List) {
        // In fl_chart 0.71.0, ScatterSpot constructor only takes x and y
        spots.add(
          ScatterSpot(
            double.parse(point['x'].toString()),
            double.parse(point['y'].toString()),
          ),
        );
      }
    }
    
    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots,
        titlesData: const FlTitlesData(
          show: false,
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
      ),
    );
  }

  Widget _buildPieChart(Map<String, dynamic> chart) {
    final labels = (chart['labels'] as List).cast<String>();
    final data = chart['datasets'][0]['data'] as List;
    final colors = chart['datasets'][0]['color'] as List;

    // Convert data to PieChartSectionData objects
    final sections = <PieChartSectionData>[];
    for (var i = 0; i < labels.length; i++) {
      final value = double.parse(data[i].toString());
      final color = Color(int.parse(colors[i].replaceAll('#', '0xFF')));
      
      sections.add(
        PieChartSectionData(
          value: value,
          title: '${(value * 100).toStringAsFixed(0)}%',
          color: color,
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 0,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildRadarChart(Map<String, dynamic> chart) {
    final labels = (chart['labels'] as List).cast<String>();
    final dataset = chart['datasets'][0];
    final data = (dataset['data'] as List).map((e) => double.parse(e.toString())).toList();
    final color = Color(int.parse(dataset['color'].replaceAll('#', '0xFF')));

    // For fl_chart 0.71.0, create RadarChartTitle objects for each label
    return RadarChart(
      RadarChartData(
        radarBorderData: const BorderSide(color: Colors.transparent),
        tickBorderData: const BorderSide(color: Colors.transparent),
        gridBorderData: BorderSide(color: Colors.grey[300]!, width: 1),
        ticksTextStyle: const TextStyle(color: Colors.transparent),
        titleTextStyle: const TextStyle(fontSize: 8, color: Colors.black54),
        tickCount: 4,
        dataSets: [
          RadarDataSet(
            fillColor: color.withOpacity(0.2),
            borderColor: color,
            entryRadius: 2,
            dataEntries: [
              for (int i = 0; i < data.length; i++)
                RadarEntry(value: data[i]),
            ],
          ),
        ],
        titlePositionPercentageOffset: 0.12,
        getTitle: (index, angle) {
          // Creating a RadarChartTitle object
          return RadarChartTitle(
            text: labels[index % labels.length],
            angle: angle,
          );
        },
      ),
    );
  }
}