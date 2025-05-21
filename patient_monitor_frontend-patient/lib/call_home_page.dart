import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'call_page.dart';
import 'appwrite_service.dart';

class CallHomePage extends StatelessWidget {
  const CallHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController channelController = TextEditingController();
    final appwriteService = Provider.of<AppwriteService>(context);
    
    // Check if user data is available
    final String? userName = appwriteService.currentUser?['name'] as String? ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await appwriteService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, $userName!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: channelController,
              decoration: const InputDecoration(
                labelText: 'Channel Name',
                hintText: 'Enter a channel name to join or create',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final channelName = channelController.text.trim();
                if (channelName.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CallPage(channelName: channelName),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a channel name')),
                  );
                }
              },
              child: const Text('Join Call'),
            ),
          ],
        ),
      ),
    );
  }
}