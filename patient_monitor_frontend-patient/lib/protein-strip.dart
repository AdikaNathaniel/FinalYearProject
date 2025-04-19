import 'package:flutter/material.dart';

class UrineStripColorSelector extends StatefulWidget {
  @override
  _UrineStripColorSelectorState createState() => _UrineStripColorSelectorState();
}

class _UrineStripColorSelectorState extends State<UrineStripColorSelector> {
  final List<Color> colors = [
    Color(0xFF00C2C7), // Cyan Blue
    Color(0xFFE5B7A5), // Light Pink
    Color(0xFFB794C0), // Light Purple
    Color(0xFFD8D8D8), // Light Gray
    Color(0xFFF0D56D), // Light Yellow
    Color(0xFFF5C243), // Yellow
    Color(0xFFFFA500), // Orange
    Color(0xFFFFD700), // Gold Yellow
    Color(0xFFD2B48C), // Tan
    Color(0xFF8B5A2B), // Dark Brown
  ];

  final List<int> proteinLevels = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9 // Corresponding protein levels
  ];

  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose the Color from Your Urine Strip',
        style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Tap on the color that matches your urine strip to see your protein level.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
          SizedBox(height: 20),
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: List.generate(colors.length, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(selectedIndex == index ? 6 : 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedIndex == index ? Colors.blueAccent : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: colors[index],
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 30),
          selectedIndex != null
              ? Column(
                  children: [
                    Text(
                      'Selected Color:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: colors[selectedIndex!],
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Protein Level: ${proteinLevels[selectedIndex!]}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ],
                )
              : Container(),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: UrineStripColorSelector(),
    debugShowCheckedModeBanner: false,
  ));
}
