import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class LiveVitalsHardwareDataPage extends StatefulWidget {
  const LiveVitalsHardwareDataPage({Key? key}) : super(key: key);

  @override
  State<LiveVitalsHardwareDataPage> createState() => _LiveVitalsHardwareDataPageState();
}

class _LiveVitalsHardwareDataPageState extends State<LiveVitalsHardwareDataPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> vitals = [];
  bool isLoading = true;
  String errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    fetchVitals();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchVitals() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    final url = Uri.parse('http://192.168.43.64:3100/api/v1/vitals');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            vitals = List<Map<String, dynamic>>.from(data['result']);
            isLoading = false;
          });
          _animationController.reset();
          _animationController.forward();
        } else {
          throw Exception(data['message'] ?? 'Failed to load vitals');
        }
      } else {
        throw Exception('Failed to load vitals: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
      print('Error fetching vitals: $e');
    }
  }

  String formatDateTime(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate).toLocal();
      return DateFormat("d'th' MMMM, yyyy 'at' h:mm a").format(dateTime);
    } catch (e) {
      return 'Date not available';
    }
  }

  String formatMapValue(dynamic mapValue) {
    if (mapValue == null) return 'N/A';
    if (mapValue is double) {
      return mapValue.toStringAsFixed(2);
    }
    if (mapValue is int) {
      return mapValue.toString();
    }
    return mapValue.toString();
  }

  Widget buildVitalCard(Map<String, dynamic> vital) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
  '${vital["patientId"] ?? "N/A"}',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Colors.blueGrey,
  ),
  textAlign: TextAlign.center,
),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 0.9,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _vitalIconTile(Icons.favorite, 'HR', '${vital['heartRate']?.toString() ?? 'N/A'}', Colors.red),
                  _vitalIconTile(Icons.local_hospital, 'BP', 
                    '${vital['systolic']?.toString() ?? 'N/A'}/${vital['diastolic']?.toString() ?? 'N/A'}', Colors.blue),
                  _vitalIconTile(Icons.device_thermostat, 'Temp', 
                    '${vital['temperature']?.toString() ?? 'N/A'}°C', Colors.orange),
                  _vitalIconTile(Icons.water_drop, 'SpO₂', 
                    '${vital['spo2']?.toString() ?? 'N/A'}%', Colors.green),
                  _vitalIconTile(Icons.bloodtype, 'Glucose', 
                    '${vital['glucose']?.toString() ?? 'N/A'} mg/dL', Colors.purple),
                  _vitalIconTile(Icons.speed, 'MAP', 
                    formatMapValue(vital['map']), Colors.teal),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                formatDateTime(vital['createdAt']?.toString() ?? ''),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vitalIconTile(IconData icon, String label, String value, Color color) {
    return ScaleTransition(
      scale: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Vitals Monitor"),
        backgroundColor: Colors.cyan[600],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchVitals,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchVitals,
        color: Colors.cyan[600],
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                ),
              );
            }
            if (errorMessage.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: fetchVitals,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (vitals.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No vitals data available',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: fetchVitals,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: vitals.length,
              itemBuilder: (context, index) => buildVitalCard(vitals[index]),
            );
          },
        ),
      ),
    );
  }
}