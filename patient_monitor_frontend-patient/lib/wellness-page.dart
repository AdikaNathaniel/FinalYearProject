import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_page.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';

class WellnessTipsScreen extends StatefulWidget {
  final String userEmail;

  const WellnessTipsScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  _WellnessTipsScreenState createState() => _WellnessTipsScreenState();
}

class _WellnessTipsScreenState extends State<WellnessTipsScreen> {
  final List<Map<String, dynamic>> tips = [
    {"icon": FontAwesomeIcons.appleAlt, "title": "Eat Nutritious Meals", "description": "Ensure a balanced diet with fruits, vegetables, and proteins."},
    {"icon": FontAwesomeIcons.tint, "title": "Stay Hydrated", "description": "Drink at least 8 glasses of water daily to stay healthy."},
    {"icon": FontAwesomeIcons.walking, "title": "Gentle Exercises", "description": "Light exercises like walking help improve circulation."},
    {"icon": FontAwesomeIcons.bed, "title": "Get Enough Rest", "description": "Aim for 7-9 hours of sleep to keep your energy up."},
    {"icon": FontAwesomeIcons.seedling, "title": "Take Prenatal Vitamins", "description": "Folic acid and iron are crucial for baby's growth."},
    {"icon": FontAwesomeIcons.lungs, "title": "Practice Deep Breathing", "description": "Helps reduce stress and improve oxygen flow."},
    {"icon": FontAwesomeIcons.baby, "title": "Talk to Your Baby", "description": "Bonding starts early; talk and sing to your baby."},
    {"icon": FontAwesomeIcons.clipboardList, "title": "Attend Prenatal Checkups", "description": "Regular checkups ensure a healthy pregnancy."},
    {"icon": FontAwesomeIcons.sun, "title": "Get Enough Sunlight", "description": "Vitamin D is essential for bone health."},
    {"icon": FontAwesomeIcons.spa, "title": "Manage Stress", "description": "Meditation and yoga can help maintain a calm mind."},
    {"icon": FontAwesomeIcons.bookMedical, "title": "Educate Yourself", "description": "Read books and take pregnancy classes for knowledge."},
    {"icon": FontAwesomeIcons.soap, "title": "Maintain Hygiene", "description": "Keep clean to prevent infections and stay healthy."},
    {"icon": FontAwesomeIcons.carrot, "title": "Eat Fiber-Rich Foods", "description": "Prevents constipation and aids digestion."},
    {"icon": FontAwesomeIcons.brain, "title": "Stay Positive", "description": "A happy mind leads to a healthy pregnancy."},
    {"icon": FontAwesomeIcons.notesMedical, "title": "Monitor Baby's Movements", "description": "Keep track of fetal kicks and movement patterns."},
    {"icon": FontAwesomeIcons.pills, "title": "Avoid Harmful Substances", "description": "Avoid alcohol, smoking, and too much caffeine."},
    {"icon": FontAwesomeIcons.shoePrints, "title": "Wear Comfortable Shoes", "description": "Prevents swelling and keeps you comfortable."},
    {"icon": FontAwesomeIcons.mugHot, "title": "Drink Herbal Teas", "description": "Some teas can help reduce nausea and aid digestion."},
    {"icon": FontAwesomeIcons.bell, "title": "Listen to Soothing Music", "description": "Helps relaxation and bonding with baby."},
    {"icon": FontAwesomeIcons.userMd, "title": "Consult a Doctor", "description": "Seek medical advice for any discomforts."},
    {"icon": FontAwesomeIcons.smile, "title": "Stay Happy", "description": "Your emotions affect your baby's development."},
    {"icon": FontAwesomeIcons.dumbbell, "title": "Avoid Heavy Lifting", "description": "Strain can harm both you and your baby."},
    {"icon": FontAwesomeIcons.utensils, "title": "Eat Small Meals", "description": "Prevents nausea and maintains energy levels."},
    {"icon": FontAwesomeIcons.peace, "title": "Practice Mindfulness", "description": "Stay in the moment to reduce anxiety."},
    {"icon": FontAwesomeIcons.water, "title": "Avoid Sugary Drinks", "description": "Can lead to excessive weight gain and diabetes."},
    {"icon": FontAwesomeIcons.heart, "title": "Take Care of Your Heart", "description": "Keep cholesterol and blood pressure in check."},
    {"icon": FontAwesomeIcons.clock, "title": "Stick to a Routine", "description": "Keeps your body and baby in sync."},
    {"icon": FontAwesomeIcons.headphones, "title": "Enjoy Your Pregnancy", "description": "Celebrate the journey and make memories."},
    {"icon": FontAwesomeIcons.peopleCarry, "title": "Seek Emotional Support", "description": "Surround yourself with loved ones for support."},
    {"icon": FontAwesomeIcons.stethoscope, "title": "Be Aware of Warning Signs", "description": "Know the signs of complications and seek help."},
    {"icon": FontAwesomeIcons.glassCheers, "title": "Celebrate Milestones", "description": "Enjoy each stage of pregnancy with joy."},
    {"icon": FontAwesomeIcons.clipboardCheck, "title": "Prepare for Labor", "description": "Learn about labor and delivery beforehand."},
  ];

