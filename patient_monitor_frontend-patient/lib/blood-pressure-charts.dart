import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class BloodPressurePage extends StatefulWidget {
  @override
  _BloodPressurePageState createState() => _BloodPressurePageState();
}

class _BloodPressurePageState extends State<BloodPressurePage> {
  bool isLoading = false;
  Map<String, dynamic>? chartData;
  final TextEditingController _daysController = TextEditingController(text: "7");

  @override
  void initState() {
    super.initState();
    fetchBloodPressureData();
  }

  Future<void> fetchBloodPressureData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final days = _daysController.text.isNotEmpty ? _daysController.text : "7";
      final url = "https://patient-monitor-backend-patient.fly.dev/api/v1/heltec-live-vitals/charts/blood-pressure?days=$days";
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          chartData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        chartData = {"error": e.toString()};
      });
    }
  }

  Widget buildBloodPressureChart() {
    // Fixed: Check if error value is not null, not just if key exists
    if (chartData == null || chartData!["error"] != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              chartData?["error"]?.toString() ?? "No data available",
              style: TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final result = chartData!["result"];
    if (result == null) {
      return Center(
        child: Text(
          "No chart data available",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final labels = result["labels"] as List<dynamic>?;
    final datasets = result["datasets"] as List<dynamic>?;

    if (labels == null || datasets == null || datasets.isEmpty) {
      return Center(
        child: Text(
          "No blood pressure data available",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Extract systolic and diastolic data
    Map<String, dynamic>? systolicDataset;
    Map<String, dynamic>? diastolicDataset;
    
    for (final dataset in datasets) {
      if (dataset["label"] == "Systolic BP (mmHg)") {
        systolicDataset = dataset;
      } else if (dataset["label"] == "Diastolic BP (mmHg)") {
        diastolicDataset = dataset;
      }
    }

    if (systolicDataset == null || diastolicDataset == null) {
      return Center(
        child: Text(
          "Blood pressure data incomplete",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final systolicData = systolicDataset["data"] as List<dynamic>? ?? [];
    final diastolicData = diastolicDataset["data"] as List<dynamic>? ?? [];
    
    if (systolicData.isEmpty || diastolicData.isEmpty) {
      return Center(
        child: Text(
          "No data points available",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Create spots for both systolic and diastolic
    List<FlSpot> systolicSpots = [];
    List<FlSpot> diastolicSpots = [];
    
    for (int i = 0; i < systolicData.length && i < diastolicData.length; i++) {
      final systolicValue = systolicData[i];
      final diastolicValue = diastolicData[i];
      
      if (systolicValue is num && diastolicValue is num) {
        systolicSpots.add(FlSpot(i.toDouble(), systolicValue.toDouble()));
        diastolicSpots.add(FlSpot(i.toDouble(), diastolicValue.toDouble()));
      }
    }

    if (systolicSpots.isEmpty || diastolicSpots.isEmpty) {
      return Center(
        child: Text(
          "No valid data points to display",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Calculate min and max values
    final maxSystolic = systolicData.map((e) => (e as num).toDouble()).reduce((a, b) => a > b ? a : b);
    final maxDiastolic = diastolicData.map((e) => (e as num).toDouble()).reduce((a, b) => a > b ? a : b);
    final minSystolic = systolicData.map((e) => (e as num).toDouble()).reduce((a, b) => a < b ? a : b);
    final minDiastolic = diastolicData.map((e) => (e as num).toDouble()).reduce((a, b) => a < b ? a : b);
    
    final maxValue = maxSystolic > maxDiastolic ? maxSystolic : maxDiastolic;
    final minValue = minSystolic < minDiastolic ? minSystolic : minDiastolic;

    return Column(
      children: [
        // Chart Title with unit
        Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Blood Pressure Trend (mmHg)",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Last ${_daysController.text} days • ${systolicSpots.length} readings",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Legend
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Systolic BP",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 20),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Diastolic BP",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Line Chart - Expanded to fill available space
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(minValue, maxValue),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            value.toInt().toString(), // Just show the number without unit
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          // Show only first and last labels
                          if (index == 0 || index == labels.length - 1) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                labels[index].toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            );
                          }
                        }
                        return SizedBox();
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: (systolicSpots.length - 1).toDouble(),
                minY: minValue * 0.9,
                maxY: maxValue * 1.1,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipPadding: EdgeInsets.all(12),
                    tooltipMargin: 8,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final date = index >= 0 && index < labels.length 
                            ? labels[index].toString() 
                            : 'N/A';
                        final value = spot.y.toStringAsFixed(0);
                        
                        // Determine if this is systolic or diastolic based on bar index
                        final isSystolic = touchedSpots.indexOf(spot) == 0;
                        final label = isSystolic ? 'Systolic' : 'Diastolic';
                        
                        return LineTooltipItem(
                          '$date\n$label: $value mmHg',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
                lineBarsData: [
                  // Systolic BP Line
                  LineChartBarData(
                    spots: systolicSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.withOpacity(0.2),
                          Colors.blue.withOpacity(0.05),
                        ],
                      ),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.blue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                  // Diastolic BP Line
                  LineChartBarData(
                    spots: diastolicSpots,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: false),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.orange,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateInterval(double minValue, double maxValue) {
    final range = maxValue - minValue;
    
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    if (range <= 200) return 50;
    return 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Blood Pressure",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Days Input Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Number of Days",
                      hintText: "Enter days (e.g., 7)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.calendar_today, color: Colors.blue),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : fetchBloodPressureData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Update",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Chart or Loading
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Loading Blood Pressure Data...",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  )
                : buildBloodPressureChart(),
          ),
        ],
      ),
    );
  }
}