import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Ensure the intl package is installed
import 'health_metrics.dart'; // Import your HealthDashboard screen

class PregnancyCalculatorScreen extends StatefulWidget {
  final String userEmail; // Accept user email as a parameter

  PregnancyCalculatorScreen({required this.userEmail}); // Constructor to accept userEmail

  @override
  _PregnancyCalculatorScreenState createState() => _PregnancyCalculatorScreenState();
}

class _PregnancyCalculatorScreenState extends State<PregnancyCalculatorScreen> {
  DateTime? _selectedDate;
  int? _weeksPregnant;

  // Function to calculate pregnancy weeks
  void _calculatePregnancyWeeks() {
    if (_selectedDate == null) return;

    DateTime today = DateTime.now();
    Duration difference = today.difference(_selectedDate!);
    int weeks = (difference.inDays ~/ 7); // Integer division to get full weeks

    setState(() {
      _weeksPregnant = weeks;
    });

    // Show dialog after calculating weeks
    _showAntenatalVisitDialog(weeks);
  }

  // Function to show dialog with antenatal visit information
  void _showAntenatalVisitDialog(int weeks) {
    String message;
    if (weeks < 28) {
      message = "You need 1 antenatal visit per month.";
    } else if (weeks < 36) {
      message = "You need 2 antenatal visits per month.";
    } else {
      message = "You need 1 antenatal visit per week.";
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Antenatal Visit Notification"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Function to pick a date
  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 280)), // Approx 40 weeks ago
      firstDate: DateTime.now().subtract(Duration(days: 365 * 2)), // Limit to last 2 years
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _calculatePregnancyWeeks();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        centerTitle: true,
        backgroundColor: Colors.pink[200], // Light pink color
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue,
              Colors.red,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pregnancy Image on Top
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/pregnancy.png"),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              SizedBox(height: 20),

              // Instruction Text
              Text(
                "Select the first day of your last menstrual period (LMP)",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 15),

              // Date Picker Button
              ElevatedButton.icon(
                onPressed: _pickDate,
                icon: Icon(Icons.calendar_today),
                label: Text(
                  _selectedDate == null
                      ? "Select Date"
                      : DateFormat("MMMM dd, yyyy").format(_selectedDate!), // Fixed intl issue
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 20),

              // Display Weeks Pregnant
              if (_weeksPregnant != null)
                Column(
                  children: [
                    Text(
                      "Congratulations!!",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "You Are $_weeksPregnant Weeks Pregnant",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),

              // View My Vitals Text
              Spacer(), // Pushes the Vitals text to the bottom
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HealthDashboard(userEmail: widget.userEmail), // Navigate with userEmail
                    ),
                  );
                },
                child: Text(
                  "View My Vitals",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}