import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PatientVitalsPage extends StatefulWidget {
  @override
  _PatientVitalsPageState createState() => _PatientVitalsPageState();
}

class _PatientVitalsPageState extends State<PatientVitalsPage> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? vitals;
  bool isLoading = false;

  Future<void> fetchVitals(String name) async {
    setState(() => isLoading = true);
    final uri = Uri.parse(
        'http://localhost:3100/api/v1/health-analytics/patient-vitals?patientName=${Uri.encodeComponent(name)}');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        vitals = data['result'];
        isLoading = false;
      });
    } else {
      setState(() {
        vitals = null;
        isLoading = false;
      });
    }
  }

  Widget buildAnimatedCard(
      String title, String value, IconData icon, int index,
      {Color? color}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, valueTween, child) {
        return Opacity(
          opacity: valueTween.clamp(0.0, 1.0), // Ensure value is within range
          child: Transform.scale(
            scale: valueTween,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color?.withOpacity(0.2) ?? Colors.blue.withOpacity(0.2),
                      ),
                      child: Icon(
                        icon,
                        color: color ?? Colors.blue,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final personal = vitals?['personal_info'] ?? {};
    final signs = vitals?['vital_signs'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text("Patient Vitals", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.red], // Gradient background
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter Patient Name',
                prefixIcon: Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onSubmitted: fetchVitals,
            ),
            const SizedBox(height: 20),

            if (isLoading) CircularProgressIndicator(),

            if (vitals != null && !isLoading)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          buildAnimatedCard("Gestational Week", 
                            personal['gestational_week'].toString(), Icons.pregnant_woman, 0, color: Colors.purple),
                          buildAnimatedCard("Height (cm)", 
                            personal['height_cm'].toString(), Icons.height, 1, color: Colors.indigo),
                          buildAnimatedCard("Weight (kg)", 
                            personal['weight_kg'].toString(), Icons.monitor_weight, 2, color: Colors.green),
                          buildAnimatedCard("BMI", 
                            personal['bmi'].toString(), Icons.fitness_center, 3, color: Colors.orange),
                          buildAnimatedCard("Body Temperature (°C)", 
                            signs['body_temperature_c'].toString(), Icons.thermostat, 4, color: Colors.red),
                          buildAnimatedCard("Systolic BP (mmHg)", 
                            signs['systolic_bp_mmHg'].toString(), Icons.favorite, 5, color: Colors.pink),
                          buildAnimatedCard("Diastolic BP (mmHg)", 
                            signs['diastolic_bp_mmHg'].toString(), Icons.favorite_outline, 6, color: Colors.pinkAccent),
                          buildAnimatedCard("Blood Glucose (mg/dL)", 
                            signs['blood_glucose_mg_dL'].toString(), Icons.bloodtype, 7, color: Colors.redAccent),
                          buildAnimatedCard("Oxygen Saturation (%)", 
                            signs['oxygen_saturation_percent'].toString(), Icons.air, 8, color: Colors.lightBlue),
                          buildAnimatedCard("Heart Rate (bpm)", 
                            signs['heart_rate_bpm'].toString(), Icons.favorite_rounded, 9, color: Colors.red),
                        ],
                      ),
                      // Protein in Urine card spanning full width
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: buildAnimatedCard("Protein in Urine", 
                          signs['protein_urine_scale'].toString(), Icons.opacity, 10, color: Colors.teal),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}