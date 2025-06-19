import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'signaling_service.dart';
import 'video_call_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _roomNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<SignalingService>(context, listen: false).connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final signalingService = Provider.of<SignalingService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Video Call App'),
      ),
      body: Center(
        child: signalingService.inCall
            ? VideoCallScreen()
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Join a Video Call',
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    SizedBox(height: 30),
                    TextField(
                      controller: _roomNameController,
                      decoration: InputDecoration(
                        labelText: 'Enter Room Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.meeting_room),
                      ),
                    ),
                    SizedBox(height: 20),
                    if (signalingService.errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          signalingService.errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: signalingService.isJoining
                          ? null
                          : () {
                              if (_roomNameController.text.trim().isNotEmpty) {
                                signalingService.joinRoom(_roomNameController.text.trim());
                              }
                            },
                      child: signalingService.isJoining
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Join Room'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }
}