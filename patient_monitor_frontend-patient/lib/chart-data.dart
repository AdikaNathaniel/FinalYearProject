import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

// Base API URL
const String baseUrl = "http://localhost:3100/api/v1/chart-data";

class ChartsDataPage extends StatelessWidget {
  final List<Map<String, dynamic>> chartEndpoints = [
    {
      "title": "Vital Trends",
      "endpoint": "$baseUrl/vital-trends",
      "route": "/vital-trends",
      "supportsDays": true
    },
    {
      "title": "Temperature Comparison",
      "endpoint": "$baseUrl/temperature-comparison",
      "route": "/temperature-comparison",
      "supportsDays": true
    },
    {
      "title": "Oxygen Saturation",
      "endpoint": "$baseUrl/oxygen-saturation",
      "route": "/oxygen-saturation",
      "supportsDays": true
    },
    {
      "title": "Vital Statistics",
      "endpoint": "$baseUrl/vital-statistics",
      "route": "/vital-statistics",
      "supportsDays": false
    },
    {
      "title": "Risk Assessment",
      "endpoint": "$baseUrl/risk-assessment",
      "route": "/risk-assessment",
      "supportsDays": false
    },
    {
      "title": "Movement Analysis",
      "endpoint": "$baseUrl/movement-analysis",
      "route": "/movement-analysis",
      "supportsDays": true
    },
    {
      "title": "Protein Trend",
      "endpoint": "$baseUrl/protein-trend",
      "route": "/protein-trend",
      "supportsDays": true
    },
    {
      "title": "Comprehensive Dashboard",
      "endpoint": "$baseUrl/comprehensive-dashboard",
      "route": "/comprehensive-dashboard",
      "supportsDays": true
    },
    {
      "title": "All Chart Data",
      "endpoint": "$baseUrl",
      "route": "/all-chart-data",
      "supportsDays": false
    },
    {
      "title": "Create Chart Data",
      "endpoint": "$baseUrl",
      "route": "/create-chart-data",
      "supportsDays": false
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Charts Dashboard"),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 cards per row
          childAspectRatio: 4 / 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: chartEndpoints.length,
        itemBuilder: (context, index) {
          final item = chartEndpoints[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChartDetailPage(
                    title: item["title"],
                    endpoint: item["endpoint"],
                    supportsDays: item["supportsDays"] ?? false,
                  ),
                ),
              );
            },
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics, size: 40, color: Colors.teal),
                      const SizedBox(height: 10),
                      Text(
                        item["title"],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChartDetailPage extends StatefulWidget {
  final String title;
  final String endpoint;
  final bool supportsDays;

  const ChartDetailPage({
    required this.title,
    required this.endpoint,
    required this.supportsDays,
    Key? key,
  }) : super(key: key);

  @override
  _ChartDetailPageState createState() => _ChartDetailPageState();
}

class _ChartDetailPageState extends State<ChartDetailPage> {
  bool isLoading = false;
  Map<String, dynamic>? responseData;
  final TextEditingController _daysController = TextEditingController(text: "7");
  bool showRawJson = false;

  @override
  void initState() {
    super.initState();
    fetchChartData();
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  Future<void> fetchChartData() async {
    setState(() {
      isLoading = true;
    });

    try {
      String url = widget.endpoint;
      if (widget.supportsDays) {
        final days = _daysController.text.isNotEmpty ? _daysController.text : "7";
        url += "?days=$days";
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          responseData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        responseData = {"error": e.toString()};
      });
    }
  }

  Widget buildLineChart(List<dynamic> data) {
    if (data.isEmpty) return const Center(child: Text("No data points available"));

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      double value = 0;
      if (item is Map<String, dynamic>) {
        // Try to find a numeric value in the data
        value = (item["value"] ?? item["y"] ?? item["amount"] ?? 0).toDouble();
      } else if (item is num) {
        value = item.toDouble();
      }
      spots.add(FlSpot(i.toDouble(), value));
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.teal,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildChart() {
    if (responseData == null) {
      return const Center(
        child: Text(
          "No data available",
          style: TextStyle(fontSize: 16, color: Colors.red),
        ),
      );
    }

    // Check if there's an error in the response
    if (responseData!.containsKey("error") && responseData!["error"] != null) {
      return Center(
        child: Text(
          responseData!["error"].toString(),
          style: const TextStyle(fontSize: 16, color: Colors.red),
        ),
      );
    }

    // Check for the standard API response structure
    if (responseData!.containsKey("result") && responseData!["result"] != null) {
      final result = responseData!["result"];
      
      // FIXED: Check if result is a List (for "All Chart Data" endpoint)
      if (result is List) {
        return buildAllChartsDataView(result);
      }
      
      // FIXED: Check if result is a Map before calling containsKey
      if (result is Map<String, dynamic>) {
        // Handle comprehensive dashboard with multiple charts
        if (widget.title == "Comprehensive Dashboard") {
          return buildComprehensiveDashboard(result);
        }
        
        // Handle chart.js format (with datasets and labels)
        if (result.containsKey("datasets") && result.containsKey("labels")) {
          return buildChartJsChart(result);
        }
        
        // Handle other result structures
        if (result.containsKey("vitals")) {
          return buildVitalsChart(result);
        } else if (result.containsKey("temperature_data")) {
          return buildTemperatureChart(result);
        } else if (result.containsKey("oxygen_levels")) {
          return buildOxygenChart(result);
        } else if (result.containsKey("statistics")) {
          return buildStatisticsView(result["statistics"]);
        } else if (result.containsKey("risk_level")) {
          return buildRiskAssessmentView(result);
        } else if (result.containsKey("movement_data")) {
          return buildMovementChart(result);
        }
      }
    }

    // Handle legacy format (direct data structure)
    if (responseData!.containsKey("data") && responseData!["data"] is List) {
      return buildLineChart(responseData!["data"]);
    } else if (responseData!.containsKey("vitals")) {
      return buildVitalsChart(responseData!);
    } else if (responseData!.containsKey("temperature_data")) {
      return buildTemperatureChart(responseData!);
    } else if (responseData!.containsKey("oxygen_levels")) {
      return buildOxygenChart(responseData!);
    } else if (responseData!.containsKey("statistics")) {
      return buildStatisticsView(responseData!["statistics"]);
    } else if (responseData!.containsKey("risk_level")) {
      return buildRiskAssessmentView(responseData!);
    } else if (responseData!.containsKey("movement_data")) {
      return buildMovementChart(responseData!);
    } else if (responseData!.containsKey("protein_levels")) {
      return buildProteinChart(responseData!);
    } else {
      return buildGenericChart(responseData!);
    }
  }

  // NEW: Handle "All Chart Data" endpoint that returns an array
  Widget buildAllChartsDataView(List<dynamic> chartDataList) {
    if (chartDataList.isEmpty) {
      return const Center(child: Text("No chart data available"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "All Chart Data Records (${chartDataList.length} items)",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...chartDataList.map((item) {
            if (item is Map<String, dynamic>) {
              return buildChartDataCard(item);
            }
            return Container();
          }).toList(),
        ],
      ),
    );
  }

  // NEW: Build individual chart data cards
  Widget buildChartDataCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.containsKey("createdAt"))
              Text(
                "Recorded: ${DateTime.parse(data["createdAt"]).toLocal()}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                if (data.containsKey("glucose"))
                  _buildDataTile("Glucose", "${data["glucose"]} mg/dL", Icons.water_drop),
                if (data.containsKey("heartRate"))
                  _buildDataTile("Heart Rate", "${data["heartRate"]} BPM", Icons.favorite),
                if (data.containsKey("systolicBP"))
                  _buildDataTile("Systolic BP", "${data["systolicBP"]} mmHg", Icons.trending_up),
                if (data.containsKey("diastolicBP"))
                  _buildDataTile("Diastolic BP", "${data["diastolicBP"]} mmHg", Icons.trending_down),
                if (data.containsKey("spo2"))
                  _buildDataTile("SpO2", "${data["spo2"]}%", Icons.air),
                if (data.containsKey("bodyTemp"))
                  _buildDataTile("Body Temp", "${data["bodyTemp"]}°C", Icons.thermostat),
                if (data.containsKey("skinTemp"))
                  _buildDataTile("Skin Temp", "${data["skinTemp"]}°C", Icons.thermostat_outlined),
                if (data.containsKey("proteinLevel"))
                  _buildDataTile("Protein", "${data["proteinLevel"]} mg/dL", Icons.science),
              ],
            ),
            if (data.containsKey("accelX") && data.containsKey("accelY") && data.containsKey("accelZ"))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Acceleration Data:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("X: ${data["accelX"]}, Y: ${data["accelY"]}, Z: ${data["accelZ"]}"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.teal),
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Handle comprehensive dashboard with multiple charts
  Widget buildComprehensiveDashboard(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Comprehensive Dashboard",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Vital Trends Chart
          if (data.containsKey("vitalTrends"))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Vital Trends",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                buildChartJsChart(data["vitalTrends"]),
                const SizedBox(height: 20),
              ],
            ),
          
