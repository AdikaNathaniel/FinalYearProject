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
  Map<String, dynamic>? vitalData;
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
    
    try {
      final response = await http.get(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/heltec-live-vitals/latest'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            vitalData = data['result'];
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

  // String _getTimeAgo(String timestamp) {
  //   try {
  //     final createdAt = DateTime.parse(timestamp);
  //     final now = DateTime.now();
  //     final difference = now.difference(createdAt);
      
  //     if (difference.inMinutes < 1) return 'Just now';
  //     if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  //     if (difference.inHours < 24) return '${difference.inHours}h ago';
  //     return '${difference.inDays}d ago';
  //   } catch (e) {
  //     return 'Unknown';
  //   }
  // }

  String _getTimeAgo(String timestamp) {
  try {
    final createdAt = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 1) return 'Just now';
    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}min ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  } catch (e) {
    return 'Unknown';
  }
}


  Color _getProteinColor(int? proteinLevel) {
    if (proteinLevel == null) return Colors.grey;
    
    final colors = [
      Color(0xFF00C2C7), 
      Color(0xFFE5B7A5), 
      Color(0xFFB794C0), 
      Color(0xFFD8D8D8), 
      Color(0xFFF0D56D), 
      Color(0xFFF5C243), 
      Color(0xFFFFA500), 
      Color(0xFFFFD700), 
      Color(0xFFD2B48C), 
      Color(0xFF8B5A2B), 
    ];
    
    return proteinLevel < colors.length ? colors[proteinLevel] : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Vitals Monitor"),
        backgroundColor: Colors.blueAccent,
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
        color: Colors.blueAccent,
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
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
                        backgroundColor: Colors.blueAccent,
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
            if (vitalData == null) {
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
                        backgroundColor: Colors.blueAccent,
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
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      MetricCard(
                        title: 'Blood Glucose',
                        value: '${vitalData?['glucose']?.toStringAsFixed(1) ?? 'N/A'} mg/dL',
                        icon: Icons.water_drop,
                        color: Colors.purple,
                        lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                      ),
                      
                      MetricCard(
                        title: 'Blood Pressure',
                        value: '${vitalData?['systolicBP']?.toStringAsFixed(0) ?? 'N/A'}/${vitalData?['diastolicBP']?.toStringAsFixed(0) ?? 'N/A'} mmHg',
                        icon: Icons.favorite,
                        color: Colors.pink,
                        lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                      ),
                      
                      MetricCard(
                        title: 'Heart Rate',
                        value: '${vitalData?['heartRate']?.toStringAsFixed(0) ?? 'N/A'} BPM',
                        icon: Icons.monitor_heart,
                        color: Colors.red,
                        lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                      ),
                      
                      MetricCard(
                        title: 'Oxygen Saturation',
                        value: '${vitalData?['spo2']?.toStringAsFixed(0) ?? 'N/A'}%',
                        icon: Icons.air,
                        color: Colors.blue,
                        lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                      ),
                      
                      MetricCard(
                        title: 'Body Temperature',
                        value: '${vitalData?['bodyTemp']?.toStringAsFixed(1) ?? 'N/A'}°C',
                        icon: Icons.thermostat,
                        color: Colors.orange,
                        lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                      ),
                      
                      AccelerometerCard(
                        x: vitalData?['accelX']?.toStringAsFixed(2) ?? 'N/A',
                        y: vitalData?['accelY']?.toStringAsFixed(2) ?? 'N/A',
                        z: vitalData?['accelZ']?.toStringAsFixed(2) ?? 'N/A',
                        lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                      ),
                      
                      GyroscopeCard(
                        x: vitalData?['gyroX']?.toStringAsFixed(2) ?? 'N/A',
                        y: vitalData?['gyroY']?.toStringAsFixed(2) ?? 'N/A',
                        z: vitalData?['gyroZ']?.toStringAsFixed(2) ?? 'N/A',
                        lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                      ),
                      
                      MetricCard(
                        title: 'Skin Temperature',
                        value: '${vitalData?['skinTemp']?.toStringAsFixed(1) ?? 'N/A'}°C',
                        icon: Icons.thermostat_outlined,
                        color: Colors.deepPurple,
                        lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                      ),
                    ],
                  ),

                  // Protein Card (if protein level exists)
                  if (vitalData?['proteinLevel'] != null) ...[
                    const SizedBox(height: 12),
                    ProteinCard( 
                      proteinLevel: vitalData?['proteinLevel'] ?? 0,
                      color: _getProteinColor(vitalData?['proteinLevel']),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String lastUpdated;

  const MetricCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.lastUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lastUpdated,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class AccelerometerCard extends StatelessWidget {
  final String x;
  final String y;
  final String z;
  final String lastUpdated;

  const AccelerometerCard({
    Key? key,
    required this.x,
    required this.y,
    required this.z,
    required this.lastUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.directions,
                color: Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accelerometer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'X',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          x,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Y',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          y,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Z',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          z,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              lastUpdated,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class GyroscopeCard extends StatelessWidget {
  final String x;
  final String y;
  final String z;
  final String lastUpdated;

  const GyroscopeCard({
    Key? key,
    required this.x,
    required this.y,
    required this.z,
    required this.lastUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.cached,
                color: Colors.teal,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gyroscope',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'X',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          x,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Y',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          y,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Z',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          z,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              lastUpdated,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class ProteinCard extends StatelessWidget {
  final int proteinLevel;
  final Color color;

  const ProteinCard({
    Key? key,
    required this.proteinLevel,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(
                Icons.science,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Protein in Urine',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level: $proteinLevel',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last updated: Just now',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}