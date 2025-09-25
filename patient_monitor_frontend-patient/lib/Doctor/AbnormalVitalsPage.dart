import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(AbnormalVitalsApp());
}

class AbnormalVitalsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abnormal Vitals Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: AbnormalVitalsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AbnormalVitalsScreen extends StatefulWidget {
  @override
  _AbnormalVitalsScreenState createState() => _AbnormalVitalsScreenState();
}

class _AbnormalVitalsScreenState extends State<AbnormalVitalsScreen> {
  List<dynamic> patients = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchAbnormalVitals();
  }

  Future<void> fetchAbnormalVitals() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/health-analytics/patients-with-abnormal-vitals'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          patients = data['result'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching data: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Abnormal Vitals Dashboard',
          style: TextStyle(color: Colors.blue),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchAbnormalVitals,
          ),
        ],
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
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Patient Name')),
                          DataColumn(label: Text('Gestational Week')),
                          DataColumn(label: Text('Vital')),
                          DataColumn(label: Text('Value')),
                          DataColumn(label: Text('Normal Range')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: patients.map<DataRow>((patient) {
                          final vitals = patient['abnormal_vitals'];
                          final vitalName = vitals.keys.first;
                          final vitalData = vitals[vitalName];

                          return DataRow(
                            cells: [
                              DataCell(Text(patient['patient_name'])),
                              DataCell(Text(patient['gestational_week'].toString())),
                              DataCell(Text(vitalName.toUpperCase())),
                              DataCell(Text(vitalData['value'].toString())),
                              DataCell(Text(
                                  '${vitalData['normal_range']['min']} - ${vitalData['normal_range']['max']}')),
                              DataCell(
                                Chip(
                                  label: Text(
                                    vitalData['status'],
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: vitalData['status'] == 'above normal'
                                      ? Colors.orange[800]
                                      : Colors.blue[800],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
      ),
    );
  }
}