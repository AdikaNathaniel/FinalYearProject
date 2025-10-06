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
    _cardAnimations = List.generate(4, (index) {
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
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.blue.withOpacity(0.3),
              highlightColor: Colors.blue.withOpacity(0.1),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 6,
                shadowColor: Colors.blue.withOpacity(0.3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade600,
                        Colors.blue.shade700,
                        Colors.blue.shade800,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              radius: 20,
                              child: Icon(
                                icon,
                                size: 24,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
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
      backgroundColor: Colors.white,
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
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                
                // Cards Section
                _buildCard(
                  icon: Icons.note_add,
                  title: "Create New Record",
                  animation: _cardAnimations[0],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreateRecordPage()),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildCard(
                  icon: Icons.medical_services,
                  title: "Symptom Management",
                  animation: _cardAnimations[1],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SymptomListPage()),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildCard(
                  icon: Icons.person_search,
                  title: "Find Patient Symptoms",
                  animation: _cardAnimations[2],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FindSymptomPage()),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildCard(
                  icon: Icons.local_hospital,
                  title: "Manual Predictions",
                  animation: _cardAnimations[3],
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