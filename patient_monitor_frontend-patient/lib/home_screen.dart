import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        print('Message received: ${message.notification?.title}');

        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message.notification?.title ?? 'No Title',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Text(message.notification?.body ?? 'No Body'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog first
                    Future.delayed(Duration(milliseconds: 100), () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop(); // Go back immediately
                      }
                    });
                  },
                  child: Text('OK', style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("No new notifications.")),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 100, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
