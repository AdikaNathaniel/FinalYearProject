import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_page.dart'; // Import for logout navigation
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
    {"icon": FontAwesomeIcons.smile, "title": "Stay Happy", "description": "Your emotions affect your baby’s development."},
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

  @override
  void initState() {
    super.initState();
    _startTimer(); // Start the timer
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          startIndex = (startIndex + 4) % tips.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void _showUserInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(child: Text('Profile')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email),
                SizedBox(width: 10),
                Text(widget.userEmail),
              ],
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final response = await http.put(
                  Uri.parse('http://localhost:3100/api/v1/users/logout'),
                  headers: {'Content-Type': 'application/json'},
                );

                if (response.statusCode == 200) {
                  final responseData = json.decode(response.body);
                  if (responseData['success']) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  } else {
                    _showSnackbar(context, "Logout failed: ${responseData['message']}", Colors.red);
                  }
                } else {
                  _showSnackbar(context, "Logout failed: Server error", Colors.red);
                }
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

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
    List<Map<String, dynamic>> displayedTips = tips.sublist(startIndex, startIndex + 4);

    return Scaffold(
      appBar: AppBar(
        title: Text("Pregnancy Wellness Tips",
         style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.pinkAccent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'U',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            onPressed: () {
              _showUserInfoDialog(context); // Show user info dialog
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue,
              Colors.red,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: GridView.builder(
            itemCount: displayedTips.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              var tip = displayedTips[index];
              return AnimatedSwitcher(
                duration: Duration(milliseconds: 800),
                child: Card(
                  key: ValueKey(tip["title"]),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  color: Colors.pink[50],
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tip["icon"], size: 50, color: Colors.pinkAccent),
                        SizedBox(height: 10),
                        Text(
                          tip["title"],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          tip["description"],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
    );
  }
}


// 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

// https://www.youtube.com/redirect?event=video_description&redir_token=QUFFLUhqa0ZOUVBUM0UwSDFxZ0Q5ZzlYdnFpakM3YUlEQXxBQ3Jtc0trMnUxTS1GdkdtOXdGMFNkZkczM3JraWxRN05zU1RRbHVpQ21yWEVrYndUNnl6QjdTb3hIemd3S09Ra1E2ZnRoSXhHZXdzWXg4OWZ0YXdxeklIYWpMVFMzX2tuLXFSS1JvbnNIbDNraThtMVFmS3Ntcw&q=https%3A%2F%2Fgithub.com%2Fmarketplace%2Fmodels&v=YP8mV_2RDLc