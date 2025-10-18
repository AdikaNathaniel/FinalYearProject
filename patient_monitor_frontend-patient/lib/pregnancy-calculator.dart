import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Ensure the intl package is installed
import 'vitals-health-data.dart'; // Import your VitalsHealthDataPage

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
        title: Text("Pregnancy Calculator"),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          kToolbarHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Content Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pregnancy Image on Top
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/pregnancy.png"),
                            fit: BoxFit.contain,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Instruction Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Select the first day of your Last Menstrual Period",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Date Picker Button
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _pickDate,
                          icon: Icon(Icons.calendar_today),
                          label: Text(
                            _selectedDate == null
                                ? "Select Date"
                                : DateFormat("MMMM dd, yyyy").format(_selectedDate!),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            textStyle: TextStyle(fontSize: 16),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Display Weeks Pregnant
                      if (_weeksPregnant != null)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Congratulations!!",
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "You Are $_weeksPregnant Weeks Pregnant",
                                style: TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Spacer to push bottom content down
                  SizedBox(height: 20),

                  // Bottom Content Section
                  Column(
                    children: [
                      // View My Vitals Text
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VitalsHealthDataPage(userEmail: widget.userEmail),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.monitor_heart, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                "Record Your Vitals Data",
                                style: TextStyle(
                                  fontSize: 18, 
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}