import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Metrics Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        cardTheme: CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const HealthDashboard(),
    );
  }
}

class HealthDashboard extends StatelessWidget {
  const HealthDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      title: const Text(
        'Health Metrics Dashboard',
        style: TextStyle(
          color: Colors.white, // Set the text color to white
        ),
      ),
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.blueAccent,
    ),
      body: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue,
            Colors.red,
          ],
        ),
      ),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: const [
            MetricCard(
              title: 'Body Temperature',
              value: '37.2°C',
              icon: Icons.thermostat,
              color: Colors.red,
              lastUpdated: '2 hours ago',
            ),
            MetricCard(
              title: 'Blood Pressure',
              value: '120/80 mmHg',
              icon: Icons.favorite,
              color: Colors.pink,
              lastUpdated: '3 hours ago',
            ),
            MetricCard(
              title: 'Blood Glucose',
              value: '5.4 mmol/L',
              icon: Icons.water_drop,
              color: Colors.purple,
              lastUpdated: '1 hour ago',
            ),
            MetricCard(
              title: 'Oxygen Saturation',
              value: '98%',
              icon: Icons.air,
              color: Colors.blue,
              lastUpdated: '30 minutes ago',
            ),
            MetricCard(
              title: 'Heart Rate',
              value: '72 BPM',
              icon: Icons.monitor_heart,
              color: Colors.red,
              lastUpdated: '15 minutes ago',
            ),
            MetricCard(
              title: 'Weight',
              value: '68.5 kg',
              icon: Icons.monitor_weight,
              color: Colors.green,
              lastUpdated: '1 day ago',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new measurement
        },
        child: const Icon(Icons.add),
        tooltip: 'Add new measurement',
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}

class MetricCard extends StatefulWidget {
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
  _MetricCardState createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true); // Repeat the animation to create a bounce effect.

    _bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _bounceController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bounceAnimation.value),
                  child: child,
                );
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.2),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Last updated: ${widget.lastUpdated}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
