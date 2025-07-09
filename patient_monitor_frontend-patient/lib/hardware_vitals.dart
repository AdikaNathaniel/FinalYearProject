import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HardwareVitals extends StatefulWidget {
  const HardwareVitals({Key? key}) : super(key: key);

  @override
  _HardwareVitalsState createState() => _HardwareVitalsState();
}

class _HardwareVitalsState extends State<HardwareVitals> {
  Map<String, dynamic>? vitals;
  Timer? timer;

  final String xiaoIp = 'http://192.168.43.218'; // 🔁 Replace with your actual IP
  final Duration pollingInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    fetchVitals(); // Fetch once immediately
    timer = Timer.periodic(pollingInterval, (_) => fetchVitals()); // Poll every 5s
  }

  Future<void> fetchVitals() async {
    try {
      final response = await http.get(Uri.parse('$xiaoIp/vitals'));

      if (response.statusCode == 200) {
        setState(() {
          vitals = json.decode(response.body);
        });
      } else {
        print("Failed to load vitals: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching vitals: $e");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🩺 Live Vitals Monitor"),
        backgroundColor: Colors.teal,
      ),
      body: vitals == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VitalTile(label: "💓 Heart Rate", value: "${vitals!['heartRate']} bpm"),
                  VitalTile(label: "🩸 Blood Pressure", value: "${vitals!['systolicBP']}/${vitals!['diastolicBP']} mmHg"),
                  VitalTile(label: "🌡️ Temperature", value: "${vitals!['temperature']} °C"),
                  VitalTile(label: "🍬 Blood Glucose", value: "${vitals!['bloodGlucose']} mg/dL"),
                  VitalTile(label: "💨 O₂ Saturation", value: "${vitals!['oxygenSaturation']} %"),
                ],
              ),
            ),
    );
  }
}

class VitalTile extends StatelessWidget {
  final String label;
  final String value;

  const VitalTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.monitor_heart, color: Colors.redAccent),
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
