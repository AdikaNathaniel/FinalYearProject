import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PrescriptionPage extends StatefulWidget {
  @override
  _PrescriptionPageState createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  List<dynamic> prescriptions = [];

  @override
  void initState() {
    super.initState();
    fetchPrescriptions();
  }

  Future<void> fetchPrescriptions() async {
    final response = await http.get(Uri.parse('http://localhost:3100/api/v1/prescriptions'));

    if (response.statusCode == 200) {
      setState(() {
        prescriptions = json.decode(response.body)['result'];
      });
    } else {
      throw Exception('Failed to load prescriptions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text(
            'Prescriptions',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.red], // Gradient background
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: prescriptions.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.separated(
                itemCount: prescriptions.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.white.withOpacity(0.5), // Divider color
                  thickness: 1, // Thickness of the divider
                  height: 20, // Space above and below the divider
                ),
                itemBuilder: (context, index) {
                  final prescription = prescriptions[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildInfoRow(Icons.person, 'Patient: ${prescription['patient_name']}'),
                          buildInfoRow(Icons.medication, 'Drug: ${prescription['drug_name']}'),
                          buildInfoRow(Icons.local_pharmacy, 'Dosage: ${prescription['dosage']}'),
                          buildInfoRow(Icons.access_time, 'Frequency: ${prescription['frequency']}'),
                          buildInfoRow(Icons.calendar_today, 'Duration: ${prescription['duration']}'),
                          buildInfoRow(Icons.date_range, 'Start Date: ${formatDate(prescription['start_date'])}'),
                          buildInfoRow(Icons.date_range, 'End Date: ${formatDate(prescription['end_date'])}'),
                          buildInfoRow(Icons.confirmation_number, 'Quantity: ${prescription['quantity']}'),
                          buildInfoRow(Icons.info_outline, 'Reason: ${prescription['reason'] ?? 'N/A'}'),
                          buildInfoRow(Icons.info_outline, 'Notes: ${prescription['notes'] ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(String dateString) {
    try {
      List<String> parts = dateString.split(' ');
      String year = parts[3];
      String month = monthStringToNumber(parts[1]).toString().padLeft(2, '0');
      String day = parts[2].padLeft(2, '0');
      return '$year-$month-$day';
    } catch (e) {
      print('Error parsing date: $dateString');
      return 'Invalid date';
    }
  }

  int monthStringToNumber(String month) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    return months[month] ?? 0;
  }
}