          // Temperature Comparison Chart
          if (data.containsKey("temperatureComparison"))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Temperature Comparison",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                buildChartJsChart(data["temperatureComparison"]),
                const SizedBox(height: 20),
              ],
            ),
          
          // Oxygen Saturation Chart
          if (data.containsKey("oxygenSaturation"))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Oxygen Saturation",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                buildChartJsChart(data["oxygenSaturation"]),
                const SizedBox(height: 20),
              ],
            ),
          
          // Vital Statistics Chart
          if (data.containsKey("vitalStatistics"))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Vital Statistics",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                buildBarChart(data["vitalStatistics"]),
                const SizedBox(height: 20),
              ],
            ),
          
          // Risk Assessment Chart
          if (data.containsKey("riskAssessment"))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Risk Assessment",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                buildRiskAssessmentChart(data["riskAssessment"]),
                const SizedBox(height: 20),
              ],
            ),
          
          // Movement Analysis Chart
          if (data.containsKey("movementAnalysis"))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Movement Analysis",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                buildChartJsChart(data["movementAnalysis"]),
                const SizedBox(height: 20),
              ],
            ),
          
          // Protein Trend Chart
          if (data.containsKey("proteinTrend"))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Protein Trend",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                buildChartJsChart(data["proteinTrend"]),
              ],
            ),
        ],
      ),
    );
  }

  // NEW: Build bar chart for vital statistics
  Widget buildBarChart(Map<String, dynamic> chartData) {
    final labels = chartData["labels"] as List<dynamic>?;
    final datasets = chartData["datasets"] as List<dynamic>?;
    
    if (labels == null || datasets == null || datasets.isEmpty) {
      return const Center(child: Text("No chart data available"));
    }

    final dataset = datasets.first;
    final data = dataset["data"] as List<dynamic>? ?? [];
    
    if (data.isEmpty) {
      return const Center(child: Text("No data points available"));
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < data.length && i < labels.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data[i].toDouble(),
              color: Colors.teal,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.map((e) => e.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[index].toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          barGroups: barGroups,
        ),
      ),
    );
  }

  // NEW: Build pie chart for risk assessment
  Widget buildRiskAssessmentChart(Map<String, dynamic> chartData) {
    final labels = chartData["labels"] as List<dynamic>?;
    final datasets = chartData["datasets"] as List<dynamic>?;
    
    if (labels == null || datasets == null || datasets.isEmpty) {
      return const Center(child: Text("No risk assessment data available"));
    }

    final dataset = datasets.first;
    final data = dataset["data"] as List<dynamic>? ?? [];
    
    if (data.isEmpty || labels.isEmpty) {
      return const Center(child: Text("No risk data available"));
    }

    List<PieChartSectionData> sections = [];
    List<Color> colors = [Colors.green, Colors.red, Colors.orange, Colors.blue];
    
    for (int i = 0; i < data.length && i < labels.length; i++) {
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: data[i].toDouble(),
          title: '${labels[i]}\n${data[i]}',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sections: sections,
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget buildChartJsChart(Map<String, dynamic> result) {
    final labels = result["labels"] as List<dynamic>?;
    final datasets = result["datasets"] as List<dynamic>?;
    
    if (labels == null || datasets == null || datasets.isEmpty) {
      return const Center(child: Text("No chart data available"));
    }

    // Handle multiple datasets
    List<LineChartBarData> lineBarsData = [];
    
    for (int datasetIndex = 0; datasetIndex < datasets.length; datasetIndex++) {
      final dataset = datasets[datasetIndex];
      final data = dataset["data"] as List<dynamic>?;
      
      if (data == null || data.isEmpty) continue;
      
      List<FlSpot> spots = [];
      for (int i = 0; i < data.length; i++) {
        final value = data[i];
        if (value is num) {
          spots.add(FlSpot(i.toDouble(), value.toDouble()));
        }
      }
      
      if (spots.isNotEmpty) {
        // Extract color from borderColor or use default colors
        Color lineColor = Colors.teal;
        if (dataset["borderColor"] != null) {
          String borderColor = dataset["borderColor"].toString();
          if (borderColor.contains("rgb")) {
            // Parse rgb color - simple implementation
            if (borderColor.contains("153, 102, 255")) {
              lineColor = Colors.purple;
            } else if (borderColor.contains("255, 99, 132")) {
              lineColor = Colors.red;
            } else if (borderColor.contains("54, 162, 235")) {
              lineColor = Colors.blue;
            } else if (borderColor.contains("255, 205, 86")) {
              lineColor = Colors.yellow;
            } else if (borderColor.contains("75, 192, 192")) {
              lineColor = Colors.teal;
            }
          }
        } else {
          // Use different colors for multiple datasets
          List<Color> defaultColors = [Colors.teal, Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple];
          lineColor = defaultColors[datasetIndex % defaultColors.length];
        }
        
        lineBarsData.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: lineColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            }),
          ),
        );
      }
    }
    
    if (lineBarsData.isEmpty) {
      return const Center(child: Text("No valid data points found"));
    }

    return Column(
      children: [
        // Legend
        if (datasets.length > 1)
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              children: datasets.asMap().entries.map((entry) {
                final index = entry.key;
                final dataset = entry.value;
                final label = dataset["label"] ?? "Dataset ${index + 1}";
                
                Color legendColor = Colors.teal;
                List<Color> defaultColors = [Colors.teal, Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple];
                legendColor = defaultColors[index % defaultColors.length];
                
                return Container(
                  margin: const EdgeInsets.only(right: 16, bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: legendColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(label.toString(), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        
        // Chart
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                horizontalInterval: null,
                verticalInterval: null,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index].toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300),
              ),
              lineBarsData: lineBarsData,
              minX: 0,
              maxX: (labels.length - 1).toDouble(),
            ),
          ),
        ),
        
        // Data summary
        if (datasets.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Data Summary",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...datasets.map((dataset) {
                      final label = dataset["label"] ?? "Unknown";
                      final data = dataset["data"] as List<dynamic>? ?? [];
                      final latestValue = data.isNotEmpty ? data.last : "N/A";
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(label.toString()),
                            Text(
                              "Latest: $latestValue",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildVitalsChart(Map<String, dynamic> data) {
    final vitals = data["vitals"];
    if (vitals == null) return const Center(child: Text("No vitals data"));

    List<FlSpot> heartRateSpots = [];
    List<FlSpot> temperatureSpots = [];
    List<FlSpot> oxygenSpots = [];

    for (int i = 0; i < vitals.length; i++) {
      final vital = vitals[i];
      if (vital["heart_rate"] != null) {
        heartRateSpots.add(FlSpot(i.toDouble(), vital["heart_rate"].toDouble()));
      }
      if (vital["temperature"] != null) {
        temperatureSpots.add(FlSpot(i.toDouble(), vital["temperature"].toDouble()));
      }
      if (vital["oxygen_saturation"] != null) {
        oxygenSpots.add(FlSpot(i.toDouble(), vital["oxygen_saturation"].toDouble()));
      }
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            if (heartRateSpots.isNotEmpty)
              LineChartBarData(
                spots: heartRateSpots,
                isCurved: true,
                color: Colors.red,
                barWidth: 2,
                dotData: FlDotData(show: false),
              ),
            if (temperatureSpots.isNotEmpty)
              LineChartBarData(
                spots: temperatureSpots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 2,
                dotData: FlDotData(show: false),
              ),
            if (oxygenSpots.isNotEmpty)
              LineChartBarData(
                spots: oxygenSpots,
                isCurved: true,
                color: Colors.green,
                barWidth: 2,
                dotData: FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildTemperatureChart(Map<String, dynamic> data) {
    final tempData = data["temperature_data"];
    if (tempData == null || tempData.isEmpty) {
      return const Center(child: Text("No temperature data"));
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < tempData.length; i++) {
      final temp = tempData[i];
      spots.add(FlSpot(i.toDouble(), temp["temperature"].toDouble()));
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOxygenChart(Map<String, dynamic> data) {
    final oxygenData = data["oxygen_levels"];
    if (oxygenData == null || oxygenData.isEmpty) {
      return const Center(child: Text("No oxygen data"));
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < oxygenData.length; i++) {
      final oxygen = oxygenData[i];
      spots.add(FlSpot(i.toDouble(), oxygen["saturation"].toDouble()));
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatisticsView(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: stats.entries.map((entry) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.analytics, color: Colors.teal),
              title: Text(
                entry.key.replaceAll("_", " ").toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                entry.value.toString(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildRiskAssessmentView(Map<String, dynamic> data) {
    final riskLevel = data["risk_level"] ?? "Unknown";
    final riskScore = data["risk_score"] ?? 0;
    
    Color riskColor = Colors.green;
    if (riskLevel.toString().toLowerCase().contains("high")) {
      riskColor = Colors.red;
    } else if (riskLevel.toString().toLowerCase().contains("medium")) {
      riskColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.security, size: 60, color: riskColor),
                  const SizedBox(height: 16),
                  Text(
                    "Risk Level: $riskLevel",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Score: $riskScore",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          if (data["factors"] != null)
            ...List.generate(data["factors"].length, (index) {
              final factor = data["factors"][index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.amber),
                  title: Text(factor.toString()),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget buildMovementChart(Map<String, dynamic> data) {
    final movementData = data["movement_data"];
    if (movementData == null || movementData.isEmpty) {
      return const Center(child: Text("No movement data"));
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < movementData.length; i++) {
      final movement = movementData[i];
      final activity = movement["activity_level"] ?? movement["steps"] ?? 0;
      spots.add(FlSpot(i.toDouble(), activity.toDouble()));
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.purple,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProteinChart(Map<String, dynamic> data) {
    final proteinData = data["protein_levels"];
    if (proteinData == null || proteinData.isEmpty) {
      return const Center(child: Text("No protein data"));
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < proteinData.length; i++) {
      final protein = proteinData[i];
      spots.add(FlSpot(i.toDouble(), protein["level"].toDouble()));
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.brown,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildGenericChart(Map<String, dynamic> data) {
    // Try to find any numeric arrays in the data
    List<FlSpot> spots = [];
    
    data.forEach((key, value) {
      if (value is List) {
        for (int i = 0; i < value.length; i++) {
          final item = value[i];
          if (item is num) {
            spots.add(FlSpot(i.toDouble(), item.toDouble()));
          } else if (item is Map && item.containsKey("value")) {
            spots.add(FlSpot(i.toDouble(), item["value"].toDouble()));
          }
        }
        return; // Use the first valid list found
      }
    });

    if (spots.isEmpty) {
      return buildKeyValueView(data);
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.teal,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildKeyValueView(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: data.entries.map((entry) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.data_usage, color: Colors.teal),
              title: Text(
                entry.key.replaceAll("_", " ").toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(entry.value.toString()),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(showRawJson ? Icons.bar_chart : Icons.code),
            onPressed: () {
              setState(() {
                showRawJson = !showRawJson;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.supportsDays)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Number of days",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: isLoading ? null : fetchChartData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Update"),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : showRawJson
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Text(
                            const JsonEncoder.withIndent("  ").convert(responseData),
                            style: const TextStyle(fontSize: 14, fontFamily: "monospace"),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: buildChart(),
                      ),
          ),
        ],
      ),
    );
  }
}