import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'video_chat_screen.dart';
import 'video_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _roomController = TextEditingController();
  final String _defaultRoomName = 'default-room';

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Chat')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room Name',
                  hintText: 'Enter room name',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final roomName = _roomController.text.isEmpty
                      ? _defaultRoomName
                      : _roomController.text;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Provider(
                        create: (_) => VideoService(serverUrl: 'http://localhost:3100'),
                        child: VideoChatScreen(roomName: roomName),
                      ),
                    ),
                  );
                },
                child: const Text('Join Room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}