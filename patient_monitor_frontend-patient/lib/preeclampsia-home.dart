import 'package:flutter/material.dart';
import 'create-prescription.dart';
import 'view_prescription.dart';
import 'create-prescription.dart';
import 'symptom-list.dart';
import 'symptom-by-name.dart';
import 'preeclampsia-live.dart';
import 'preeclampsia-post.dart';
import 'preeclampsia-get-all.dart';

class PreeclampsiaHomePage extends StatefulWidget {
  const PreeclampsiaHomePage({super.key});

  @override
  State<PreeclampsiaHomePage> createState() => _PreeclampsiaHomePageState();
}

class _PreeclampsiaHomePageState extends State<PreeclampsiaHomePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create staggered animations for each card
    _cardAnimations = List.generate(5, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.15,
          1.0,
          curve: Curves.easeOutBack,
        ),
      ));
    });

    // Start animations
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required Animation<double> animation,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: Opacity(
            opacity: animation.value,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(25),
              splashColor: color.withOpacity(0.3),
              highlightColor: color.withOpacity(0.1),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 8,
                shadowColor: color.withOpacity(0.4),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.85),
                        color,
                        color.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: title,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 35,
                            child: Icon(
                              icon,
                              size: 42,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Preeclampsia Manager',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF8FAFE),
              Colors.blue.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                
                // Welcome Section
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.blue.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  // child: const Row(
                  //   children: [
                  //     Icon(
                  //       Icons.health_and_safety,
                  //       size: 30,
                  //       color: Colors.blue,
                  //     ),
                  //     SizedBox(width: 15),
                  //     // Expanded(
                  //     //   child: Column(
                  //     //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     //     // children: [
                  //     //     //   // Text(
                  //     //     //   //   'Welcome to Preeclampsia Care',
                  //     //     //   //   style: TextStyle(
                  //     //     //   //     fontSize: 18,
                  //     //     //   //     fontWeight: FontWeight.bold,
                  //     //     //   //     color: Colors.blue,
                  //     //     //   //   ),
                  //     //     //   // ),
                  //     //     //   // SizedBox(height: 4),
                  //     //     //   // Text(
                  //     //     //   //   'Comprehensive maternal health monitoring',
                  //     //     //   //   style: TextStyle(
                  //     //     //   //     fontSize: 14,
                  //     //     //   //     color: Colors.grey,
                  //     //     //   //   ),
                  //     //     //   // ),
                  //     //     // ],
                  //     //   ),
                  //     // ),
                  //   ],
                  // ),
                ),

                // Cards Section
                _buildCard(
                  icon: Icons.note_add,
                  title: "Create New Record",
                  subtitle: "Add a new patient preeclampsia record",
                  color: const Color(0xFF4CAF50),
                  animation: _cardAnimations[0],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreateRecordPage()),
                    );
                  },
                ),

                const SizedBox(height: 16),

                _buildCard(
                  icon: Icons.medical_services,
                  title: "Symptom Management",
                  subtitle: "Manage and monitor preeclampsia symptoms",
                  color: const Color(0xFFFF9800),
                  animation: _cardAnimations[1],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SymptomListPage()),
                    );
                  },
                ),

                const SizedBox(height: 16),

                _buildCard(
                  icon: Icons.person_search,
                  title: "Find Patient Symptoms",
                  subtitle: "Search symptoms by patient name or ID",
                  color: const Color(0xFF9C27B0),
                  animation: _cardAnimations[2],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FindSymptomPage()),
                    );
                  },
                ),

                const SizedBox(height: 16),

                _buildCard(
                  icon: Icons.watch,
                  title: "Wearable Device Predictions",
                  subtitle: "Real-time predictions from wearable devices",
                  color: const Color(0xFF00BCD4),
                  animation: _cardAnimations[3],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PreeclampsiaVitals()),
                    );
                  },
                ),

                const SizedBox(height: 16),

                _buildCard(
                  icon: Icons.local_hospital,
                  title: "Medical Staff Predictions",
                  subtitle: "Manual predictions by healthcare professionals",
                  color: const Color(0xFFF44336),
                  animation: _cardAnimations[4],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GetAllRecordsPage()),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}