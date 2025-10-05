import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

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
  final String videoId = 'jfrqdZKpZEE';

  @override
  void initState() {
    super.initState();
  }

  void _showVideoModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Video Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'How to Use A Protein Strip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Video Player
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildVideoPlayer(),
                    ),
                  ),
                ),
                // Bottom padding
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    // Use a simplified approach that works on all platforms
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_filled,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Video Tutorial: How to Use Protein Strip',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15),
            Text(
              'Learn the proper way to use urine protein test strips',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _openYouTubeVideo,
              icon: Icon(Icons.play_arrow),
              label: Text('Watch on YouTube'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Alternative method using url_launcher (simpler approach)
  Future<void> _openYouTubeVideo() async {
    final String youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';
    final Uri url = Uri.parse(youtubeUrl);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open YouTube'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose the Color from Your Urine Strip',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              'Tap on the color that matches your urine strip to see your protein level.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
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
            if (selectedIndex != null) ...[
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
              SizedBox(height: 30),
            ],
            Spacer(),
            // Option 1: Use simplified modal
            ElevatedButton(
              onPressed: _showVideoModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Click Me to Learn How to Use A Protein Strip',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            SizedBox(height: 10),
            // Option 2: Direct YouTube link (alternative)
            OutlinedButton(
              onPressed: _openYouTubeVideo,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.pinkAccent,
                side: BorderSide(color: Colors.pinkAccent),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Open YouTube Directly',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(height: 25),
          ],
        ),
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