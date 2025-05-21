
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// // Import your pages
// import 'login_appwrite.dart';
// import 'call_home_page.dart'; // Make sure this exists or create it
// import 'appwrite_service.dart'; // Adjust path if needed
// import 'agora.dart'; // Adjust path if needed

// void main() {
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AppwriteService()),
//         ChangeNotifierProvider(create: (_) => AgoraService()),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
  
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Video Call App',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: FutureBuilder(
//         // Check if user is already logged in
//         future: Provider.of<AppwriteService>(context, listen: false).getCurrentUser(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Scaffold(body: Center(child: CircularProgressIndicator()));
//           } else {
//             // If user is logged in, go to Call Home, else show Login
//             return snapshot.hasData ? const CallHomePage() : const LoginPage();
//           }
//         },
//       ),
//       routes: {
//         '/login': (context) => const LoginPage(),
//         '/call': (context) => const CallHomePage(),
//       },
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures framework is ready

  // Setup error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log('Flutter error: ${details.exception}', error: details.exception, stackTrace: details.stack);
  };

  runApp(const VideoCallApp());
}


class VideoCallApp extends StatelessWidget {
  const VideoCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('Building main app');
    return MaterialApp(
      title: 'Video Call',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const VideoCallPage(),
    );
  }
}

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final String backendUrl = 'http://localhost:3100';
  final TextEditingController _channelController = TextEditingController();
  final TextEditingController _uidController = TextEditingController();
  bool _isJoined = false;
  late RtcEngine _agoraEngine;
  List<int> remoteUids = [];
  int? localUid;
  String _log = 'Initializing...\n'; // For storing logs

  void _addLog(String message) {
    setState(() {
      _log = '${DateTime.now()}: $message\n$_log';
    });
    // Use the developer.log for better terminal output
    developer.log(message, name: 'VideoCallApp');
  }

  @override
  void initState() {
    developer.log('VideoCallPage initState called', name: 'VideoCallApp');
    super.initState();
    _uidController.text = '0'; // Default UID
    _addLog('initState called');
    setupVideoSDKEngine();
  }

  Future<void> setupVideoSDKEngine() async {
    _addLog('Starting SDK setup...');
    try {
      // Request camera and microphone permissions
      _addLog('Requesting permissions...');
      final status = await [Permission.microphone, Permission.camera].request();
      _addLog('Permission status - Microphone: ${status[Permission.microphone]}, Camera: ${status[Permission.camera]}');

      // Create an instance of the Agora engine
      _addLog('Creating Agora engine instance...');
      _agoraEngine = createAgoraRtcEngine();
      
      _addLog('Initializing Agora engine...');
      await _agoraEngine.initialize(const RtcEngineContext(
        appId: '1e83d054ca2a43dda969689a961ed0a8',
      ));

      // Register the event handler - Removed onWarning parameter that was causing issues
      _addLog('Registering event handlers...');
      _agoraEngine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            _addLog('Join channel success - channel: ${connection.channelId}, elapsed: $elapsed ms');
            setState(() {
              _isJoined = true;
            });
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            _addLog('Remote user joined - uid: $remoteUid');
            setState(() {
              remoteUids.add(remoteUid);
            });
          },
          onUserOffline: (connection, remoteUid, reason) {
            _addLog('Remote user offline - uid: $remoteUid, reason: $reason');
            setState(() {
              remoteUids.removeWhere((id) => id == remoteUid);
            });
          },
          onError: (err, msg) {
            _addLog('Agora error - code: $err, message: $msg');
          },
          // onWarning was removed as it's not available in your version of agora_rtc_engine
        ),
      );

      _addLog('Enabling video...');
      await _agoraEngine.enableVideo();
      _addLog('Video enabled successfully');
    } catch (e, stackTrace) {
      _addLog('Error in setupVideoSDKEngine: $e');
      developer.log('SDK setup error', error: e, stackTrace: stackTrace, name: 'VideoCallApp');
    }
  }

  Future<void> joinChannel() async {
    if (_channelController.text.isEmpty) {
      _addLog('Join channel attempted with empty channel name');
      return;
    }

    _addLog('Attempting to join channel ${_channelController.text} with UID ${_uidController.text}');
    
    try {
      // Get token from backend
  
      final tokenUrl = '$backendUrl/api/v1/videcall/token/${_channelController.text}/${_uidController.text}';
      _addLog('Requesting token from: $tokenUrl');
      
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse(tokenUrl));
      _addLog('Token API response time: ${stopwatch.elapsedMilliseconds}ms, status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final token = json.decode(response.body)['token'];
        _addLog('Token received successfully');
        
        _addLog('Joining Agora channel...');
        stopwatch.reset();
        stopwatch.start();
        await _agoraEngine.joinChannel(
          token: token,
          channelId: _channelController.text,
          uid: int.parse(_uidController.text),
          options: const ChannelMediaOptions(
            channelProfile: ChannelProfileType.channelProfileCommunication,
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
          ),
        );
        _addLog('Join channel completed in ${stopwatch.elapsedMilliseconds}ms');

        setState(() {
          localUid = int.parse(_uidController.text);
        });
      } else {
        _addLog('Failed to get token: ${response.body}');
      }
    } catch (e, stackTrace) {
      _addLog('Error joining channel: $e');
      developer.log('Join channel error', error: e, stackTrace: stackTrace, name: 'VideoCallApp');
    }
  }

  Future<void> leaveChannel() async {
    _addLog('Leaving channel...');
    try {
      final stopwatch = Stopwatch()..start();
      await _agoraEngine.leaveChannel();
      _addLog('Left channel in ${stopwatch.elapsedMilliseconds}ms');
      
      setState(() {
        _isJoined = false;
        remoteUids.clear();
      });
    } catch (e, stackTrace) {
      _addLog('Error leaving channel: $e');
      developer.log('Leave channel error', error: e, stackTrace: stackTrace, name: 'VideoCallApp');
    }
  }

  @override
  void dispose() {
    _addLog('Disposing resources...');
    try {
      _agoraEngine.leaveChannel();
      _agoraEngine.release();
    } catch (e, stackTrace) {
      developer.log('Error during dispose', error: e, stackTrace: stackTrace, name: 'VideoCallApp');
    }
    _channelController.dispose();
    _uidController.dispose();
    super.dispose();
    _addLog('Resources disposed');
  }

  Widget _renderLocalPreview() {
    developer.log('Rendering local preview, isJoined: $_isJoined, localUid: $localUid', name: 'VideoCallApp');
    if (_isJoined && localUid != null) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _agoraEngine,
          canvas: VideoCanvas(uid: localUid),
        ),
      );
    } else {
      return const Text(
        'Join a channel',
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _renderRemoteVideo() {
    developer.log('Rendering remote video, remoteUids: $remoteUids', name: 'VideoCallApp');
    if (remoteUids.isNotEmpty) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _agoraEngine,
          canvas: VideoCanvas(uid: remoteUids[0]),
          connection: RtcConnection(channelId: _channelController.text),
        ),
      );
    } else {
      return const Text(
        'Waiting for a remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stopwatch = Stopwatch()..start();
    developer.log('Building VideoCallPage widget', name: 'VideoCallApp');
    
    final widget = Scaffold(
      appBar: AppBar(
        title: const Text('Video Call'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isJoined) ...[
              TextField(
                controller: _channelController,
                decoration: const InputDecoration(
                  labelText: 'Channel Name',
                ),
              ),
              TextField(
                controller: _uidController,
                decoration: const InputDecoration(
                  labelText: 'User ID (number)',
                ),
                keyboardType: TextInputType.number,
              ),
              ElevatedButton(
                onPressed: joinChannel,
                child: const Text('Join Channel'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: leaveChannel,
                child: const Text('Leave Channel'),
              ),
            ],
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Center(child: _renderLocalPreview()),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(child: _renderRemoteVideo()),
                  ),
                  // Log display
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: SingleChildScrollView(
                        reverse: true,
                        child: Text(_log, style: const TextStyle(fontFamily: 'monospace')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    
    developer.log('Build completed in ${stopwatch.elapsedMilliseconds}ms', name: 'VideoCallApp');
    return widget;
  }
}