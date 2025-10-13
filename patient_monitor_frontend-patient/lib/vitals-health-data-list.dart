import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VitalsHealthDataListPage extends StatefulWidget {
  const VitalsHealthDataListPage({super.key});

  @override
  State<VitalsHealthDataListPage> createState() => _VitalsHealthDataListPageState();
}

class _VitalsHealthDataListPageState extends State<VitalsHealthDataListPage> {
  DateTime? startDate;
  DateTime? endDate;
  int currentPage = 1;
  final int limit = 10;
  bool isLoading = false;
  List<dynamic> vitalsData = [];
  int totalPages = 1;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Pick date and time together
  Future<DateTime?> pickDateTime(BuildContext context, {DateTime? initial}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );

    if (time == null) return date;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> fetchVitals() async {
    if (startDate == null || endDate == null) {
      _showErrorDialog('Please select both start and end dates');
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse(
        "https://patient-monitor-backend-patient.fly.dev/api/v1/vitals-health-data"
        "?page=$currentPage&limit=$limit"
        "&startDate=${startDate!.toIso8601String()}"
        "&endDate=${endDate!.toIso8601String()}"
      );

      final response = await http.get(url, headers: {"Content-Type": "application/json"});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          vitalsData = data["result"]["data"] ?? [];
          totalPages = data["result"]["pages"] ?? 1;
        });
        
        if (vitalsData.isEmpty) {
          _showErrorDialog('No vitals data found for the selected period');
        }
      } else {
        _showErrorDialog('Error fetching vitals: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error fetching vitals: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildVitalsCard(dynamic item) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            // Date and time in top right corner
            Positioned(
              top: 0,
              right: 0,
              child: Text(
                _formatDateTime(item["timestamp"]?.toString() ?? ''),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User ID at the top center
                Text(
                  'User: ${item['userId']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20), // Extra space for the timestamp
                
                // Vitals data in rows
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallVitalCard(
                        'Blood Pressure',
                        item["bloodPressure"] != null 
                            ? '${item["bloodPressure"]["systolic"]}/${item["bloodPressure"]["diastolic"]}'
                            : 'N/A',
                        Icons.favorite,
                        Colors.pink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildSmallVitalCard(
                        'Heart Rate',
                        item["heartRate"] != null ? '${item["heartRate"]}' : 'N/A',
                        Icons.monitor_heart,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallVitalCard(
                        'SpO₂',
                        item["spO2"] != null ? '${item["spO2"]}%' : 'N/A',
                        Icons.air,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildSmallVitalCard(
                        'Glucose',
                        item["bloodGlucose"] != null ? '${item["bloodGlucose"]}' : 'N/A',
                        Icons.water_drop,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (item["bodyTemperature"] != null)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSmallVitalCard(
                          'Temperature',
                          '${item["bodyTemperature"]}°C',
                          Icons.thermostat,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                
                // Method at the bottom center
                Text(
                  'Method: ${item["inputMethod"]}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallVitalCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: color,
              size: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      
      // Convert to 12-hour format
      int hour = date.hour;
      String period = 'AM';
      
      if (hour >= 12) {
        period = 'PM';
        if (hour > 12) hour -= 12;
      }
      if (hour == 0) hour = 12;
      
      return '${date.day}/${date.month}/${date.year}\n${hour}:${date.minute.toString().padLeft(2, '0')} $period';
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
        title: const Text('Vitals Data List'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
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
                        Icons.analytics,
                        size: 48,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'View Vitals Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                startDate == null
                                    ? "Pick Start Date & Time"
                                    : "Start: ${_formatDateTime(startDate.toString())}",
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                final picked = await pickDateTime(context, initial: startDate);
                                if (picked != null) setState(() => startDate = picked);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                endDate == null
                                    ? "Pick End Date & Time"
                                    : "End: ${_formatDateTime(endDate.toString())}",
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                final picked = await pickDateTime(context, initial: endDate);
                                if (picked != null) setState(() => endDate = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : fetchVitals,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Fetch Vitals Data',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vitalsData.isEmpty
                        ? const Center(
                            child: Text(
                              'No data found',
                              style: TextStyle(
                                fontSize: 16, 
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: vitalsData.length,
                            itemBuilder: (context, index) => buildVitalsCard(vitalsData[index]),
                          ),
              ),
              if (vitalsData.isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: currentPage > 1
                                  ? () {
                                      setState(() => currentPage--);
                                      fetchVitals();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                "Previous",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              "Page $currentPage of $totalPages",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: currentPage < totalPages
                                  ? () {
                                      setState(() => currentPage++);
                                      fetchVitals();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                "Next",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}