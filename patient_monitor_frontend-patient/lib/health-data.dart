import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pregnancy History',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HealthDataPage(),
    );
  }
}

class HealthDataPage extends StatefulWidget {
  @override
  _HealthDataPageState createState() => _HealthDataPageState();
}

class _HealthDataPageState extends State<HealthDataPage> {
  List<dynamic> healthData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHealthData();
  }

  Future<void> fetchHealthData() async {
    final response = await http.get(Uri.parse('http://localhost:3100/api/v1/health'));

    if (response.statusCode == 200) {
      setState(() {
        healthData = json.decode(response.body)['result'];
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load health data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Center(
          child: Text(
            'Pregnancy History',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.red],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: healthData.length,
                itemBuilder: (context, index) {
                  final item = healthData[index];

                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.blue),
                              SizedBox(width: 10),
                              Text(
                                'Age: ${item['age']}',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Divider(),
                          _buildInfoRow(Icons.child_care, 'Parity', item['parity']),
                          _buildInfoRow(Icons.pregnant_woman, 'Gravida', item['gravida']),
                          _buildInfoRow(Icons.date_range, 'Gestational Age', '${item['gestationalAge']} weeks'),
                          _buildBooleanRow(Icons.local_hospital, 'Diabetes', item['hasDiabetes']),
                          _buildBooleanRow(Icons.bloodtype, 'Anemia', item['hasAnemia']),
                          _buildBooleanRow(Icons.warning, 'Preeclampsia', item['hasPreeclampsia']),
                          _buildBooleanRow(Icons.medical_services, 'Gestational Diabetes', item['hasGestationalDiabetes']),
                          Divider(),
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(
                                'Created At: ${item['createdAt']}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  /// Helper method to display text information with icons
  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          SizedBox(width: 10),
          Text(
            '$label: $value',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Helper method to display boolean values as "Yes" or "No"
  Widget _buildBooleanRow(IconData icon, String label, dynamic value) {
    bool isTrue = value.toString().toLowerCase() == 'true'; // Ensure correct boolean conversion
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: isTrue ? Colors.red : Colors.green),
          SizedBox(width: 10),
          Text(
            '$label: ${isTrue ? "Yes" : "No"}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}