  int startIndex = 0;
  Timer? _timer; // Store the timer
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startTimer(); // Start the timer
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          startIndex = (startIndex + 8) % tips.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    _scrollController.dispose();
    super.dispose();
  }

  // Add missing method
  void _showEmergencyAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Emergency Alert"),
        content: Text("Emergency alert functionality would be implemented here."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  // void _showUserInfoDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => Dialog(
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(16),
  //       ),
  //       insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
  //       child: Container(
  //         width: MediaQuery.of(context).size.width * 0.9,
  //         padding: const EdgeInsets.all(20),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: [
  //             const Text(
  //               'Profile',
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const SizedBox(height: 20),
              
  //             Padding(
  //               padding: const EdgeInsets.symmetric(vertical: 8),
  //               child: Row(
  //                 children: [
  //                   const Icon(Icons.email_outlined, size: 20, color: Colors.blue),
  //                   const SizedBox(width: 12),
  //                   Flexible(
  //                     child: Text(
  //                       widget.userEmail,
  //                       style: const TextStyle(
  //                         color: Colors.black,
  //                         fontSize: 12,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 12),
              
  //             Padding(
  //               padding: const EdgeInsets.symmetric(vertical: 8),
  //               child: GestureDetector(
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   _showEmergencyAlertDialog(context);
  //                 },
  //                 child: Row(
  //                   children: [
  //                     const Icon(Icons.emergency, size: 20, color: Colors.red),
  //                     const SizedBox(width: 12),
  //                     const Flexible(
  //                       child: Text(
  //                         'Send An Emergency Alert',
  //                         style: TextStyle(
  //                           color: Colors.black,
  //                           fontSize: 12,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(width: 8),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 12),
              
  //             Padding(
  //               padding: const EdgeInsets.symmetric(vertical: 8),
  //               child: GestureDetector(
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   // This will use the SetProfilePage from set_profile.dart
  //                 },
  //                 child: Row(
  //                   children: [
  //                     const Icon(Icons.settings_outlined, size: 20, color: Colors.blueGrey),
  //                     const SizedBox(width: 12),
  //                     const Text(
  //                       'Settings',
  //                       style: TextStyle(
  //                         color: Colors.black,
  //                         fontSize: 12,
  //                       ),
  //                     ),
  //                     const Spacer(),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 12),

            
  //             Padding(
  //               padding: const EdgeInsets.symmetric(vertical: 8),
  //               child: GestureDetector(
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   // This will use the WearableDevicePairingPage from bluetooth-wearable.dart
  //                 },
  //                 child: Row(
  //                   children: [
  //                     const Icon(Icons.bluetooth, size: 20, color: Colors.blue),
  //                     const SizedBox(width: 12),
  //                     const Flexible(
  //                       child: Text(
  //                         'Pair With Bluetooth Device',
  //                         style: TextStyle(
  //                           color: Colors.black,
  //                           fontSize: 12,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(width: 8),
  //                   ],
  //                 ),
  //               ),
  //             ),

  //             const SizedBox(height: 12),
              
  //             Padding(
  //               padding: const EdgeInsets.symmetric(vertical: 8),
  //               child: GestureDetector(
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   // This will use the NotificationListPage from notification-list.dart
  //                 },
  //                 child: Row(
  //                   children: [
  //                     const Icon(Icons.notifications_active_outlined, size: 20, color: Colors.orange),
  //                     const SizedBox(width: 12),
  //                     const Text(
  //                       'Notifications',
  //                       style: TextStyle(
  //                         color: Colors.black,
  //                         fontSize: 12,
  //                       ),
  //                     ),
  //                     const Spacer(),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 12),
              
  //             Padding(
  //               padding: const EdgeInsets.symmetric(vertical: 8),
  //               child: GestureDetector(
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   // This will use the SupportFormPage from support-create.dart
  //                 },
  //                 child: Row(
  //                   children: [
  //                     const Icon(Icons.help_outline, size: 20, color: Colors.purple),
  //                     const SizedBox(width: 12),
  //                     const Text(
  //                       'Need Help?',
  //                       style: TextStyle(
  //                         color: Colors.black,
  //                         fontSize: 12,
  //                       ),
  //                     ),
  //                     const Spacer(),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 12),
              
  //             Padding(
  //               padding: const EdgeInsets.symmetric(vertical: 8),
  //               child: GestureDetector(
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   // This will use the MapPage from map.dart
  //                 },
  //                 child: Row(
  //                   children: [
  //                     const Icon(Icons.location_on, size: 20, color: Colors.green),
  //                     const SizedBox(width: 12),
  //                     const Flexible(
  //                       child: Text(
  //                         'View Location Of PregMama',
  //                         style: TextStyle(
  //                           color: Colors.black,
  //                           fontSize: 12,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(width: 8),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 20),
              
  //             TextButton(
  //               onPressed: () async {
  //                 final response = await http.put(
  //                   Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/users/logout'),
  //                   headers: {'Content-Type': 'application/json'},
  //                 );

  //                 if (response.statusCode == 200) {
  //                   final responseData = json.decode(response.body);
  //                   if (responseData['success']) {
  //                     Navigator.pushReplacement(
  //                       context,
  //                       MaterialPageRoute(builder: (context) => LoginPage()),
  //                     );
  //                   } else {
  //                     _showSnackbar(
  //                         context,
  //                         "Logout failed: ${responseData['message']}",
  //                         Colors.red);
  //                   }
  //                 } else {
  //                     _showSnackbar(
  //                         context,
  //                         "Logout failed: Server error",
  //                         Colors.red);
  //                 }
  //               },
  //               style: TextButton.styleFrom(
  //                 foregroundColor: Colors.red,
  //                 padding: const EdgeInsets.symmetric(vertical: 12),
  //               ),
  //               child: const Text(
  //                 'Logout',
  //                 style: TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.w500,
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 4),
              
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('Close'),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void _showSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    // Get 8 tips starting from startIndex
    List<Map<String, dynamic>> displayedTips = [];
    for (int i = 0; i < 8; i++) {
      int tipIndex = (startIndex + i) % tips.length;
      displayedTips.add(tips[tipIndex]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Pregnancy Tips",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     icon: CircleAvatar(
        //       backgroundColor: Colors.white,
        //       child: Text(
        //         widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'U',
        //         style: TextStyle(color: Colors.blue),
        //       ),
        //     ),
        //     onPressed: () {
        //       _showUserInfoDialog(context); // Show user info dialog
        //     },
        //   ),
        // ],
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Scrollbar(
            controller: _scrollController,
            child: GridView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: false,
              itemCount: displayedTips.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                var tip = displayedTips[index];
                return AnimatedSwitcher(
                  duration: Duration(milliseconds: 800),
                  child: Card(
                    key: ValueKey(tip["title"]),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    elevation: 5,
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(tip["icon"], size: 40, color: Colors.blue),
                          SizedBox(height: 8),
                          Text(
                            tip["title"],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              tip["description"],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}